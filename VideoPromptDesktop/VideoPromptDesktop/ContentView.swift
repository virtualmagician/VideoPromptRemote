//
//  ContentView.swift
//  VideoPromptDesktop
//
//  Created for VideoPromptOSC Control App
//

import SwiftUI

struct ContentView: View {
    @ObservedObject var oscService: OSCClientService
    @ObservedObject var iproxyService: IProxyService
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView
            
            Divider()
                .background(Color.white.opacity(0.2))
            
            // Main content
            if !iproxyService.isLibimobiledeviceInstalled {
                // Installation required view
                installationRequiredView
            } else {
                // Button Grid
                buttonGrid
                    .padding(16)
            }
            
            Divider()
                .background(Color.white.opacity(0.2))
            
            // Status Bar
            statusBar
        }
        .background(Color(nsColor: .windowBackgroundColor))
        .sheet(isPresented: $oscService.showSettings) {
            SettingsView(oscService: oscService, iproxyService: iproxyService)
        }
        .alert("Installation Started", isPresented: $iproxyService.showInstallInstructions) {
            Button("OK") {
                // Recheck installation after user dismisses
                iproxyService.checkInstallation()
            }
        } message: {
            Text("A Terminal window has opened to install libimobiledevice.\n\nOnce installation completes, click OK to continue.")
        }
    }
    
    // MARK: - Header
    
    private var headerView: some View {
        HStack {
            Text("VideoPromptOSC")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.primary)
            
            Spacer()
            
            // Refresh button (to recheck installation)
            if !iproxyService.isLibimobiledeviceInstalled {
                Button(action: { iproxyService.checkInstallation() }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .help("Check installation again")
            }
            
            Button(action: { oscService.showSettings = true }) {
                Image(systemName: "gearshape")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
            .help("Settings")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
    
    // MARK: - Installation Required View
    
    private var installationRequiredView: some View {
        VStack(spacing: 16) {
            Spacer()
            
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 36))
                .foregroundColor(.orange)
            
            Text("libimobiledevice Required")
                .font(.system(size: 14, weight: .semibold))
            
            Text("This app needs libimobiledevice to communicate with your iOS device over USB.")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
            
            Button(action: { iproxyService.installLibimobiledevice() }) {
                HStack {
                    Image(systemName: "arrow.down.circle")
                    Text("Install via Homebrew")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding(.horizontal, 40)
            
            Text("Or run in Terminal:")
                .font(.system(size: 11))
                .foregroundColor(.secondary)
            
            Text("brew install libimobiledevice")
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(.secondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.black.opacity(0.2))
                )
                .textSelection(.enabled)
            
            Spacer()
        }
        .frame(height: 220)
        .padding(.vertical, 8)
    }
    
    // MARK: - Button Grid
    
    private var buttonGrid: some View {
        VStack(spacing: 10) {
            // Row 1: Play / Pause
            HStack(spacing: 10) {
                ControlButton(
                    command: .play,
                    isHighlighted: oscService.showFeedback && oscService.lastSentCommand == .play
                ) {
                    oscService.send(.play)
                }
                
                ControlButton(
                    command: .pause,
                    isHighlighted: oscService.showFeedback && oscService.lastSentCommand == .pause
                ) {
                    oscService.send(.pause)
                }
            }
            
            // Row 2: Toggle / Reset
            HStack(spacing: 10) {
                ControlButton(
                    command: .toggle,
                    isHighlighted: oscService.showFeedback && oscService.lastSentCommand == .toggle
                ) {
                    oscService.send(.toggle)
                }
                
                ControlButton(
                    command: .reset,
                    isHighlighted: oscService.showFeedback && oscService.lastSentCommand == .reset
                ) {
                    oscService.send(.reset)
                }
            }
            
            // Row 3: Previous / Next
            HStack(spacing: 10) {
                ControlButton(
                    command: .previous,
                    isHighlighted: oscService.showFeedback && oscService.lastSentCommand == .previous
                ) {
                    oscService.send(.previous)
                }
                
                ControlButton(
                    command: .next,
                    isHighlighted: oscService.showFeedback && oscService.lastSentCommand == .next
                ) {
                    oscService.send(.next)
                }
            }
        }
        .frame(height: 240)
    }
    
    // MARK: - Status Bar
    
    private var statusBar: some View {
        HStack(spacing: 6) {
            // Connection indicator
            Circle()
                .fill(oscService.host == "127.0.0.1" ? Color.orange : Color.green)
                .frame(width: 8, height: 8)
            
            // OSC target
            Text("OSC → \(oscService.host):\(oscService.port)")
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundColor(.secondary)
                .lineLimit(1)
            
            if oscService.host == "127.0.0.1" {
                Text("(Set iPhone IP)")
                    .font(.system(size: 9))
                    .foregroundColor(.orange)
            }
            
            Spacer()
            
            // Command feedback
            if oscService.showFeedback, let command = oscService.lastSentCommand {
                Text("→ \(command.displayName)")
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundColor(.green)
                    .transition(.opacity)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .animation(.easeOut(duration: 0.15), value: oscService.showFeedback)
    }
}

// MARK: - Settings View

struct SettingsView: View {
    @ObservedObject var oscService: OSCClientService
    @ObservedObject var iproxyService: IProxyService
    @Environment(\.dismiss) private var dismiss
    
    @State private var hostText: String = ""
    @State private var portText: String = ""
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Settings")
                .font(.headline)
            
            // Connection Settings
            VStack(alignment: .leading, spacing: 12) {
                Text("OSC Connection (WiFi)")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.secondary)
                
                Text("Enter your iPhone's WiFi IP address.\nFind it in Settings → Wi-Fi → tap (i) on your network.")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("iPhone IP")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.secondary)
                        
                        TextField("192.168.1.x", text: $hostText)
                            .textFieldStyle(.roundedBorder)
                            .font(.system(.body, design: .monospaced))
                            .frame(width: 140)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Port")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.secondary)
                        
                        TextField("9000", text: $portText)
                            .textFieldStyle(.roundedBorder)
                            .font(.system(.body, design: .monospaced))
                            .frame(width: 80)
                    }
                }
            }
            
            Divider()
            
            // iproxy Status
            VStack(alignment: .leading, spacing: 8) {
                Text("USB Connection (iproxy)")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.secondary)
                
                HStack {
                    Circle()
                        .fill(Color(nsColor: iproxyService.status.color))
                        .frame(width: 10, height: 10)
                    
                    Text(iproxyService.status.displayText)
                        .font(.system(size: 12))
                    
                    Spacer()
                    
                    if iproxyService.isLibimobiledeviceInstalled {
                        Button(action: { iproxyService.restart() }) {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 12))
                        }
                        .buttonStyle(.plain)
                        .help("Restart iproxy")
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            Divider()
            
            // Keyboard Shortcuts
            VStack(alignment: .leading, spacing: 8) {
                Text("Keyboard Shortcuts")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.secondary)
                
                HStack(spacing: 16) {
                    shortcutLabel("↵ Enter", "Play")
                    shortcutLabel("⎋ Esc", "Pause")
                }
                HStack(spacing: 16) {
                    shortcutLabel("␣ Space", "Toggle")
                    shortcutLabel("R", "Reset")
                }
                HStack(spacing: 16) {
                    shortcutLabel("← Left", "Previous")
                    shortcutLabel("→ Right", "Next")
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            Spacer()
            
            HStack {
                Button("Reset to Defaults") {
                    hostText = "127.0.0.1"
                    portText = "9000"
                }
                .buttonStyle(.plain)
                .foregroundColor(.secondary)
                
                Spacer()
                
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)
                
                Button("Save") {
                    saveSettings()
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(24)
        .frame(width: 340, height: 460)
        .onAppear {
            hostText = oscService.host
            portText = String(oscService.port)
        }
    }
    
    private func shortcutLabel(_ shortcut: String, _ action: String) -> some View {
        HStack(spacing: 4) {
            Text(shortcut)
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundColor(.primary)
            Text(action)
                .font(.system(size: 11))
                .foregroundColor(.secondary)
        }
        .frame(width: 110, alignment: .leading)
    }
    
    private func saveSettings() {
        oscService.host = hostText
        if let port = UInt16(portText), port > 0 {
            oscService.port = port
        }
        oscService.reconnect()
    }
}

#Preview {
    ContentView(oscService: OSCClientService(), iproxyService: IProxyService())
        .frame(width: 280, height: 320)
}
