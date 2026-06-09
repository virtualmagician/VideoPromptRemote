//
//  KeyboardSettingsView.swift
//  VideoPromptOSC
//
//  Created for VideoPromptOSC App
//

import SwiftUI

struct KeyboardSettingsView: View {
    @ObservedObject var keyboardService: KeyboardService
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isKeyboardFocused: Bool
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    ForEach(KeyboardAction.allCases) { action in
                        KeyBindingRow(
                            action: action,
                            binding: keyboardService.binding(for: action),
                            isCapturing: keyboardService.capturingAction == action,
                            onSetTapped: {
                                keyboardService.startCapturing(for: action)
                                isKeyboardFocused = true
                            },
                            onClearTapped: {
                                keyboardService.clearBinding(for: action)
                            }
                        )
                    }
                } header: {
                    Text("Keyboard Shortcuts")
                } footer: {
                    Text("Tap 'Set' and then press the key you want to assign. Connect an external keyboard to use these shortcuts.")
                }
                
                Section {
                    Button("Reset to Defaults") {
                        keyboardService.resetToDefaults()
                    }
                    .foregroundColor(.orange)
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Keyboard Controls")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        keyboardService.cancelCapturing()
                        dismiss()
                    }
                }
            }
            .focusable()
            .focused($isKeyboardFocused)
            .onKeyPress { keyPress in
                if keyboardService.isCapturing, let action = keyboardService.capturingAction {
                    keyboardService.setBinding(keyPress: keyPress, for: action)
                    return .handled
                }
                return .ignored
            }
        }
        .onDisappear {
            keyboardService.cancelCapturing()
        }
    }
}

// MARK: - Key Binding Row

struct KeyBindingRow: View {
    let action: KeyboardAction
    let binding: KeyBinding?
    let isCapturing: Bool
    let onSetTapped: () -> Void
    let onClearTapped: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Action icon and name
            Image(systemName: action.iconName)
                .font(.system(size: 18))
                .foregroundColor(.accentColor)
                .frame(width: 28)
            
            Text(action.displayName)
                .font(.system(size: 15))
            
            Spacer()
            
            // Current key binding or capture indicator
            if isCapturing {
                Text("Press a key...")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.orange)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.orange.opacity(0.15))
                    )
            } else if let binding = binding, binding.isSet {
                HStack(spacing: 8) {
                    Text(binding.displayKey)
                        .font(.system(size: 14, weight: .semibold, design: .monospaced))
                        .foregroundColor(.primary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.secondary.opacity(0.15))
                        )
                    
                    Button {
                        onClearTapped()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 18))
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            } else {
                Button {
                    onSetTapped()
                } label: {
                    Text("Set")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.accentColor)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color.accentColor, lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
            }
            
            // Set button (shown when key is already set)
            if !isCapturing && binding?.isSet == true {
                Button {
                    onSetTapped()
                } label: {
                    Text("Change")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture {
            if !isCapturing {
                onSetTapped()
            }
        }
    }
}

#Preview {
    KeyboardSettingsView(keyboardService: KeyboardService())
}
