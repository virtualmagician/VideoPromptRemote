//
//  VolumeButtonService.swift
//  VideoPromptOSC
//
//  Created for VideoPromptOSC App
//

import Foundation
import AVFoundation
import MediaPlayer

/// Protocol for handling volume button events
@MainActor
protocol VolumeButtonHandler: AnyObject {
    func handleVolumeButtonSinglePress()
    func handleVolumeButtonDoublePress()
}

/// Service for detecting volume button presses from Bluetooth remotes
/// Uses volume change observation to detect button presses
@MainActor
class VolumeButtonService: ObservableObject {
    
    // MARK: - Published Properties
    @Published private(set) var isEnabled: Bool = true
    @Published private(set) var lastPressTime: Date?
    
    // MARK: - Configuration
    /// Time window for detecting double-press (in seconds)
    let doublePressInterval: TimeInterval = 0.4
    
    // MARK: - Private Properties
    private weak var handler: VolumeButtonHandler?
    private var volumeObserver: NSKeyValueObservation?
    private var lastVolume: Float = 0.5
    private var pendingSinglePress: Task<Void, Never>?
    private var volumeView: MPVolumeView?
    private var isProcessingPress: Bool = false
    
    // MARK: - Initialization
    init() {
        setupVolumeObservation()
    }
    
    deinit {
        volumeObserver?.invalidate()
    }
    
    // MARK: - Public Methods
    
    /// Set the handler for volume button events
    func setHandler(_ handler: VolumeButtonHandler) {
        self.handler = handler
    }
    
    /// Enable or disable volume button detection
    func setEnabled(_ enabled: Bool) {
        isEnabled = enabled
    }
    
    // MARK: - Private Methods
    
    private func setupVolumeObservation() {
        let audioSession = AVAudioSession.sharedInstance()
        
        // Store initial volume
        lastVolume = audioSession.outputVolume
        
        // Observe volume changes
        volumeObserver = audioSession.observe(\.outputVolume, options: [.new, .old]) { [weak self] session, change in
            Task { @MainActor in
                self?.handleVolumeChange(newVolume: change.newValue ?? session.outputVolume)
            }
        }
        
        // Create hidden volume view to intercept volume HUD
        // This helps prevent the system volume popup from appearing
        setupHiddenVolumeView()
    }
    
    private func setupHiddenVolumeView() {
        // Create an MPVolumeView off-screen to suppress the system volume HUD
        let volumeView = MPVolumeView(frame: CGRect(x: -1000, y: -1000, width: 1, height: 1))
        volumeView.alpha = 0.01
        self.volumeView = volumeView
        
        // Add to a window if available
        DispatchQueue.main.async {
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first {
                window.addSubview(volumeView)
            }
        }
    }
    
    private func handleVolumeChange(newVolume: Float) {
        guard isEnabled else { return }
        guard !isProcessingPress else { return }
        
        // Detect if volume went up (button press we care about)
        let volumeIncreased = newVolume > lastVolume
        
        // Update stored volume
        let previousVolume = lastVolume
        lastVolume = newVolume
        
        // Only respond to volume UP
        guard volumeIncreased else { return }
        
        // Prevent rapid-fire processing
        isProcessingPress = true
        
        // Check for double-press
        let now = Date()
        if let lastPress = lastPressTime,
           now.timeIntervalSince(lastPress) < doublePressInterval {
            // Double press detected!
            pendingSinglePress?.cancel()
            pendingSinglePress = nil
            lastPressTime = nil
            
            print("Volume button: DOUBLE PRESS detected")
            handler?.handleVolumeButtonDoublePress()
            
            // Reset volume to prevent it from maxing out
            resetVolume(to: previousVolume)
            
            // Allow next press after a short delay
            Task {
                try? await Task.sleep(nanoseconds: 200_000_000)
                isProcessingPress = false
            }
        } else {
            // Potential single press - wait to see if another comes
            lastPressTime = now
            
            pendingSinglePress?.cancel()
            pendingSinglePress = Task {
                // Wait for potential second press
                try? await Task.sleep(nanoseconds: UInt64(doublePressInterval * 1_000_000_000))
                
                guard !Task.isCancelled else { return }
                
                // No second press came - this is a single press
                print("Volume button: SINGLE PRESS detected")
                handler?.handleVolumeButtonSinglePress()
                lastPressTime = nil
                
                // Reset volume to prevent it from maxing out
                resetVolume(to: previousVolume)
                isProcessingPress = false
            }
            
            // Allow immediate processing of next press for double-tap detection
            Task {
                try? await Task.sleep(nanoseconds: 50_000_000)
                isProcessingPress = false
            }
        }
    }
    
    private func resetVolume(to targetVolume: Float) {
        // Use MPVolumeView's slider to reset volume without showing HUD
        if let slider = volumeView?.subviews.first(where: { $0 is UISlider }) as? UISlider {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                slider.value = targetVolume
                self.lastVolume = targetVolume
            }
        }
    }
}
