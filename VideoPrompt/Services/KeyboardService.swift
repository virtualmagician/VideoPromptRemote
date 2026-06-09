//
//  KeyboardService.swift
//  VideoPromptOSC
//
//  Created for VideoPromptOSC App
//

import Foundation
import SwiftUI
import Combine

/// Protocol for handling keyboard commands
@MainActor
protocol KeyboardCommandHandler: AnyObject {
    func handleKeyboardTogglePlay()
    func handleKeyboardPlay()
    func handleKeyboardPause()
    func handleKeyboardNext()
    func handleKeyboardPrevious()
    func handleKeyboardReset()
}

/// Service for managing keyboard shortcuts and bindings
@MainActor
class KeyboardService: ObservableObject {
    
    // MARK: - Published Properties
    @Published private(set) var bindings: [KeyboardAction: KeyBinding] = [:]
    @Published var isCapturing: Bool = false
    @Published var capturingAction: KeyboardAction?
    
    // MARK: - Private Properties
    private let bindingsKey = "keyboardBindings"
    private weak var commandHandler: KeyboardCommandHandler?
    
    // MARK: - Initialization
    init() {
        loadBindings()
        setupDefaultBindingsIfNeeded()
    }
    
    // MARK: - Public Methods
    
    /// Set the command handler
    func setCommandHandler(_ handler: KeyboardCommandHandler) {
        self.commandHandler = handler
    }
    
    /// Get binding for a specific action
    func binding(for action: KeyboardAction) -> KeyBinding? {
        return bindings[action]
    }
    
    /// Set a key binding for an action
    func setBinding(keyPress: KeyPress, for action: KeyboardAction) {
        let keyEquivalent = keyPress.key
        let displayName = KeyDisplayHelper.displayName(for: keyPress)
        
        // Remove this key from any other action that might have it
        for (existingAction, existingBinding) in bindings {
            if existingAction != action,
               let existingKey = existingBinding.key,
               existingKey == keyEquivalent {
                bindings[existingAction] = KeyBinding(
                    id: existingBinding.id,
                    action: existingAction,
                    key: nil,
                    characterLabel: nil
                )
            }
        }
        
        // Set the new binding
        let binding = KeyBinding(
            id: bindings[action]?.id ?? UUID(),
            action: action,
            key: keyEquivalent,
            characterLabel: displayName
        )
        bindings[action] = binding
        saveBindings()
        
        // Exit capture mode
        isCapturing = false
        capturingAction = nil
    }
    
    /// Clear binding for an action
    func clearBinding(for action: KeyboardAction) {
        if let existing = bindings[action] {
            bindings[action] = KeyBinding(
                id: existing.id,
                action: action,
                key: nil,
                characterLabel: nil
            )
            saveBindings()
        }
    }
    
    /// Start capturing a key for an action
    func startCapturing(for action: KeyboardAction) {
        isCapturing = true
        capturingAction = action
    }
    
    /// Cancel key capture
    func cancelCapturing() {
        isCapturing = false
        capturingAction = nil
    }
    
    /// Handle a key press event
    /// Returns true if the key was handled
    func handleKeyPress(_ keyPress: KeyPress) -> Bool {
        // If we're in capture mode, don't handle as command
        if isCapturing {
            return false
        }
        
        // Find matching action
        for (action, binding) in bindings {
            guard let boundKey = binding.key else { continue }
            
            if keyPress.key == boundKey {
                executeAction(action)
                return true
            }
        }
        
        return false
    }
    
    /// Reset all bindings to defaults
    func resetToDefaults() {
        bindings.removeAll()
        setupDefaultBindingsIfNeeded()
        saveBindings()
    }
    
    // MARK: - Private Methods
    
    private func executeAction(_ action: KeyboardAction) {
        guard let handler = commandHandler else { return }
        
        switch action {
        case .togglePlay:
            handler.handleKeyboardTogglePlay()
        case .play:
            handler.handleKeyboardPlay()
        case .pause:
            handler.handleKeyboardPause()
        case .next:
            handler.handleKeyboardNext()
        case .previous:
            handler.handleKeyboardPrevious()
        case .reset:
            handler.handleKeyboardReset()
        }
    }
    
    private func setupDefaultBindingsIfNeeded() {
        // Only set defaults if no bindings exist
        if bindings.isEmpty {
            // Default: Space = toggle, Right = next, Left = previous
            bindings[.togglePlay] = KeyBinding(
                action: .togglePlay,
                key: .space,
                characterLabel: "Space"
            )
            bindings[.next] = KeyBinding(
                action: .next,
                key: .rightArrow,
                characterLabel: "→"
            )
            bindings[.previous] = KeyBinding(
                action: .previous,
                key: .leftArrow,
                characterLabel: "←"
            )
            
            // Initialize empty bindings for other actions
            for action in KeyboardAction.allCases {
                if bindings[action] == nil {
                    bindings[action] = KeyBinding(action: action)
                }
            }
            
            saveBindings()
        }
    }
    
    private func saveBindings() {
        do {
            let bindingsArray = Array(bindings.values)
            let data = try JSONEncoder().encode(bindingsArray)
            UserDefaults.standard.set(data, forKey: bindingsKey)
        } catch {
            print("Failed to save keyboard bindings: \(error)")
        }
    }
    
    private func loadBindings() {
        guard let data = UserDefaults.standard.data(forKey: bindingsKey) else { return }
        
        do {
            let bindingsArray = try JSONDecoder().decode([KeyBinding].self, from: data)
            bindings = Dictionary(uniqueKeysWithValues: bindingsArray.map { ($0.action, $0) })
        } catch {
            print("Failed to load keyboard bindings: \(error)")
        }
    }
}

// MARK: - VideoPlayerViewModel Extension

extension VideoPlayerViewModel: KeyboardCommandHandler {
    func handleKeyboardTogglePlay() {
        togglePlayPause()
    }
    
    func handleKeyboardPlay() {
        play()
    }
    
    func handleKeyboardPause() {
        pause()
    }
    
    func handleKeyboardNext() {
        loadNext(autoPlay: true)
    }
    
    func handleKeyboardPrevious() {
        loadPrevious(autoPlay: false)
    }
    
    func handleKeyboardReset() {
        resetPlaylist()
    }
}
