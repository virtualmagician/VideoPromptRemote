//
//  OSCClientService.swift
//  VideoPromptDesktop
//
//  Created for VideoPromptOSC Control App
//

import Foundation
import OSCKit

/// OSC command types that can be sent
enum OSCCommand: String, CaseIterable, Identifiable {
    case play = "/videoprompt/play"
    case pause = "/videoprompt/pause"
    case toggle = "/videoprompt/toggle"
    case reset = "/videoprompt/reset"
    case next = "/videoprompt/next"
    case previous = "/videoprompt/previous"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .play: return "PLAY"
        case .pause: return "PAUSE"
        case .toggle: return "TOGGLE"
        case .reset: return "RESET"
        case .next: return "NEXT"
        case .previous: return "PREV"
        }
    }
    
    var iconName: String {
        switch self {
        case .play: return "play.fill"
        case .pause: return "pause.fill"
        case .toggle: return "playpause.fill"
        case .reset: return "arrow.counterclockwise"
        case .next: return "forward.fill"
        case .previous: return "backward.fill"
        }
    }
    
    var keyboardShortcut: String {
        switch self {
        case .play: return "↵"
        case .pause: return "⎋"
        case .toggle: return "␣"
        case .reset: return "R"
        case .next: return "→"
        case .previous: return "←"
        }
    }
}

/// Service for sending OSC messages to VideoPromptOSC on iOS
@MainActor
class OSCClientService: ObservableObject {
    
    // MARK: - Published Properties
    @Published var host: String {
        didSet { saveSettings() }
    }
    @Published var port: UInt16 {
        didSet { saveSettings() }
    }
    @Published private(set) var lastSentCommand: OSCCommand?
    @Published private(set) var showFeedback: Bool = false
    @Published var showSettings: Bool = false
    
    // MARK: - Private Properties
    private var client: OSCClient?
    private var feedbackTask: Task<Void, Never>?
    
    // UserDefaults keys
    private let hostKey = "osc_host"
    private let portKey = "osc_port"
    
    // MARK: - Initialization
    init() {
        // Load saved settings or use defaults
        self.host = UserDefaults.standard.string(forKey: hostKey) ?? "127.0.0.1"
        self.port = UInt16(UserDefaults.standard.integer(forKey: portKey))
        if self.port == 0 {
            self.port = 9000
        }
        
        setupClient()
    }
    
    deinit {
        feedbackTask?.cancel()
    }
    
    // MARK: - Public Methods
    
    /// Send an OSC command to the configured target
    func send(_ command: OSCCommand) {
        let message = OSCMessage(command.rawValue)
        
        do {
            try client?.send(message, to: host, port: port)
            print("Sent OSC: \(command.rawValue) to \(host):\(port)")
            
            // Update state for visual feedback
            lastSentCommand = command
            triggerFeedback()
        } catch {
            print("Failed to send OSC message: \(error)")
        }
    }
    
    /// Reconnect the client (useful after changing settings)
    func reconnect() {
        setupClient()
    }
    
    // MARK: - Private Methods
    
    private func setupClient() {
        client = OSCClient()
    }
    
    private func saveSettings() {
        UserDefaults.standard.set(host, forKey: hostKey)
        UserDefaults.standard.set(Int(port), forKey: portKey)
    }
    
    private func triggerFeedback() {
        // Cancel any existing feedback animation
        feedbackTask?.cancel()
        
        // Show feedback
        showFeedback = true
        
        // Hide after delay
        feedbackTask = Task {
            try? await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds
            if !Task.isCancelled {
                showFeedback = false
            }
        }
    }
}
