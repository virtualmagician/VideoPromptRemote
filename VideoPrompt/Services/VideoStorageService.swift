//
//  VideoStorageService.swift
//  VideoPromptOSC
//
//  Created for VideoPromptOSC App
//

import Foundation

class VideoStorageService {
    
    // MARK: - Constants
    private let savedVideoKey = "savedVideoFileName"
    private let videoFileName = "saved_video"
    
    // MARK: - Private Properties
    private var documentsDirectory: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    // MARK: - Public Methods
    
    /// Save video from source URL to app's documents directory
    /// Returns the new URL if successful, nil otherwise
    func saveVideo(from sourceURL: URL) -> URL? {
        // Start accessing security-scoped resource if needed
        let shouldStopAccessing = sourceURL.startAccessingSecurityScopedResource()
        defer {
            if shouldStopAccessing {
                sourceURL.stopAccessingSecurityScopedResource()
            }
        }
        
        // Get file extension from source
        let fileExtension = sourceURL.pathExtension
        let destinationFileName = "\(videoFileName).\(fileExtension)"
        let destinationURL = documentsDirectory.appendingPathComponent(destinationFileName)
        
        do {
            // Remove existing file if present
            if FileManager.default.fileExists(atPath: destinationURL.path) {
                try FileManager.default.removeItem(at: destinationURL)
            }
            
            // Copy new file
            try FileManager.default.copyItem(at: sourceURL, to: destinationURL)
            
            // Save file name to UserDefaults
            UserDefaults.standard.set(destinationFileName, forKey: savedVideoKey)
            
            return destinationURL
        } catch {
            print("Failed to save video: \(error)")
            return nil
        }
    }
    
    /// Get the URL of the previously saved video
    func getSavedVideoURL() -> URL? {
        guard let fileName = UserDefaults.standard.string(forKey: savedVideoKey) else {
            return nil
        }
        
        let videoURL = documentsDirectory.appendingPathComponent(fileName)
        
        // Verify file exists
        if FileManager.default.fileExists(atPath: videoURL.path) {
            return videoURL
        }
        
        return nil
    }
    
    /// Clear saved video reference
    func clearSavedVideo() {
        if let fileName = UserDefaults.standard.string(forKey: savedVideoKey) {
            let videoURL = documentsDirectory.appendingPathComponent(fileName)
            try? FileManager.default.removeItem(at: videoURL)
        }
        
        UserDefaults.standard.removeObject(forKey: savedVideoKey)
    }
}
