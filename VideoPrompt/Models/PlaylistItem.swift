//
//  PlaylistItem.swift
//  VideoPromptOSC
//
//  Created for VideoPromptOSC App
//

import Foundation

struct PlaylistItem: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    var filename: String
    var displayName: String
    let dateAdded: Date
    
    init(id: UUID = UUID(), filename: String, displayName: String? = nil, dateAdded: Date = Date()) {
        self.id = id
        self.filename = filename
        self.displayName = displayName ?? Self.extractDisplayName(from: filename)
        self.dateAdded = dateAdded
    }
    
    var fileURL: URL {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentsDirectory.appendingPathComponent(filename)
    }
    
    var exists: Bool {
        FileManager.default.fileExists(atPath: fileURL.path)
    }
    
    private static func extractDisplayName(from filename: String) -> String {
        let name = (filename as NSString).deletingPathExtension
        return name
            .replacingOccurrences(of: "_", with: " ")
            .replacingOccurrences(of: "-", with: " ")
    }
}
