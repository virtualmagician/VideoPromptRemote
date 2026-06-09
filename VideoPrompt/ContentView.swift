//
//  ContentView.swift
//  VideoPromptOSC
//
//  Created for VideoPromptOSC App
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var playlistService: PlaylistService
    @EnvironmentObject private var oscService: OSCService
    @EnvironmentObject private var volumeButtonService: VolumeButtonService
    @EnvironmentObject private var keyboardService: KeyboardService
    
    @StateObject private var viewModel = VideoPlayerViewModel()
    @State private var showPlaylistEditor = false
    @State private var swipeFeedback: SwipeFeedback?
    @State private var hasInitialized = false
    @FocusState private var isViewFocused: Bool
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                Color.black
                    .ignoresSafeArea()
                
                // Video Player with gesture handling
                VideoPlayerContainerView(
                    viewModel: viewModel,
                    swipeFeedback: $swipeFeedback
                )
                .ignoresSafeArea()
                
                // No video overlay
                if viewModel.videoURL == nil {
                    NoVideoView()
                }
                
                // Overlay with time display and settings gear
                PlayerOverlayView(
                    viewModel: viewModel,
                    onSettingsTapped: {
                        viewModel.pause()
                        showPlaylistEditor = true
                    }
                )
                
                // Playlist position indicator (bottom-right)
                if viewModel.playlistCount > 1 {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            PlaylistPositionIndicator(
                                currentIndex: viewModel.currentIndex,
                                totalCount: viewModel.playlistCount
                            )
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 16)
                    }
                }
                
                // OSC Status indicator (bottom-left)
                VStack {
                    Spacer()
                    HStack {
                        OSCStatusIndicator(
                            isRunning: oscService.isRunning,
                            port: oscService.port
                        )
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)
                }
                
                // OSC Feedback overlay (center)
                OSCFeedbackView(
                    command: oscService.lastReceivedCommand,
                    isVisible: oscService.showFeedback
                )
                
                // Swipe feedback overlay
                if let feedback = swipeFeedback {
                    SwipeFeedbackView(feedback: feedback)
                }
            }
        }
        .statusBarHidden(true)
        .persistentSystemOverlays(.hidden)
        .focusable(interactions: .activate)
        .focusEffectDisabled()
        .focused($isViewFocused)
        .onKeyPress(phases: .down, action: handleKeyPress)
        .sheet(isPresented: $showPlaylistEditor) {
            PlaylistEditorView(
                playlistService: playlistService,
                viewModel: viewModel,
                keyboardService: keyboardService
            )
        }
        .onAppear {
            if !hasInitialized {
                // Initialize view model with playlist service
                viewModel.setPlaylistService(playlistService)
                // Load saved playlist on app launch
                viewModel.loadSavedVideo()
                // Connect OSC service to view model
                oscService.setCommandHandler(viewModel)
                // Connect volume button service to view model
                volumeButtonService.setHandler(viewModel)
                // Connect keyboard service to view model
                keyboardService.setCommandHandler(viewModel)
                hasInitialized = true
            }
            // Request focus for keyboard input
            isViewFocused = true
        }
        .onChange(of: playlistService.items.count) { oldCount, newCount in
            // Reload if items were added externally (e.g., via AirDrop)
            if newCount > oldCount && hasInitialized {
                // New item added, optionally reload
                if viewModel.videoURL == nil {
                    viewModel.loadCurrentPlaylistItem()
                }
            }
        }
        .onChange(of: showPlaylistEditor) { _, isShowing in
            // Restore focus when sheet is dismissed
            if !isShowing {
                isViewFocused = true
            }
        }
        .onChange(of: viewModel.isPlaying) { _, isPlaying in
            // Restore focus when playback stops (e.g., video ends)
            // AVPlayer can cause focus to shift when playback state changes
            // Use delay to ensure focus is restored after any async focus stealing
            if !isPlaying {
                Task {
                    try? await Task.sleep(nanoseconds: 100_000_000) // 100ms delay
                    isViewFocused = true
                }
            }
        }
        .onChange(of: isViewFocused) { _, isFocused in
            // Aggressively restore focus if lost while not showing a sheet
            if !isFocused && !showPlaylistEditor {
                Task {
                    try? await Task.sleep(nanoseconds: 50_000_000) // 50ms delay
                    isViewFocused = true
                }
            }
        }
    }
    
    /// Handle keyboard input - always returns .handled for arrow keys to prevent focus navigation
    private func handleKeyPress(_ keyPress: KeyPress) -> KeyPress.Result {
        // Always handle arrow keys to prevent iOS focus navigation
        let isArrowKey = keyPress.key == .leftArrow || keyPress.key == .rightArrow ||
                         keyPress.key == .upArrow || keyPress.key == .downArrow
        
        // Try to handle with keyboard service
        if keyboardService.handleKeyPress(keyPress) {
            return .handled
        }
        
        // Even if not bound, consume arrow keys to prevent focus navigation
        if isArrowKey {
            return .handled
        }
        
        return .ignored
    }
}

// MARK: - Swipe Feedback

enum SwipeFeedback {
    case next
    case previous
    case noNext
    case noPrevious
    
    var icon: String {
        switch self {
        case .next: return "forward.fill"
        case .previous: return "backward.fill"
        case .noNext, .noPrevious: return "xmark"
        }
    }
    
    var text: String {
        switch self {
        case .next: return "NEXT"
        case .previous: return "PREVIOUS"
        case .noNext: return "END OF PLAYLIST"
        case .noPrevious: return "START OF PLAYLIST"
        }
    }
}

struct SwipeFeedbackView: View {
    let feedback: SwipeFeedback
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: feedback.icon)
                .font(.system(size: 40, weight: .bold))
            Text(feedback.text)
                .font(.system(size: 16, weight: .bold, design: .rounded))
        }
        .foregroundColor(.white)
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.black.opacity(0.7))
        )
        .transition(.scale.combined(with: .opacity))
    }
}

// MARK: - Playlist Position Indicator

struct PlaylistPositionIndicator: View {
    let currentIndex: Int
    let totalCount: Int
    
    var body: some View {
        Text("\(currentIndex + 1) / \(totalCount)")
            .font(.system(size: 14, weight: .medium, design: .monospaced))
            .foregroundColor(.white.opacity(0.8))
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(Color.black.opacity(0.5))
            )
    }
}

// MARK: - Video Player Container

struct VideoPlayerContainerView: View {
    @ObservedObject var viewModel: VideoPlayerViewModel
    @Binding var swipeFeedback: SwipeFeedback?
    
    @State private var dragOffset: CGFloat = 0
    private let swipeThreshold: CGFloat = 50
    
    var body: some View {
        VideoPlayerView(viewModel: viewModel)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 30)
                    .onChanged { value in
                        dragOffset = value.translation.width
                    }
                    .onEnded { value in
                        handleSwipe(translation: value.translation.width)
                        dragOffset = 0
                    }
            )
            .simultaneousGesture(
                TapGesture(count: 2)
                    .onEnded {
                        // Double tap: reset to playlist start
                        viewModel.resetPlaylist()
                    }
            )
            .simultaneousGesture(
                TapGesture(count: 1)
                    .onEnded {
                        // Single tap: toggle play/pause
                        viewModel.togglePlayPause()
                    }
            )
    }
    
    private func handleSwipe(translation: CGFloat) {
        if translation > swipeThreshold {
            // Right swipe: always advance to next and play
            if viewModel.hasNext {
                viewModel.loadNext(autoPlay: true)
                showFeedback(.next)
            } else {
                showFeedback(.noNext)
            }
        } else if translation < -swipeThreshold {
            // Left swipe: go to previous
            if viewModel.hasPrevious {
                viewModel.loadPrevious(autoPlay: false)
                showFeedback(.previous)
            } else {
                showFeedback(.noPrevious)
            }
        }
    }
    
    private func showFeedback(_ feedback: SwipeFeedback) {
        withAnimation(.easeOut(duration: 0.2)) {
            swipeFeedback = feedback
        }
        
        Task {
            try? await Task.sleep(nanoseconds: 600_000_000)
            withAnimation(.easeOut(duration: 0.2)) {
                swipeFeedback = nil
            }
        }
    }
}

// MARK: - No Video View

struct NoVideoView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "video.badge.plus")
                .font(.system(size: 60))
                .foregroundColor(.white.opacity(0.6))
            
            Text("Tap the gear icon to add videos")
                .font(.system(size: 18, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.6))
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(OSCService(port: 9000))
        .environmentObject(VolumeButtonService())
        .environmentObject(PlaylistService())
        .environmentObject(KeyboardService())
}
