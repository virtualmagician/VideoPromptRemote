//
//  IProxyService.swift
//  VideoPromptDesktop
//
//  Created for VideoPromptOSC Control App
//

import Foundation
import AppKit

/// Status of the iproxy connection
enum IProxyStatus: Equatable {
    case notInstalled
    case stopped
    case starting
    case waitingForDevice
    case connected
    case error(String)
    
    var displayText: String {
        switch self {
        case .notInstalled:
            return "iproxy not installed"
        case .stopped:
            return "Not running"
        case .starting:
            return "Starting..."
        case .waitingForDevice:
            return "Waiting for iOS device"
        case .connected:
            return "Connected via USB"
        case .error(let message):
            return "Error: \(message)"
        }
    }
    
    var color: NSColor {
        switch self {
        case .notInstalled:
            return .systemRed
        case .stopped:
            return .systemGray
        case .starting:
            return .systemYellow
        case .waitingForDevice:
            return .systemOrange
        case .connected:
            return .systemGreen
        case .error:
            return .systemRed
        }
    }
}

/// Service for managing iproxy process
@MainActor
class IProxyService: ObservableObject {
    
    // MARK: - Published Properties
    @Published private(set) var status: IProxyStatus = .stopped
    @Published private(set) var isLibimobiledeviceInstalled: Bool = false
    @Published private(set) var connectedDeviceId: String?
    @Published var showInstallInstructions: Bool = false
    
    // MARK: - Configuration
    let localPort: UInt16
    let devicePort: UInt16
    
    // MARK: - Private Properties
    private var process: Process?
    private var outputPipe: Pipe?
    private var errorPipe: Pipe?
    private var iproxyPath: String?
    private var ideviceIdPath: String?
    private var deviceCheckTask: Task<Void, Never>?
    
    // Common paths where iproxy might be installed
    private let possiblePaths = [
        "/opt/homebrew/bin/iproxy",      // Apple Silicon Homebrew
        "/usr/local/bin/iproxy",          // Intel Homebrew
        "/opt/local/bin/iproxy",          // MacPorts
        "/usr/bin/iproxy"                 // System
    ]
    
    private let possibleIdeviceIdPaths = [
        "/opt/homebrew/bin/idevice_id",   // Apple Silicon Homebrew
        "/usr/local/bin/idevice_id",       // Intel Homebrew
        "/opt/local/bin/idevice_id",       // MacPorts
        "/usr/bin/idevice_id"              // System
    ]
    
    // MARK: - Initialization
    init(localPort: UInt16 = 9000, devicePort: UInt16 = 9000) {
        self.localPort = localPort
        self.devicePort = devicePort
        checkInstallation()
    }
    
    deinit {
        // Clean up process on deinit (synchronous, non-isolated)
        outputPipe?.fileHandleForReading.readabilityHandler = nil
        errorPipe?.fileHandleForReading.readabilityHandler = nil
        process?.terminate()
        deviceCheckTask?.cancel()
    }
    
    // MARK: - Public Methods
    
    /// Check if libimobiledevice/iproxy is installed
    func checkInstallation() {
        iproxyPath = findToolPath(possiblePaths, toolName: "iproxy")
        ideviceIdPath = findToolPath(possibleIdeviceIdPaths, toolName: "idevice_id")
        isLibimobiledeviceInstalled = iproxyPath != nil
        
        if !isLibimobiledeviceInstalled {
            status = .notInstalled
        } else if status == .notInstalled {
            status = .stopped
        }
    }
    
    /// Start the iproxy process
    func start() {
        guard let path = iproxyPath else {
            status = .notInstalled
            return
        }
        
        // Don't start if already running
        guard process == nil else { return }
        
        status = .starting
        
        let task = Process()
        task.executableURL = URL(fileURLWithPath: path)
        task.arguments = [String(localPort), String(devicePort)]
        
        // Setup pipes to capture output
        outputPipe = Pipe()
        errorPipe = Pipe()
        task.standardOutput = outputPipe
        task.standardError = errorPipe
        
        // Handle process termination
        task.terminationHandler = { [weak self] process in
            Task { @MainActor in
                self?.handleTermination(exitCode: process.terminationStatus)
            }
        }
        
        // Monitor stderr for connection status
        errorPipe?.fileHandleForReading.readabilityHandler = { [weak self] handle in
            let data = handle.availableData
            if !data.isEmpty, let output = String(data: data, encoding: .utf8) {
                Task { @MainActor in
                    self?.handleOutput(output)
                }
            }
        }
        
        do {
            try task.run()
            process = task
            
            // Give it a moment to start, then begin device checking
            Task {
                try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                if self.process?.isRunning == true && self.status == .starting {
                    self.startDeviceChecking()
                }
            }
        } catch {
            status = .error("Failed to start: \(error.localizedDescription)")
            process = nil
        }
    }
    
    /// Stop the iproxy process
    func stop() {
        deviceCheckTask?.cancel()
        deviceCheckTask = nil
        
        outputPipe?.fileHandleForReading.readabilityHandler = nil
        errorPipe?.fileHandleForReading.readabilityHandler = nil
        
        if let runningProcess = process, runningProcess.isRunning {
            runningProcess.terminate()
        }
        process = nil
        connectedDeviceId = nil
        
        if status != .notInstalled {
            status = .stopped
        }
    }
    
    /// Restart the iproxy process
    func restart() {
        stop()
        Task {
            try? await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
            start()
        }
    }
    
    /// Open Terminal to install libimobiledevice via Homebrew
    func installLibimobiledevice() {
        // First check if Homebrew is installed
        let brewPath = FileManager.default.fileExists(atPath: "/opt/homebrew/bin/brew") 
            ? "/opt/homebrew/bin/brew" 
            : "/usr/local/bin/brew"
        
        let homebrewInstalled = FileManager.default.fileExists(atPath: brewPath)
        
        let script: String
        if homebrewInstalled {
            // Homebrew is installed, just install libimobiledevice
            script = """
            tell application "Terminal"
                activate
                do script "\(brewPath) install libimobiledevice && echo '\\n✅ Installation complete! You can close this window.' || echo '\\n❌ Installation failed.'"
            end tell
            """
        } else {
            // Need to install Homebrew first
            script = """
            tell application "Terminal"
                activate
                do script "/bin/bash -c \\"$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\\" && brew install libimobiledevice && echo '\\n✅ Installation complete! You can close this window.' || echo '\\n❌ Installation failed.'"
            end tell
            """
        }
        
        var error: NSDictionary?
        if let appleScript = NSAppleScript(source: script) {
            appleScript.executeAndReturnError(&error)
            if let error = error {
                print("AppleScript error: \(error)")
            }
        }
        
        showInstallInstructions = true
    }
    
    // MARK: - Private Methods
    
    private func findToolPath(_ paths: [String], toolName: String) -> String? {
        for path in paths {
            if FileManager.default.fileExists(atPath: path) {
                return path
            }
        }
        
        // Try using 'which' command as fallback
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/which")
        task.arguments = [toolName]
        
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = FileHandle.nullDevice
        
        do {
            try task.run()
            task.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let path = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines),
               !path.isEmpty {
                return path
            }
        } catch {
            // Silently fail, tool not found
        }
        
        return nil
    }
    
    private func startDeviceChecking() {
        deviceCheckTask?.cancel()
        
        deviceCheckTask = Task {
            while !Task.isCancelled {
                await checkConnectedDevice()
                try? await Task.sleep(nanoseconds: 2_000_000_000) // Check every 2 seconds
            }
        }
    }
    
    private func checkConnectedDevice() async {
        guard let path = ideviceIdPath else {
            // No idevice_id available, just assume waiting
            if process?.isRunning == true {
                status = .waitingForDevice
            }
            return
        }
        
        let deviceId = await runIdeviceId(path: path)
        
        if let deviceId = deviceId, !deviceId.isEmpty {
            connectedDeviceId = deviceId
            if process?.isRunning == true {
                status = .connected
            }
        } else {
            connectedDeviceId = nil
            if process?.isRunning == true {
                status = .waitingForDevice
            }
        }
    }
    
    private func runIdeviceId(path: String) async -> String? {
        return await withCheckedContinuation { continuation in
            let task = Process()
            task.executableURL = URL(fileURLWithPath: path)
            task.arguments = ["-l"]
            
            let pipe = Pipe()
            task.standardOutput = pipe
            task.standardError = FileHandle.nullDevice
            
            do {
                try task.run()
                task.waitUntilExit()
                
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                if let output = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines),
                   !output.isEmpty {
                    // Return first device ID (one per line)
                    let firstDevice = output.components(separatedBy: .newlines).first
                    continuation.resume(returning: firstDevice)
                } else {
                    continuation.resume(returning: nil)
                }
            } catch {
                continuation.resume(returning: nil)
            }
        }
    }
    
    private func handleOutput(_ output: String) {
        print("iproxy: \(output)")
        
        // Check for common status messages
        if output.contains("waiting for device") || output.contains("Waiting for device") {
            status = .waitingForDevice
        } else if output.contains("accepted connection") || output.contains("Creating socket") {
            status = .connected
        } else if output.contains("error") || output.contains("Error") {
            if output.contains("No device found") {
                status = .waitingForDevice
            } else {
                status = .error("Connection error")
            }
        }
    }
    
    private func handleTermination(exitCode: Int32) {
        process = nil
        
        if exitCode != 0 && status != .stopped {
            if exitCode == 1 {
                status = .error("No iOS device found")
            } else {
                status = .error("Exited with code \(exitCode)")
            }
        } else if status != .notInstalled {
            status = .stopped
        }
    }
}
