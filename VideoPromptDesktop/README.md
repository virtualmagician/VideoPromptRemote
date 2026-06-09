# VideoPromptDesktop

A native macOS companion app for controlling VideoPromptOSC on iOS via OSC messages over WiFi.

## Overview

VideoPromptDesktop is a compact control surface that sends OSC (Open Sound Control) commands to the VideoPromptOSC iOS app over your local WiFi network. Simply enter your iPhone's IP address and start controlling playback.

## Features

- **Six control buttons**: Play, Pause, Toggle, Reset, Previous, Next
- **Keyboard shortcuts**: Including arrow keys for playlist navigation
- **WiFi-based connection**: Direct OSC over local network
- **Always-on-top window**: Stays visible while working in other apps
- **Visual feedback**: Buttons flash when commands are sent
- **Connection status**: Shows configured host and port
- **Configurable connection**: Adjustable host and port settings
- **Persistent settings**: Remembers your configuration

## Requirements

- macOS 13.0 (Ventura) or later
- Xcode 15.0 or later (for building)
- Same WiFi network as iOS device

## Installation

### Building from Source

1. Open `VideoPromptDesktop.xcodeproj` in Xcode
2. Wait for Swift Package Manager to fetch OSCKit
3. Select your development team in Signing & Capabilities
4. Build and run (Cmd+R)

## Usage

### Quick Start

1. Ensure your Mac and iPhone are on the same WiFi network
2. Launch VideoPromptOSC on the iOS device
3. Find your iPhone's IP address:
   - On iPhone: Settings → WiFi → tap the connected network → IP Address
4. Launch VideoPromptDesktop on your Mac
5. Click the gear icon (⚙) and enter the iPhone's IP address
6. Use the buttons or keyboard shortcuts to control playback

### Controls

| Button | OSC Command | Keyboard Shortcut |
|--------|-------------|-------------------|
| PLAY | `/videoprompt/play` | Enter (↵) |
| PAUSE | `/videoprompt/pause` | Escape (⎋) |
| TOGGLE | `/videoprompt/toggle` | Space (␣) |
| RESET | `/videoprompt/reset` | R |
| PREV | `/videoprompt/previous` | ← (Left Arrow) |
| NEXT | `/videoprompt/next` | → (Right Arrow) |

### Status Bar

The bottom of the window shows:
- **Host:Port** — The configured destination (e.g., `192.168.1.50:9,000`)
- **Hint** — Click gear to configure the iPhone's IP address

### Settings

Click the gear icon (⚙) to configure:
- **Host**: iPhone's IP address on local WiFi (e.g., `192.168.1.50`)
- **Port**: Target UDP port (default: 9000)

Settings are automatically saved and restored on launch.

### Window Behavior

- The window floats above other windows (always-on-top)
- Fixed compact size for minimal screen footprint
- Can be moved by dragging anywhere on the window

## How It Works

1. **Configure**: Enter your iPhone's WiFi IP address in Settings
2. **When you click a button**: Sends an OSC UDP message to the configured IP:port
3. **Over WiFi**: The message travels directly to the iOS device
4. **VideoPromptOSC receives**: The iOS app receives and executes the command

## Technical Details

### Dependencies

- **OSCKit** (Swift Package Manager) - https://github.com/orchetect/OSCKit

### Architecture

| File | Purpose |
|------|---------|
| `VideoPromptDesktopApp.swift` | App entry, window configuration, keyboard shortcuts |
| `ContentView.swift` | Main UI with button grid, status, and settings |
| `OSCClientService.swift` | OSC UDP client, command definitions, and settings management |
| `IProxyService.swift` | Optional iproxy process management (legacy USB support) |
| `ControlButton.swift` | Styled button component |

### OSC Commands

| Command | OSC Address |
|---------|-------------|
| Play | `/videoprompt/play` |
| Pause | `/videoprompt/pause` |
| Toggle | `/videoprompt/toggle` |
| Reset | `/videoprompt/reset` |
| Previous | `/videoprompt/previous` |
| Next | `/videoprompt/next` |

### Default Configuration

- Host: iPhone's IP address (e.g., `192.168.1.50`)
- Port: `9000`

## Troubleshooting

### Commands not reaching iOS app

1. Ensure VideoPromptOSC is running on the iOS device
2. Verify both devices are on the same WiFi network
3. Check the iPhone's IP address is entered correctly in Settings
4. Verify both apps are using port 9000
5. Check if any firewall is blocking UDP traffic

### Finding iPhone's IP Address

On iPhone:
1. Open **Settings**
2. Tap **WiFi**
3. Tap the **(i)** icon next to your connected network
4. Look for **IP Address** (e.g., `192.168.1.50`)

### Window not staying on top

The window is configured to float by default. If it's not working:
- Try restarting the app
- Check System Preferences > Desktop & Dock for window management settings

### Keyboard shortcuts not working

- Ensure the app window is focused
- Check the Controls menu for available shortcuts
- Some shortcuts may conflict with system shortcuts

### iPhone IP address changes

If your iPhone gets a new IP address (e.g., after reconnecting to WiFi):
1. Find the new IP address on iPhone (Settings → WiFi → network info)
2. Update the Host in VideoPromptDesktop Settings

## Version History

- **2.0** - WiFi & Playlist Support
  - Added Previous/Next buttons for playlist navigation
  - Arrow key shortcuts (← and →) for Previous/Next
  - WiFi-based OSC connection (removed USB/iproxy dependency)
  - Updated UI to show configured host/port
  - Settings now prompt for iPhone IP address

- **1.1** - Automatic iproxy management
  - Automatic iproxy start/stop with app lifecycle
  - One-click libimobiledevice installation
  - Connection status monitoring
  - Installation detection and prompts

- **1.0** - Initial release
  - Four control buttons (Play, Pause, Toggle, Reset)
  - Keyboard shortcuts
  - Always-on-top window
  - Configurable host/port settings
  - Visual feedback on button press

## License

Released under the MIT License — free to use, modify, and distribute with no
restrictions. See the [LICENSE](../LICENSE) file at the repository root.

Copyright © 2026 Marco Tempest - MagicLab.
