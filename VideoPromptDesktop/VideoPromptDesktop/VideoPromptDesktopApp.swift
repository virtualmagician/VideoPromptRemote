//
//  VideoPromptDesktopApp.swift
//  VideoPromptDesktop
//
//  Created for VideoPromptOSC Control App
//

import SwiftUI

@main
struct VideoPromptDesktopApp: App {
    @StateObject private var oscService = OSCClientService()
    @StateObject private var iproxyService = IProxyService()
    
    var body: some Scene {
        WindowGroup {
            ContentView(oscService: oscService, iproxyService: iproxyService)
                .frame(width: 280, height: dynamicHeight)
                .background(WindowAccessor { window in
                    configureWindow(window)
                })
                .onAppear {
                    // Start iproxy automatically if installed
                    if iproxyService.isLibimobiledeviceInstalled {
                        iproxyService.start()
                    }
                }
                .onDisappear {
                    // Stop iproxy when app closes
                    iproxyService.stop()
                }
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .commands {
            // Add keyboard shortcuts to menu
            CommandGroup(replacing: .newItem) { }
            
            CommandMenu("Controls") {
                Button("Play") {
                    oscService.send(.play)
                }
                .keyboardShortcut(.return, modifiers: [])
                .disabled(!iproxyService.isLibimobiledeviceInstalled)
                
                Button("Pause") {
                    oscService.send(.pause)
                }
                .keyboardShortcut(.escape, modifiers: [])
                .disabled(!iproxyService.isLibimobiledeviceInstalled)
                
                Button("Toggle Play/Pause") {
                    oscService.send(.toggle)
                }
                .keyboardShortcut(.space, modifiers: [])
                .disabled(!iproxyService.isLibimobiledeviceInstalled)
                
                Button("Reset") {
                    oscService.send(.reset)
                }
                .keyboardShortcut("r", modifiers: [])
                .disabled(!iproxyService.isLibimobiledeviceInstalled)
                
                Divider()
                
                Button("Previous") {
                    oscService.send(.previous)
                }
                .keyboardShortcut(.leftArrow, modifiers: [])
                .disabled(!iproxyService.isLibimobiledeviceInstalled)
                
                Button("Next") {
                    oscService.send(.next)
                }
                .keyboardShortcut(.rightArrow, modifiers: [])
                .disabled(!iproxyService.isLibimobiledeviceInstalled)
                
                Divider()
                
                Button("Restart iproxy") {
                    iproxyService.restart()
                }
                .keyboardShortcut("r", modifiers: .command)
                .disabled(!iproxyService.isLibimobiledeviceInstalled)
                
                Divider()
                
                Button("Settings...") {
                    oscService.showSettings = true
                }
                .keyboardShortcut(",", modifiers: .command)
            }
        }
    }
    
    /// Dynamic height based on whether installation is required
    private var dynamicHeight: CGFloat {
        iproxyService.isLibimobiledeviceInstalled ? 360 : 340
    }
    
    private func configureWindow(_ window: NSWindow?) {
        guard let window = window else { return }
        
        // Always on top
        window.level = .floating
        
        // Window appearance
        window.titlebarAppearsTransparent = true
        window.isMovableByWindowBackground = true
        window.backgroundColor = .windowBackgroundColor
        
        // Window size constraints
        let height = iproxyService.isLibimobiledeviceInstalled ? 360.0 : 340.0
        window.minSize = NSSize(width: 280, height: height)
        window.maxSize = NSSize(width: 280, height: height)
        
        // Center window on first launch
        if window.frame.origin == .zero {
            window.center()
        }
    }
}

// MARK: - Window Accessor Helper

struct WindowAccessor: NSViewRepresentable {
    let callback: (NSWindow?) -> Void
    
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            self.callback(view.window)
        }
        return view
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async {
            self.callback(nsView.window)
        }
    }
}

// MARK: - App Delegate for cleanup

class AppDelegate: NSObject, NSApplicationDelegate {
    var iproxyService: IProxyService?
    
    func applicationWillTerminate(_ notification: Notification) {
        iproxyService?.stop()
    }
}

#Preview {
    ContentView(oscService: OSCClientService(), iproxyService: IProxyService())
        .frame(width: 280, height: 300)
}
