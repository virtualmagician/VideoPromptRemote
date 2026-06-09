//
//  ControlButton.swift
//  VideoPromptDesktop
//
//  Created for VideoPromptOSC Control App
//

import SwiftUI

/// A styled control button for OSC commands
struct ControlButton: View {
    let command: OSCCommand
    let isHighlighted: Bool
    let action: () -> Void
    
    @State private var isPressed: Bool = false
    
    var body: some View {
        Button(action: {
            withAnimation(.easeOut(duration: 0.1)) {
                isPressed = true
            }
            action()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.easeOut(duration: 0.1)) {
                    isPressed = false
                }
            }
        }) {
            VStack(spacing: 6) {
                Image(systemName: command.iconName)
                    .font(.system(size: 24, weight: .semibold))
                
                Text(command.displayName)
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                
                Text(command.keyboardShortcut)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.white.opacity(0.5))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .foregroundColor(buttonColor)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(backgroundColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(borderColor, lineWidth: isHighlighted ? 2 : 1)
                    )
            )
            .scaleEffect(isPressed || isHighlighted ? 0.95 : 1.0)
        }
        .buttonStyle(.plain)
    }
    
    private var buttonColor: Color {
        switch command {
        case .play: return .green
        case .pause: return .orange
        case .toggle: return .cyan
        case .reset: return .yellow
        case .next: return .blue
        case .previous: return .purple
        }
    }
    
    private var backgroundColor: Color {
        if isHighlighted {
            return buttonColor.opacity(0.3)
        }
        return buttonColor.opacity(0.15)
    }
    
    private var borderColor: Color {
        if isHighlighted {
            return buttonColor
        }
        return buttonColor.opacity(0.4)
    }
}

#Preview {
    HStack(spacing: 12) {
        ControlButton(command: .play, isHighlighted: false) {}
        ControlButton(command: .pause, isHighlighted: true) {}
    }
    .padding()
    .frame(width: 300, height: 120)
    .background(Color.black)
}
