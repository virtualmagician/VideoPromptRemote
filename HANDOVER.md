# Handover — VideoPrompt Remote

> **Audience:** the next developer or AI agent picking up this project.
> **Goal of this doc:** give you everything you need to be productive in ~10 minutes,
> without re-reading the whole codebase. Read this before making changes.

Last updated: 2026-08-29

---

## 1. What this project is

Two native Apple apps that together form a presentation/teleprompter video system
built for the **WEF 2026 production**:

| App | Platform | Role |
|-----|----------|------|
| **VideoPromptOSC** | iOS 18+ | Full-screen, distraction-free video **player** with a playlist. Listens for control input. |
| **VideoPromptDesktop** | macOS 13+ | Floating **remote** that sends control commands. |

They communicate over **OSC (Open Sound Control) via UDP on port 9000** across the
local WiFi network. There is **no web stack, no backend, no server** — it's pure
Swift/SwiftUI + AVFoundation + OSCKit.

If you want the user-facing description, read [`README.md`](README.md). This file is
the *engineering* handover.

---

## 2. Repository layout

```
VideoPrompt Remote/                     # workspace root
├── README.md                           # user-facing docs
├── HANDOVER.md                         # ← you are here
├── .gitignore                          # ignores DerivedData/, build/, SPM caches, .DS_Store
├── VideoPromptRemote.xcodeproj/        # iOS Xcode project (scheme: VideoPromptOSC)
├── VideoPrompt/                        # iOS app SOURCE (see file map below)
├── VideoPromptTests/                   # iOS unit tests (minimal)
├── VideoPromptDesktop/                 # macOS companion
│   ├── README.md
│   ├── VideoPromptDesktop.xcodeproj/
│   └── VideoPromptDesktop/             # macOS app SOURCE
├── DerivedData/                        # build artifacts — DO NOT COMMIT (gitignored)
└── build/                              # build output — DO NOT COMMIT (gitignored)
```

### iOS source file map (`VideoPrompt/`)

| File | Responsibility |
|------|----------------|
| `VideoPromptApp.swift` | `@main`. Creates shared services, configures audio session (`.ambient`), disables idle timer, starts OSC server, handles incoming/AirDrop video URLs via `.onOpenURL`. |
| `ContentView.swift` | Main UI shell. **Wires every service to the view model** in `.onAppear`. Owns touch gestures and SwiftUI `.onKeyPress` keyboard handling. |
| `ViewModels/VideoPlayerViewModel.swift` | **The brain.** `@MainActor`. Owns `AVPlayer` lifecycle, playback state, playlist navigation. Implements `OSCCommandHandler`, `KeyboardCommandHandler`, `VolumeButtonHandler`. |
| `Services/PlaylistService.swift` | Playlist CRUD + persistence. Copies videos into Documents, stores items + current index as JSON in `UserDefaults`. Migrates v1 single-video storage. |
| `Services/OSCService.swift` | UDP OSC **server** (receiver) using OSCKit. Parses `/videoprompt/*` and forwards to the command handler. Holds visual-feedback state. |
| `Services/KeyboardService.swift` | Key-binding model + persistence; press-to-assign. |
| `Services/VolumeButtonService.swift` | Bluetooth remote detection via `AVAudioSession.outputVolume` changes; hidden `MPVolumeView` suppresses the system HUD; double-press detection (0.4s). |
| `Services/VideoStorageService.swift` | **LEGACY (v1).** Single-video storage, superseded by `PlaylistService`. Still referenced by tests. See Known Issues. |
| `Views/VideoPlayerView.swift` | `UIViewRepresentable` wrapping `AVPlayerLayer`. Also contains a legacy UIKit remote-control VC. |
| `Views/PlaylistEditorView.swift` | Playlist management UI, PHPicker, keyboard settings entry. |
| `Views/*` | HUD, time display, OSC feedback overlay, picker, keyboard settings. |
| `Models/PlaylistItem.swift`, `Models/KeyBinding.swift` | Codable data models. |
| `Utilities/TimeFormatter.swift` | `MM:SS` / `H:MM:SS` formatting. |

### macOS source file map (`VideoPromptDesktop/VideoPromptDesktop/`)

| File | Responsibility |
|------|----------------|
| `VideoPromptDesktopApp.swift` | `@main`. Fixed-size always-on-top window. Menu-bar keyboard shortcuts for all 6 commands. Auto-starts `iproxy` if installed (legacy). |
| `ContentView.swift` | Button grid + status + settings. **Currently gates the button grid on `iproxyService.isLibimobiledeviceInstalled`** (see Known Issues). |
| `Services/OSCClientService.swift` | OSC UDP **client** (sender). Command definitions + host/port settings in `UserDefaults`. |
| `Services/IProxyService.swift` | Legacy USB tunnel via `iproxy`/`libimobiledevice`. |
| `Views/ControlButton.swift` | Styled button component. |

---

## 3. Architecture & control flow

### The key idea: one brain, many inputs

Every control path converges on **`VideoPlayerViewModel`**. To add a new control
source, implement the relevant handler protocol (or call the VM directly) and wire it
in `ContentView.onAppear`.

```
OSC (WiFi)  ─┐
Keyboard    ─┤
BT remote   ─┼──▶  VideoPlayerViewModel  ──▶  AVPlayer  ──▶  VideoPlayerView (AVPlayerLayer)
Touch/swipe ─┤            │
Playlist UI ─┘            └──▶  PlaylistService  ──▶  UserDefaults (JSON) + Documents/
```

### Wiring happens in one place — `ContentView.onAppear`:
```swift
viewModel.setPlaylistService(playlistService)
oscService.setCommandHandler(viewModel)
volumeButtonService.setHandler(viewModel)
keyboardService.setCommandHandler(viewModel)
```

### OSC protocol (UDP :9000)

| Address | Action |
|---------|--------|
| `/videoprompt/play` | Start playback |
| `/videoprompt/pause` | Pause |
| `/videoprompt/toggle` | Toggle play/pause |
| `/videoprompt/reset` | Reset to first video, time 0 |
| `/videoprompt/next` | Next video (auto-plays) |
| `/videoprompt/previous` | Previous video |

Quick manual test from any Mac (no desktop app needed):
```bash
brew install liblo
oscsend <iphone-wifi-ip> 9000 /videoprompt/toggle
```

### Persistence model

- **Playlist items + current index** → `UserDefaults` keys `playlistItems`, `playlistCurrentIndex` (JSON).
- **Video files** → copied into the app's `Documents/` directory.
- **Keyboard bindings** → `UserDefaults` (JSON).
- **Desktop host/port** → `UserDefaults`.
- v1→v2 migration: `PlaylistService` upgrades the old `savedVideoFileName` key.

---

## 4. Build & run

### iOS (VideoPromptOSC)
1. Open `VideoPromptRemote.xcodeproj`.
2. Let SPM fetch **OSCKit** (0.6.2) and its deps (CocoaAsyncSocket, SwiftASCII).
3. Set your signing team under Signing & Capabilities.
4. Select a real device (camera/Bluetooth/OSC features need hardware), `Cmd+R`.

CLI build:
```bash
xcodebuild -project VideoPromptRemote.xcodeproj -scheme VideoPromptOSC \
  -sdk iphoneos -configuration Release build
```

### macOS (VideoPromptDesktop)
1. Open `VideoPromptDesktop/VideoPromptDesktop.xcodeproj`, `Cmd+R`.
2. Open Settings (gear) and enter the iPhone's WiFi IP. Port `9000`.

### Deploy to a physical device from the command line (verified working)

This is how the app has actually been deployed to devices (iPad Pro M5 and iPhone 17 Pro).
`devicectl` is the modern replacement for `ios-deploy`.

```bash
# 1. Find the device UDID
xcrun devicectl list devices

# 2. Build for that device (Debug), into a LOCAL DerivedData path inside the repo
xcodebuild -project VideoPromptRemote.xcodeproj -scheme VideoPromptOSC \
  -configuration Debug -destination 'id=<DEVICE_UDID>' \
  -derivedDataPath build/DerivedData -allowProvisioningUpdates build

# 3. Install + launch
APP=build/DerivedData/Build/Products/Debug-iphoneos/VideoPromptOSC.app
xcrun devicectl device install app --device <DEVICE_UDID> "$APP"
xcrun devicectl device process launch --device <DEVICE_UDID> com.videoprompt.osc
```

**Deployment gotchas (learned the hard way):**
- **Active developer dir may be Command Line Tools, not Xcode.** If `xcrun devicectl`
  reports "unable to find utility devicectl", the active dir is
  `/Library/Developer/CommandLineTools`. Either run `sudo xcode-select -s
  /Applications/Xcode.app/Contents/Developer`, or prefix commands with
  `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer` (and call `devicectl` by
  full path: `/Applications/Xcode.app/Contents/Developer/usr/bin/devicectl`).
- **The repo lives in Dropbox/CloudStorage reachable via a symlink**
  (`~/Newmagic Dropbox/...` → `~/Library/CloudStorage/Dropbox-Newmagic/...`). Building
  through the symlink path while stale DerivedData exists from the *real* path causes
  **`CodeSign` failures** with "Stale file … located outside of the allowed root paths"
  warnings. Fix: `rm -rf build/DerivedData` and rebuild from the **canonical
  CloudStorage path**. Prefer always building from the canonical path.
- Signing is **Automatic**, team `Z3U3NKMU2Y`. `-allowProvisioningUpdates` lets
  xcodebuild create/refresh the "iOS Team Provisioning Profile" automatically.
- Simulator services can fail under sandboxing; device work needs full system access.

### Key project facts (verified)
- iOS deployment target: **18.0** (`IPHONEOS_DEPLOYMENT_TARGET`).
- macOS deployment target: **13.0**.
- Bundle IDs: `com.videoprompt.osc` (iOS), `com.videoprompt.desktop` (macOS).
- Signing: Automatic, DEVELOPMENT_TEAM `Z3U3NKMU2Y`.
- `MARKETING_VERSION = 1.0` in the iOS project (note: README "version history" tracks
  *feature* milestones up to 3.0; the Xcode marketing version has not been bumped to match).

---

## 5. Known issues & gotchas

1. **Desktop app gates its UI on `libimobiledevice` (legacy USB).**
   `VideoPromptDesktop/ContentView.swift` only shows the button grid when
   `iproxyService.isLibimobiledeviceInstalled` is true, even though OSC now works over
   plain WiFi and the README advertises WiFi-only. **Likely the highest-value fix:**
   remove the `isLibimobiledeviceInstalled` gate (and probably retire `IProxyService`
   entirely) so the controls always show. Default host is also `127.0.0.1` (USB tunnel
   address) and should arguably default to empty / prompt for the iPhone IP.

2. **Dead/legacy code still present:**
   - `VideoStorageService.swift` (v1 single-video storage) is superseded by
     `PlaylistService` but is still referenced by `VideoPromptTests`. Removing it means
     updating the tests.
   - `RemoteControlView` (UIKit) inside `VideoPlayerView.swift` is superseded by the
     SwiftUI `.onKeyPress` path in `ContentView`.

3. **Version drift in docs vs project:** README requirements said iOS 17 (now corrected
   to 18); marketing version is still 1.0. Bump `MARKETING_VERSION` before tagging a
   release.

4. **Tests are minimal.** `VideoPromptTests` covers little. No CI is configured.

5. **Hardware-dependent features** (Bluetooth volume-button remote, camera remote, real
   OSC over WiFi) cannot be fully validated in the simulator — test on a device.

---

## 6. Git, GitHub & licensing (current state)

- **Git repo:** initialized. Default branch `main`.
- **Remote:** [`virtualmagician/VideoPromptRemote`](https://github.com/virtualmagician/VideoPromptRemote)
  (`origin`, plain HTTPS URL — no credentials stored in `.git/config`).
- **License:** **MIT** (`LICENSE`), © 2026 Marco Tempest - MagicLab. Fully open source,
  no restrictions. (Was proprietary during initial release prep; relicensed.)
- **`.gitignore`** excludes `build/`, `DerivedData/`, SPM caches, Xcode user state,
  and `.DS_Store`. `Package.resolved` IS tracked (reproducible dependency versions).
- **Cursor co-author suppression:** a local `.git/hooks/commit-msg` hook strips the
  auto-injected `Co-authored-by: Cursor <cursoragent@cursor.com>` trailer so Cursor
  never shows up as a GitHub contributor. **This hook is local only** (hooks aren't
  pushed). If you clone fresh or add collaborators and want it enforced, move it to a
  tracked dir and set `git config core.hooksPath .githooks`. History was already
  rewritten + force-pushed once to remove the trailer from the initial commits.
- **Auth for pushing:** no credential helper is configured. Use `gh auth login` or the
  macOS keychain (`git config --global credential.helper osxkeychain`). Do NOT paste
  personal access tokens into chat/agent prompts.
- **Committer identity note:** early commits were auto-attributed to
  `Marco Tempest <marcotempest@magiclabm5mmbp.home>` (local hostname email). Set a real
  `git config --global user.email` before making more commits.

---

## 7. Suggested next steps (roadmap)

Ordered roughly by value-to-effort for a release:

1. **Remove the desktop `libimobiledevice` gate** and (optionally) delete `IProxyService`
   so WiFi control is the only path. Update `OSCClientService` default host handling.
2. **Bump `MARKETING_VERSION`** on both targets and tag a real release.
3. **Delete legacy code** (`VideoStorageService`, `RemoteControlView`) and fix the tests
   that reference them.
4. **Add a `Package.resolved` commit** (kept by `.gitignore`) so dependency versions are
   reproducible. Confirm it builds clean after a fresh checkout.
5. **Expand tests** around `PlaylistService` (add/remove/move/migration) and OSC command
   dispatch in `VideoPlayerViewModel` — these are the most logic-heavy, testable units.
6. **Optional:** make the OSC port configurable on iOS (currently hardcoded to 9000 in
   `VideoPromptApp.swift`).

---

## 8. Conventions

- **SwiftUI-first.** Prefer SwiftUI; only drop to UIKit/AppKit when wrapping `AVPlayerLayer`
  or system features that have no SwiftUI equivalent.
- **`@MainActor` for playback.** `VideoPlayerViewModel` is main-actor isolated; keep UI/player
  mutations on the main actor.
- **Services are `ObservableObject`s** created once in the `@main` App and injected down.
- **New control inputs** should funnel through `VideoPlayerViewModel`, not manipulate
  `AVPlayer` directly.
- Keep the player UI **chrome-free** — the whole point is distraction-free presentation.

---

## 9. Where to start reading code

1. `VideoPrompt/ContentView.swift` — see how everything is wired together.
2. `VideoPrompt/ViewModels/VideoPlayerViewModel.swift` — the playback/playlist logic.
3. `VideoPrompt/Services/OSCService.swift` — the remote-control protocol entry point.
4. `VideoPromptDesktop/VideoPromptDesktop/ContentView.swift` — the desktop gate issue (#1 above).
