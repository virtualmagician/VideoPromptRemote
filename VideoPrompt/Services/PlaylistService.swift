//
//  PlaylistService.swift
//  VideoPromptOSC
//
//  Created for VideoPromptOSC App
//

import Foundation
import Combine

@MainActor
class PlaylistService: ObservableObject {
    
    // MARK: - Published Properties
    @Published private(set) var items: [PlaylistItem] = []
    @Published var currentIndex: Int = 0
    
    // MARK: - Constants
    private let playlistKey = "playlistItems"
    private let currentIndexKey = "playlistCurrentIndex"
    private let legacyVideoKey = "savedVideoFileName"
    
    // MARK: - Private Properties
    private var documentsDirectory: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    // MARK: - Computed Properties
    var currentItem: PlaylistItem? {
        guard currentIndex >= 0 && currentIndex < items.count else { return nil }
        return items[currentIndex]
    }
    
    var hasNext: Bool {
        currentIndex < items.count - 1
    }
    
    var hasPrevious: Bool {
        currentIndex > 0
    }
    
    var isEmpty: Bool {
        items.isEmpty
    }
    
    // MARK: - Initialization
    init() {
        load()
        migrateFromLegacyStorageIfNeeded()
    }
    
    // MARK: - Public Methods
    
    /// Add a video from source URL to the playlist
    func add(from sourceURL: URL) -> PlaylistItem? {
        let shouldStopAccessing = sourceURL.startAccessingSecurityScopedResource()
        defer {
            if shouldStopAccessing {
                sourceURL.stopAccessingSecurityScopedResource()
            }
        }
        
        let originalFilename = sourceURL.lastPathComponent
        let uniqueFilename = generateUniqueFilename(for: originalFilename)
        let destinationURL = documentsDirectory.appendingPathComponent(uniqueFilename)
        
        do {
            try FileManager.default.copyItem(at: sourceURL, to: destinationURL)
            
            let item = PlaylistItem(
                filename: uniqueFilename,
                displayName: (originalFilename as NSString).deletingPathExtension
            )
            items.append(item)
            save()
            
            return item
        } catch {
            print("Failed to add video to playlist: \(error)")
            return nil
        }
    }
    
    /// Remove item at index and delete the file
    func remove(at offsets: IndexSet) {
        for index in offsets {
            let item = items[index]
            try? FileManager.default.removeItem(at: item.fileURL)
        }
        
        items.remove(atOffsets: offsets)
        
        // Adjust current index if needed
        if currentIndex >= items.count {
            currentIndex = max(0, items.count - 1)
        }
        
        save()
    }
    
    /// Remove a specific item
    func remove(item: PlaylistItem) {
        if let index = items.firstIndex(of: item) {
            remove(at: IndexSet(integer: index))
        }
    }
    
    /// Move items in the playlist
    func move(from source: IndexSet, to destination: Int) {
        // Track current item before move
        let currentItem = self.currentItem
        
        items.move(fromOffsets: source, toOffset: destination)
        
        // Update current index to follow the current item
        if let currentItem = currentItem,
           let newIndex = items.firstIndex(of: currentItem) {
            currentIndex = newIndex
        }
        
        save()
    }
    
    /// Go to next item in playlist
    func goToNext() -> Bool {
        guard hasNext else { return false }
        currentIndex += 1
        save()
        return true
    }
    
    /// Go to previous item in playlist
    func goToPrevious() -> Bool {
        guard hasPrevious else { return false }
        currentIndex -= 1
        save()
        return true
    }
    
    /// Reset to beginning of playlist
    func resetToStart() {
        currentIndex = 0
        save()
    }
    
    /// Set current index to specific item
    func setCurrentIndex(_ index: Int) {
        guard index >= 0 && index < items.count else { return }
        currentIndex = index
        save()
    }
    
    /// Update display name for an item
    func updateDisplayName(for item: PlaylistItem, newName: String) {
        guard let index = items.firstIndex(of: item) else { return }
        items[index].displayName = newName
        save()
    }
    
    // MARK: - Persistence
    
    private func save() {
        do {
            let data = try JSONEncoder().encode(items)
            UserDefaults.standard.set(data, forKey: playlistKey)
            UserDefaults.standard.set(currentIndex, forKey: currentIndexKey)
        } catch {
            print("Failed to save playlist: \(error)")
        }
    }
    
    private func load() {
        guard let data = UserDefaults.standard.data(forKey: playlistKey) else { return }
        
        do {
            items = try JSONDecoder().decode([PlaylistItem].self, from: data)
            currentIndex = UserDefaults.standard.integer(forKey: currentIndexKey)
            
            // Validate current index
            if currentIndex >= items.count {
                currentIndex = max(0, items.count - 1)
            }
            
            // Remove items whose files no longer exist
            items = items.filter { $0.exists }
        } catch {
            print("Failed to load playlist: \(error)")
        }
    }
    
    // MARK: - Migration
    
    private func migrateFromLegacyStorageIfNeeded() {
        // Check if we already have playlist items
        guard items.isEmpty else { return }
        
        // Check for legacy single video
        guard let legacyFilename = UserDefaults.standard.string(forKey: legacyVideoKey) else { return }
        
        let legacyURL = documentsDirectory.appendingPathComponent(legacyFilename)
        guard FileManager.default.fileExists(atPath: legacyURL.path) else { return }
        
        // Create playlist item from legacy video
        let item = PlaylistItem(
            filename: legacyFilename,
            displayName: (legacyFilename as NSString).deletingPathExtension
        )
        items.append(item)
        currentIndex = 0
        save()
        
        // Clear legacy key
        UserDefaults.standard.removeObject(forKey: legacyVideoKey)
        
        print("Migrated legacy video to playlist: \(legacyFilename)")
    }
    
    // MARK: - Helpers
    
    private func generateUniqueFilename(for originalFilename: String) -> String {
        let name = (originalFilename as NSString).deletingPathExtension
        let ext = (originalFilename as NSString).pathExtension
        
        var filename = originalFilename
        var counter = 1
        
        while FileManager.default.fileExists(atPath: documentsDirectory.appendingPathComponent(filename).path) {
            filename = "\(name)_\(counter).\(ext)"
            counter += 1
        }
        
        return filename
    }
}
