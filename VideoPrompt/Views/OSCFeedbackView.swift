//
//  OSCFeedbackView.swift
//  VideoPromptOSC
//
//  Created for VideoPromptOSC App
//

import SwiftUI

/// Visual feedback overlay shown when OSC commands are received
struct OSCFeedbackView: View {
    let command: OSCCommand?
    let isVisible: Bool
    
    var body: some View {
        ZStack {
            if isVisible, let command = command {
                // Background pulse
                RoundedRectangle(cornerRadius: 16)
                    .fill(commandColor(for: command).opacity(0.25))
                    .frame(width: 160, height: 70)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(commandColor(for: command).opacity(0.6), lineWidth: 2)
                    )
                
                // Command text
                VStack(spacing: 4) {
                    Image(systemName: commandIcon(for: command))
                        .font(.system(size: 22, weight: .semibold))
                    Text(command.displayName)
                        .font(.system(size: 16, weight: .bold, design: .monospaced))
                }
                .foregroundColor(commandColor(for: command))
            }
        }
        .animation(.easeOut(duration: 0.15), value: isVisible)
        .animation(.easeOut(duration: 0.15), value: command)
    }
    
    private func commandColor(for command: OSCCommand) -> Color {
        switch command {
        case .play:
            return .green
        case .pause:
            return .orange
        case .toggle:
            return .cyan
        case .reset:
            return .yellow
        case .next:
            return .blue
        case .previous:
            return .purple
        }
    }
    
    private func commandIcon(for command: OSCCommand) -> String {
        switch command {
        case .play:
            return "play.fill"
        case .pause:
            return "pause.fill"
        case .toggle:
            return "playpause.fill"
        case .reset:
            return "arrow.counterclockwise"
        case .next:
            return "forward.fill"
        case .previous:
            return "backward.fill"
        }
    }
}

/// Indicator showing OSC server status
struct OSCStatusIndicator: View {
    let isRunning: Bool
    let port: UInt16
    
    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(isRunning ? Color.green : Color.red)
                .frame(width: 8, height: 8)
            
            Text("OSC:\(port)")
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundColor(.white.opacity(0.7))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(Color.black.opacity(0.4))
        )
    }
}

#Preview {
    ZStack {
        Color.black
        
        VStack(spacing: 40) {
            OSCFeedbackView(command: .play, isVisible: true)
            OSCFeedbackView(command: .pause, isVisible: true)
            OSCFeedbackView(command: .reset, isVisible: true)
            OSCStatusIndicator(isRunning: true, port: 9000)
        }
    }
}
