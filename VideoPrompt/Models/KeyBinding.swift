//
//  KeyBinding.swift
//  VideoPromptOSC
//
//  Created for VideoPromptOSC App
//

import Foundation
import SwiftUI

/// Actions that can be triggered by keyboard shortcuts
enum KeyboardAction: String, Codable, CaseIterable, Identifiable {
    case togglePlay
    case play
    case pause
    case next
    case previous
    case reset
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .togglePlay: return "Toggle Play/Pause"
        case .play: return "Play"
        case .pause: return "Pause"
        case .next: return "Next Video"
        case .previous: return "Previous Video"
        case .reset: return "Reset Playlist"
        }
    }
    
    var iconName: String {
        switch self {
        case .togglePlay: return "playpause.fill"
        case .play: return "play.fill"
        case .pause: return "pause.fill"
        case .next: return "forward.fill"
        case .previous: return "backward.fill"
        case .reset: return "arrow.counterclockwise"
        }
    }
}

/// Represents a keyboard shortcut binding
struct KeyBinding: Codable, Identifiable, Equatable {
    let id: UUID
    var action: KeyboardAction
    var key: KeyEquivalent?
    var characterLabel: String?
    
    init(id: UUID = UUID(), action: KeyboardAction, key: KeyEquivalent? = nil, characterLabel: String? = nil) {
        self.id = id
        self.action = action
        self.key = key
        self.characterLabel = characterLabel
    }
    
    var displayKey: String {
        guard let label = characterLabel else { return "Not Set" }
        return label
    }
    
    var isSet: Bool {
        key != nil
    }
    
    // Custom coding for KeyEquivalent since it's not directly Codable
    enum CodingKeys: String, CodingKey {
        case id, action, keyCharacter, characterLabel
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        action = try container.decode(KeyboardAction.self, forKey: .action)
        characterLabel = try container.decodeIfPresent(String.self, forKey: .characterLabel)
        
        if let keyChar = try container.decodeIfPresent(String.self, forKey: .keyCharacter) {
            key = KeyEquivalent(keyChar)
        } else {
            key = nil
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(action, forKey: .action)
        try container.encodeIfPresent(characterLabel, forKey: .characterLabel)
        
        if let key = key {
            try container.encode(String(key.character), forKey: .keyCharacter)
        }
    }
}

/// Extension to create KeyEquivalent from a string
extension KeyEquivalent {
    init(_ string: String) {
        if let first = string.first {
            self.init(first)
        } else {
            self.init(" ")
        }
    }
}

/// Helper to get display name for special keys
struct KeyDisplayHelper {
    static func displayName(for keyPress: KeyPress) -> String {
        switch keyPress.key {
        case .space: return "Space"
        case .return: return "Return"
        case .tab: return "Tab"
        case .escape: return "Escape"
        case .delete: return "Delete"
        case .upArrow: return "↑"
        case .downArrow: return "↓"
        case .leftArrow: return "←"
        case .rightArrow: return "→"
        case .home: return "Home"
        case .end: return "End"
        case .pageUp: return "Page Up"
        case .pageDown: return "Page Down"
        default:
            let char = keyPress.characters
            if char.isEmpty {
                return "Unknown"
            }
            return char.uppercased()
        }
    }
    
    static func keyEquivalent(from keyPress: KeyPress) -> KeyEquivalent {
        return keyPress.key
    }
}
