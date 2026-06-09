# VideoPromptOSC

A full-screen video player iOS app designed for controlled playlist playback via touch gestures, external keyboard, Bluetooth remote, or OSC (Open Sound Control) messages — with a companion macOS control app.

## Overview

VideoPromptOSC is a minimalist video player for iPhone and iPad that allows users to manage a playlist of videos and control playback through simple gestures, an external keyboard, a Bluetooth remote, or OSC messages from a computer. The app is designed for presentation and teleprompter-style use cases where clean, distraction-free video playback is essential.

This repository contains two apps:
- **VideoPromptOSC** (iOS) — The video player app with playlist support
- **VideoPromptDesktop** (macOS) — A companion control surface for sending OSC commands via WiFi

## Features

### iOS App (VideoPromptOSC)
- **Full-screen video playback** in landscape orientation
- **Multi-video playlist** with drag-to-reorder support
- **Add videos via**:
  - Media library (PHPicker)
  - AirDrop from Mac or other devices
- **Touch gesture controls**:
  - Single tap: Play/Pause toggle
  - Double tap: Reset to playlist start
  - Right swipe: Play current video, then advance to next
  - Left swipe: Load previous video
- **External keyboard support** with customizable key bindings:
  - Default: Space (toggle), Arrow keys (next/previous)
  - Press-to-assign configuration in settings
  - Persistent bindings across sessions
- **Bluetooth remote support** — single press toggles play/pause, double press resets
- **OSC control support** — Play, Pause, Toggle, Reset, Next, Previous commands via UDP
- **Visual feedback** — on-screen indicator when OSC/remote/keyboard commands are received
- **Playlist position indicator** — shows current video number (e.g., "2 / 5")
- **OSC status indicator** — shows connection status and port number
- **Minimal UI** — persistent time display and settings gear in top-right corner
- **Respects silent/ringer switch** — audio follows device silent mode
- **Universal app** — works on both iPhone and iPad

### macOS App (VideoPromptDesktop)
- **Six control buttons** — Play, Pause, Toggle, Reset, Previous, Next
- **Keyboard shortcuts** — including arrow keys for playlist navigation
- **WiFi-based OSC** — sends commands directly to iPhone's IP address
- **Always-on-top window** — stays visible while working in other apps
- **Connection status** — shows configured host and port

## Requirements

### iOS App
- iOS 18.0 or later (deployment target; external keyboard support requires `.onKeyPress`, iOS 17+)
- iPhone or iPad device
- Xcode 15.0 or later (for building)

### macOS App
- macOS 13.0 (Ventura) or later
- Xcode 15.0 or later (for building)

## Project Structure

```
VideoPromptRemote/
├── VideoPromptRemote.xcodeproj/        # iOS app Xcode project
├── VideoPrompt/                        # iOS app source
│   ├── VideoPromptApp.swift            # App entry point, audio session, OSC & AirDrop init
│   ├── ContentView.swift               # Main view with gesture & keyboard handling
│   ├── Info.plist                      # App configuration, permissions & document types
│   ├── Models/
│   │   ├── PlaylistItem.swift          # Playlist item data model
│   │   └── KeyBinding.swift            # Keyboard binding data model
│   ├── Views/
│   │   ├── VideoPlayerView.swift       # AVPlayer wrapper (UIViewRepresentable)
│   │   ├── VideoPickerView.swift       # PHPicker for video selection
│   │   ├── PlayerOverlayView.swift     # Top-right HUD (time + gear icon)
│   │   ├── TimeDisplayView.swift       # Time display component (MM:SS / MM:SS)
│   │   ├── OSCFeedbackView.swift       # OSC command feedback & status indicator
│   │   ├── PlaylistEditorView.swift    # Playlist management with drag-to-reorder
│   │   └── KeyboardSettingsView.swift  # Keyboard binding configuration UI
│   ├── ViewModels/
│   │   └── VideoPlayerViewModel.swift  # Playback state, playlist navigation & business logic
│   ├── Services/
│   │   ├── VideoStorageService.swift   # Video persistence to Documents folder
│   │   ├── OSCService.swift            # OSC server for receiving commands
│   │   ├── VolumeButtonService.swift   # Bluetooth remote volume button detection
│   │   ├── PlaylistService.swift       # Playlist state management & persistence
│   │   └── KeyboardService.swift       # External keyboard event handling
│   ├── Utilities/
│   │   └── TimeFormatter.swift         # Time formatting helper
│   └── Assets.xcassets/
│       ├── AppIcon.appiconset/         # App icon (blue with white "VP")
│       └── AccentColor.colorset/       # Accent color
│
└── VideoPromptDesktop/                 # macOS companion app
    ├── VideoPromptDesktop.xcodeproj/   # macOS app Xcode project
    └── VideoPromptDesktop/             # macOS app source
        ├── VideoPromptDesktopApp.swift # App entry, window config, keyboard shortcuts
        ├── ContentView.swift           # Main UI with button grid & status
        ├── Views/
        │   └── ControlButton.swift     # Styled button component
        └── Services/
            ├── OSCClientService.swift  # OSC UDP client for sending commands
            └── IProxyService.swift     # iproxy process management (optional)
```

## Building the Apps

### iOS App (VideoPromptOSC)

#### Using Xcode (Recommended)

1. Open `VideoPromptRemote.xcodeproj` in Xcode
2. Wait for Swift Package Manager to fetch the OSCKit dependency
3. Select your development team in Signing & Capabilities
4. Connect your iOS device
5. Select your device as the build target
6. Press `Cmd + R` to build and run

#### Using Command Line

```bash
# Navigate to project directory
cd /path/to/VideoPromptRemote

# Build for device (requires signing configuration)
xcodebuild -project VideoPromptRemote.xcodeproj \
  -scheme VideoPromptOSC \
  -sdk iphoneos \
  -configuration Release \
  build

# List available schemes
xcodebuild -list -project VideoPromptRemote.xcodeproj
```

### macOS App (VideoPromptDesktop)

1. Open `VideoPromptDesktop/VideoPromptDesktop.xcodeproj` in Xcode
2. Wait for Swift Package Manager to fetch OSCKit
3. Select your development team in Signing & Capabilities
4. Build and run (`Cmd + R`)

See [VideoPromptDesktop/README.md](VideoPromptDesktop/README.md) for detailed instructions.

## Usage

### First Launch
1. Open the app
2. Tap the gear icon (⚙️) in the top-right corner
3. Tap the **+** button to add videos from your photo library
4. Optionally, AirDrop videos from your Mac
5. Reorder videos by dragging them up/down in the list
6. Tap **Done** to start playback

### Playback Controls

| Action | Result |
|--------|--------|
| **Single tap** on screen | Play/Pause toggle |
| **Double tap** on screen | Reset to playlist start (first video, beginning) |
| **Right swipe** | Play current video; if finished, advance to next |
| **Left swipe** | Load previous video |
| **Camera remote shutter** | Play/Pause toggle |
| **Bluetooth remote (Volume Up)** | Play/Pause toggle |
| **Bluetooth remote (Volume Up x2)** | Reset to playlist start |
| **Gear icon tap** | Open playlist editor & settings |

### External Keyboard Controls

Connect an external keyboard (Bluetooth or USB) for hands-free control:

| Default Key | Action |
|-------------|--------|
| **Space** | Toggle Play/Pause |
| **→ (Right Arrow)** | Next video |
| **← (Left Arrow)** | Previous video |

#### Customizing Key Bindings

1. Tap the gear icon (⚙️)
2. Tap **Keyboard Controls**
3. Tap any action row or the **Set** button
4. Press the desired key on your keyboard
5. The binding is saved automatically

Available actions to bind:
- Toggle Play/Pause
- Play
- Pause
- Next Video
- Previous Video
- Reset Playlist

### Bluetooth Remote Support

The app supports Bluetooth remotes that simulate volume button presses:

- **Single press** of Volume Up → Toggle Play/Pause
- **Double press** of Volume Up (within 0.4 seconds) → Reset to beginning

This works with most Bluetooth camera shutter remotes and presentation clickers that send volume key events.

### Time Display
The top-right corner shows:
- Current playback position
- Total video duration
- Format: `MM:SS / MM:SS` (or `H:MM:SS` for videos over 1 hour)

### OSC Status
The bottom-left corner shows:
- Green dot: OSC server running
- Red dot: OSC server not running
- Port number (default: 9000)

## OSC Control

VideoPromptOSC includes a built-in OSC server that listens for control messages over UDP.

### OSC Configuration

| Setting | Value |
|---------|-------|
| Protocol | UDP |
| Port | 9000 |

### OSC Commands

| OSC Address | Action |
|-------------|--------|
| `/videoprompt/play` | Start playback |
| `/videoprompt/pause` | Pause playback |
| `/videoprompt/toggle` | Toggle play/pause |
| `/videoprompt/reset` | Reset to playlist start |
| `/videoprompt/next` | Load and play next video |
| `/videoprompt/previous` | Load previous video |

### WiFi Connection Setup

To control the app via WiFi from a Mac:

1. **Ensure both devices are on the same WiFi network**

2. **Find your iPhone's IP address**:
   - On iPhone: Settings → WiFi → tap the connected network → IP Address

3. **Configure VideoPromptDesktop** (or your OSC app):
   - Click the gear icon (⚙️)
   - Enter the iPhone's IP address in the Host field
   - Port: `9000`

4. **Send OSC commands** using the control buttons or keyboard shortcuts

### Example: Sending OSC from Terminal

Using `oscsend` (install via `brew install liblo`):

```bash
# Play
oscsend localhost 9000 /videoprompt/play

# Pause
oscsend localhost 9000 /videoprompt/pause

# Toggle play/pause
oscsend localhost 9000 /videoprompt/toggle

# Reset to beginning
oscsend localhost 9000 /videoprompt/reset
```

### Visual Feedback

When an OSC command is received:
- A colored overlay briefly appears in the center of the screen
- The command name is displayed (PLAY, PAUSE, TOGGLE, RESET)
- Each command type has a distinct color for easy identification

## Technical Details

### Key Components

#### VideoPlayerView
- Uses `AVPlayerLayer` as the view's layer class for optimal performance
- Implements `UIViewRepresentable` for SwiftUI integration
- Includes identity checking to prevent unnecessary layer recreation

#### VideoPlayerViewModel
- `@MainActor` annotated for thread safety
- Manages `AVPlayer` instance and playback state
- Handles time observation (updates every 0.5 seconds)
- Playlist-aware navigation (next, previous, reset)
- Implements `OSCCommandHandler` and `KeyboardCommandHandler` protocols

#### PlaylistService
- Manages ordered list of `PlaylistItem` objects
- Handles video file copying to Documents directory
- Persists playlist order in `UserDefaults` as JSON
- Supports add, remove, move (reorder) operations
- Migrates single-video users to playlist format

#### KeyboardService
- Captures external keyboard events via SwiftUI `.onKeyPress`
- Maps keys to actions with customizable bindings
- Stores bindings in `UserDefaults` as JSON
- Supports press-to-assign configuration
- Default bindings: Space, Arrow keys

#### OSCService
- Uses OSCKit library for OSC message parsing
- Runs UDP server on configurable port (default: 9000)
- Supports play, pause, toggle, reset, next, previous commands
- Manages visual feedback state for UI updates

#### VolumeButtonService
- Detects volume button presses from Bluetooth remotes
- Observes `AVAudioSession.outputVolume` changes to detect button presses
- Implements double-press detection with configurable interval (0.4s)
- Uses hidden `MPVolumeView` to suppress system volume HUD
- Resets volume after each press to prevent maxing out

### Dependencies

- **OSCKit** (Swift Package Manager) - https://github.com/orchetect/OSCKit
  - Used for OSC message parsing and UDP server

### Audio Configuration
```swift
AVAudioSession.sharedInstance().setCategory(.ambient, mode: .moviePlayback)
```
Using `.ambient` category ensures the app respects the device's silent/ringer switch.

### Orientation Lock
The app is locked to landscape orientation via `Info.plist`:
- `UIInterfaceOrientationLandscapeLeft`
- `UIInterfaceOrientationLandscapeRight`

## Permissions

The app requires the following permissions (configured in `Info.plist`):

- **Photo Library Access** (`NSPhotoLibraryUsageDescription`): Required to select videos from the user's media library
- **Local Network Access** (`NSLocalNetworkUsageDescription`): Required for receiving OSC messages over the network

## App Icon

The app icon features:
- Blue background (#007AFF - Apple system blue)
- White "VP" text in Helvetica Bold
- 1024x1024 resolution

To regenerate the icon:
```bash
cd VideoPrompt/Assets.xcassets/AppIcon.appiconset
magick -size 1024x1024 xc:'#007AFF' \
  -gravity center \
  -font "Helvetica-Bold" \
  -pointsize 420 \
  -fill white \
  -annotate 0 "VP" \
  AppIcon.png
```

## Troubleshooting

### Video stuttering or flickering
- Ensure `VideoPlayerView` uses `layerClass` override (not manual layer management)
- Check that player identity comparison uses `!==` to prevent unnecessary updates

### Bluetooth remote not working
- Ensure your Bluetooth remote sends Volume Up key events
- Try pressing the button once to verify the app detects volume changes
- Check that the app is in the foreground
- Some remotes may need to be re-paired with the device

### Video not persisting between launches
- Check that the app has write access to Documents directory
- Verify `UserDefaults` is saving the file path correctly

### OSC not receiving messages
- Check that the OSC status indicator shows a green dot (server running)
- Confirm both devices are on the same WiFi network
- Confirm the Mac OSC app is sending to the iPhone's WiFi IP address on port `9000`
- Approve the iOS "Local Network" permission prompt on first launch
- Check that no firewall is blocking UDP traffic on port 9000

### OSC feedback not showing
- Commands are being received but feedback may be too fast to see
- Check console output for "Received OSC command:" messages

## macOS Companion App

**VideoPromptDesktop** is a native macOS app for controlling VideoPromptOSC via WiFi. It provides:

- Six control buttons: Play, Pause, Toggle, Reset, Previous, Next
- Keyboard shortcuts including arrow keys for playlist navigation
- WiFi-based OSC communication (enter iPhone's IP address)
- Always-on-top floating window
- Configurable host/port settings

See [VideoPromptDesktop/README.md](VideoPromptDesktop/README.md) for full documentation.

### Quick Start with Desktop App

1. Ensure Mac and iPhone are on the same WiFi network
2. Launch VideoPromptOSC on iOS
3. Launch VideoPromptDesktop on Mac
4. Enter iPhone's IP address in Settings (gear icon)
5. Use buttons or keyboard shortcuts to control playback

| Button | Keyboard Shortcut |
|--------|-------------------|
| Play | Enter (↵) |
| Pause | Escape (⎋) |
| Toggle | Space (␣) |
| Reset | R |
| Previous | ← (Left Arrow) |
| Next | → (Right Arrow) |

## Version History

- **3.0** - Playlist & Keyboard Control
  - Multi-video playlist support with drag-to-reorder
  - AirDrop support for adding videos from Mac
  - Swipe gestures for playlist navigation (right = next, left = previous)
  - External keyboard support with customizable key bindings
  - Press-to-assign keyboard configuration UI
  - New OSC commands: `/videoprompt/next`, `/videoprompt/previous`
  - Desktop app: Added Previous/Next buttons with arrow key shortcuts
  - Desktop app: WiFi-based OSC (direct IP connection, no USB tunneling)
  - Playlist position indicator in UI

- **2.1** - Bluetooth Remote Improvements
  - New `VolumeButtonService` for reliable Bluetooth remote detection
  - Volume button observation replaces remote control events
  - Hidden `MPVolumeView` suppresses system volume HUD
  - Automatic volume reset prevents maxing out

- **2.0** - OSC Control Update
  - Added OSC server for remote control via USB
  - OSC commands: play, pause, toggle, reset
  - Visual feedback for received OSC commands
  - OSC status indicator in UI
  - Renamed app to VideoPromptOSC
  - Added OSCKit dependency via SPM
  - Added VideoPromptDesktop macOS companion app

- **1.0** - Initial release
  - Full-screen video playback
  - Touch gesture controls
  - Camera remote support
  - Persistent video selection
  - Time display overlay

## For Developers & Contributors

If you're picking up development on this project, start with [`HANDOVER.md`](HANDOVER.md).
It documents the architecture, control-input fan-in, persistence model, known issues
(including the desktop app's legacy `libimobiledevice` gate), and suggested next steps.

## License

Proprietary - All rights reserved.

Copyright © 2026 Marco Tempest / Newmagic. This software is provided for the
WEF 2026 production and is not licensed for redistribution. Third-party
dependencies (OSCKit, CocoaAsyncSocket, SwiftASCII) retain their own MIT licenses.
