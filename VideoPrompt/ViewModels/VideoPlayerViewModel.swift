//
//  VideoPlayerViewModel.swift
//  VideoPromptOSC
//
//  Created for VideoPromptOSC App
//

import SwiftUI
import AVFoundation
import Combine

@MainActor
class VideoPlayerViewModel: ObservableObject, OSCCommandHandler, VolumeButtonHandler {
    
    // MARK: - Published Properties
    @Published var player: AVPlayer?
    @Published var videoURL: URL?
    @Published var isPlaying: Bool = false
    @Published var currentTime: Double = 0
    @Published var duration: Double = 0
    @Published var isLoading: Bool = false
    @Published var hasPlayedCurrentItem: Bool = false
    
    // Flag to auto-play when player becomes ready
    private var shouldPlayWhenReady: Bool = false
    
    // MARK: - Playlist Properties
    private(set) var playlistService: PlaylistService
    
    var currentIndex: Int {
        playlistService.currentIndex
    }
    
    var hasNext: Bool {
        playlistService.hasNext
    }
    
    var hasPrevious: Bool {
        playlistService.hasPrevious
    }
    
    var playlistCount: Int {
        playlistService.items.count
    }
    
    /// Set playlist service (for dependency injection from environment)
    func setPlaylistService(_ service: PlaylistService) {
        self.playlistService = service
    }
    
    // MARK: - Private Properties
    private var timeObserver: Any?
    private var playerItemObserver: AnyCancellable?
    private var endOfVideoObserver: NSObjectProtocol?
    private var playlistObserver: AnyCancellable?
    
    // Store references for cleanup outside of actor context
    private var cleanupPlayer: AVPlayer?
    private var cleanupTimeObserver: Any?
    private var cleanupEndObserver: NSObjectProtocol?
    
    // MARK: - Initialization
    init(playlistService: PlaylistService? = nil) {
        self.playlistService = playlistService ?? PlaylistService()
        setupRemoteControlEvents()
        setupPlaylistObserver()
    }
    
    // MARK: - Public Methods
    
    /// Load current playlist item
    func loadCurrentPlaylistItem() {
        guard let item = playlistService.currentItem else {
            videoURL = nil
            player = nil
            return
        }
        
        loadVideo(from: item.fileURL, saveToPlaylist: false)
    }
    
    /// Load video from URL
    func loadVideo(from url: URL, saveToPlaylist: Bool = true) {
        isLoading = true
        hasPlayedCurrentItem = false
        
        // Stop any existing playback
        player?.pause()
        removeObservers()
        
        // Reset autoplay flag if loading directly (not via loadNext/loadPrevious)
        if saveToPlaylist {
            shouldPlayWhenReady = false
        }
        
        if saveToPlaylist {
            // Add to playlist
            if let item = playlistService.add(from: url) {
                // Set as current item
                if let index = playlistService.items.firstIndex(of: item) {
                    playlistService.setCurrentIndex(index)
                }
                videoURL = item.fileURL
                setupPlayer(with: item.fileURL)
            }
        } else {
            // Load directly without adding to playlist
            videoURL = url
            setupPlayer(with: url)
        }
        
        isLoading = false
    }
    
    /// Load saved playlist on app launch
    func loadSavedVideo() {
        loadCurrentPlaylistItem()
    }
    
    /// Toggle between play and pause states
    func togglePlayPause() {
        guard player != nil else { return }
        
        if isPlaying {
            pause()
        } else {
            play()
        }
    }
    
    /// Start video playback
    func play() {
        player?.play()
        isPlaying = true
        hasPlayedCurrentItem = true
    }
    
    /// Pause video playback
    func pause() {
        player?.pause()
        isPlaying = false
    }
    
    /// Reset current video to the beginning and pause
    func resetToStart() {
        player?.seek(to: .zero) { [weak self] _ in
            Task { @MainActor in
                self?.pause()
                self?.currentTime = 0
                self?.hasPlayedCurrentItem = false
            }
        }
    }
    
    /// Reset to beginning of playlist (first item, time 0) and pause
    func resetPlaylist() {
        playlistService.resetToStart()
        loadCurrentPlaylistItem()
        resetToStart()
    }
    
    /// Load and optionally play the next item in playlist
    func loadNext(autoPlay: Bool = false) {
        guard playlistService.goToNext() else { return }
        shouldPlayWhenReady = autoPlay
        loadCurrentPlaylistItem()
    }
    
    /// Load the previous item in playlist
    func loadPrevious(autoPlay: Bool = false) {
        guard playlistService.goToPrevious() else { return }
        shouldPlayWhenReady = autoPlay
        loadCurrentPlaylistItem()
    }
    
    /// Play current item, or advance and play next if current has been played
    func playCurrentOrNext() {
        if hasPlayedCurrentItem && hasNext {
            loadNext(autoPlay: true)
        } else {
            play()
        }
    }
    
    // MARK: - OSCCommandHandler Protocol
    
    func handleOSCPlay() {
        play()
    }
    
    func handleOSCPause() {
        pause()
    }
    
    func handleOSCToggle() {
        togglePlayPause()
    }
    
    func handleOSCReset() {
        resetPlaylist()
    }
    
    func handleOSCNext() {
        loadNext(autoPlay: true)
    }
    
    func handleOSCPrevious() {
        loadPrevious(autoPlay: false)
    }
    
    // MARK: - VolumeButtonHandler Protocol
    
    func handleVolumeButtonSinglePress() {
        togglePlayPause()
    }
    
    func handleVolumeButtonDoublePress() {
        resetPlaylist()
    }
    
    /// Cleanup method to be called before the view disappears
    func cleanup() {
        removeObservers()
        player?.pause()
        player = nil
    }
    
    // MARK: - Private Methods
    
    private func setupPlayer(with url: URL) {
        let playerItem = AVPlayerItem(url: url)
        let newPlayer = AVPlayer(playerItem: playerItem)
        player = newPlayer
        
        // Store for cleanup
        cleanupPlayer = newPlayer
        
        setupTimeObserver()
        setupPlayerItemObserver(for: playerItem)
        setupEndOfVideoObserver()
        
        // Get video duration
        Task {
            await loadDuration(for: playerItem)
        }
    }
    
    private func loadDuration(for playerItem: AVPlayerItem) async {
        do {
            let duration = try await playerItem.asset.load(.duration)
            self.duration = CMTimeGetSeconds(duration)
        } catch {
            print("Failed to load duration: \(error)")
        }
    }
    
    private func setupTimeObserver() {
        // Update current time every 0.5 seconds to reduce UI updates
        let interval = CMTime(seconds: 0.5, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        let observer = player?.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            Task { @MainActor in
                self?.currentTime = CMTimeGetSeconds(time)
            }
        }
        timeObserver = observer
        cleanupTimeObserver = observer
    }
    
    private func setupPlayerItemObserver(for playerItem: AVPlayerItem) {
        playerItemObserver = playerItem.publisher(for: \.status)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                guard let self = self else { return }
                switch status {
                case .readyToPlay:
                    self.isLoading = false
                    // Post notification for keyboard handler to reclaim first responder
                    NotificationCenter.default.post(name: Notification.Name("VideoDidLoad"), object: nil)
                    // Auto-play if flag is set
                    if self.shouldPlayWhenReady {
                        self.shouldPlayWhenReady = false
                        self.play()
                    }
                case .failed:
                    print("Player item failed: \(playerItem.error?.localizedDescription ?? "Unknown error")")
                    self.isLoading = false
                    self.shouldPlayWhenReady = false
                default:
                    break
                }
            }
    }
    
    private func setupEndOfVideoObserver() {
        let observer = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: player?.currentItem,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                // When video ends, just pause at the end (don't auto-advance or reset)
                self?.pause()
                self?.hasPlayedCurrentItem = true
            }
        }
        endOfVideoObserver = observer
        cleanupEndObserver = observer
    }
    
    private func setupRemoteControlEvents() {
        // Enable receiving remote control events (for camera shutter button)
        NotificationCenter.default.addObserver(
            forName: UIApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { _ in
            UIApplication.shared.beginReceivingRemoteControlEvents()
        }
    }
    
    private func setupPlaylistObserver() {
        // Observe playlist changes to reload if current item changes externally
        playlistObserver = playlistService.$currentIndex
            .dropFirst()
            .sink { [weak self] _ in
                // Reload when index changes from outside (e.g., playlist editor)
            }
    }
    
    private func removeObservers() {
        if let observer = timeObserver {
            player?.removeTimeObserver(observer)
            timeObserver = nil
            cleanupTimeObserver = nil
        }
        
        playerItemObserver?.cancel()
        playerItemObserver = nil
        
        if let observer = endOfVideoObserver {
            NotificationCenter.default.removeObserver(observer)
            endOfVideoObserver = nil
            cleanupEndObserver = nil
        }
    }
}
