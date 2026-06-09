//
//  OSCService.swift
//  VideoPromptOSC
//
//  Created for VideoPromptOSC App
//

import Foundation
import OSCKit

/// OSC command types that can be received
enum OSCCommand: String, CaseIterable {
    case play = "/videoprompt/play"
    case pause = "/videoprompt/pause"
    case toggle = "/videoprompt/toggle"
    case reset = "/videoprompt/reset"
    case next = "/videoprompt/next"
    case previous = "/videoprompt/previous"
    
    var displayName: String {
        switch self {
        case .play: return "PLAY"
        case .pause: return "PAUSE"
        case .toggle: return "TOGGLE"
        case .reset: return "RESET"
        case .next: return "NEXT"
        case .previous: return "PREVIOUS"
        }
    }
}

/// Protocol for handling OSC commands
@MainActor
protocol OSCCommandHandler: AnyObject {
    func handleOSCPlay()
    func handleOSCPause()
    func handleOSCToggle()
    func handleOSCReset()
    func handleOSCNext()
    func handleOSCPrevious()
}

/// Service for receiving OSC messages over UDP
@MainActor
class OSCService: ObservableObject {
    
    // MARK: - Published Properties
    @Published private(set) var isRunning: Bool = false
    @Published private(set) var lastReceivedCommand: OSCCommand?
    @Published private(set) var showFeedback: Bool = false
    
    // MARK: - Configuration
    let port: UInt16
    
    // MARK: - Private Properties
    private var server: OSCServer?
    private weak var commandHandler: OSCCommandHandler?
    private var feedbackTask: Task<Void, Never>?
    
    // MARK: - Initialization
    init(port: UInt16 = 9000) {
        self.port = port
    }
    
    deinit {
        feedbackTask?.cancel()
    }
    
    // MARK: - Public Methods
    
    /// Set the command handler to receive OSC commands
    func setCommandHandler(_ handler: OSCCommandHandler) {
        self.commandHandler = handler
    }
    
    /// Start the OSC server
    func start() async {
        guard !isRunning else { return }
        
        do {
            server = OSCServer(port: port) { [weak self] message, timeTag in
                Task { @MainActor in
                    self?.handleMessage(message)
                }
            }
            
            try server?.start()
            isRunning = true
            print("OSC Server started on port \(port)")
        } catch {
            print("Failed to start OSC server: \(error)")
            isRunning = false
        }
    }
    
    /// Stop the OSC server
    func stop() {
        server?.stop()
        server = nil
        isRunning = false
        print("OSC Server stopped")
    }
    
    // MARK: - Private Methods
    
    private func handleMessage(_ message: OSCMessage) {
        let addressPattern = message.addressPattern.stringValue
        
        guard let command = OSCCommand(rawValue: addressPattern) else {
            print("Unknown OSC address: \(addressPattern)")
            return
        }
        
        print("Received OSC command: \(command.displayName)")
        
        // Update state for feedback
        lastReceivedCommand = command
        triggerFeedback()
        
        // Execute command
        switch command {
        case .play:
            commandHandler?.handleOSCPlay()
        case .pause:
            commandHandler?.handleOSCPause()
        case .toggle:
            commandHandler?.handleOSCToggle()
        case .reset:
            commandHandler?.handleOSCReset()
        case .next:
            commandHandler?.handleOSCNext()
        case .previous:
            commandHandler?.handleOSCPrevious()
        }
    }
    
    private func triggerFeedback() {
        // Cancel any existing feedback animation
        feedbackTask?.cancel()
        
        // Show feedback
        showFeedback = true
        
        // Hide after delay
        feedbackTask = Task {
            try? await Task.sleep(nanoseconds: 600_000_000) // 0.6 seconds
            if !Task.isCancelled {
                showFeedback = false
            }
        }
    }
}
