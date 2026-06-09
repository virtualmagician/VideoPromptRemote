//
//  VideoPromptApp.swift
//  VideoPromptOSC
//
//  Created for VideoPromptOSC App
//

import SwiftUI
import AVFoundation

@main
struct VideoPromptApp: App {
    @StateObject private var oscService = OSCService(port: 9000)
    @StateObject private var volumeButtonService = VolumeButtonService()
    @StateObject private var playlistService = PlaylistService()
    @StateObject private var keyboardService = KeyboardService()
    @Environment(\.scenePhase) private var scenePhase
    
    init() {
        // Configure audio session to respect silent/ringer switch
        configureAudioSession()
        // Prevent screen from locking/sleeping while app is running
        UIApplication.shared.isIdleTimerDisabled = true
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(oscService)
                .environmentObject(volumeButtonService)
                .environmentObject(playlistService)
                .environmentObject(keyboardService)
                .preferredColorScheme(.dark)
                .task {
                    // Start OSC server when app launches
                    await oscService.start()
                }
                .onOpenURL { url in
                    handleIncomingURL(url)
                }
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            switch newPhase {
            case .active:
                // Re-enable idle timer disable when app becomes active
                UIApplication.shared.isIdleTimerDisabled = true
                // Re-enable volume button detection
                volumeButtonService.setEnabled(true)
            case .inactive, .background:
                // Allow normal idle timer when app is in background
                UIApplication.shared.isIdleTimerDisabled = false
                // Disable volume button detection in background
                volumeButtonService.setEnabled(false)
            @unknown default:
                break
            }
        }
    }
    
    private func configureAudioSession() {
        do {
            // Using .ambient category respects the silent switch
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .moviePlayback)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to configure audio session: \(error)")
        }
    }
    
    private func handleIncomingURL(_ url: URL) {
        // Handle AirDrop and other incoming video files
        print("Received incoming URL: \(url)")
        
        // Check if it's a video file
        let supportedExtensions = ["mov", "mp4", "m4v", "avi", "mkv"]
        let fileExtension = url.pathExtension.lowercased()
        
        guard supportedExtensions.contains(fileExtension) else {
            print("Unsupported file type: \(fileExtension)")
            return
        }
        
        // Start accessing security-scoped resource
        let accessing = url.startAccessingSecurityScopedResource()
        defer {
            if accessing {
                url.stopAccessingSecurityScopedResource()
            }
        }
        
        // Add to playlist
        Task { @MainActor in
            if let _ = playlistService.add(from: url) {
                print("Added video to playlist: \(url.lastPathComponent)")
            } else {
                print("Failed to add video to playlist")
            }
        }
    }
}
