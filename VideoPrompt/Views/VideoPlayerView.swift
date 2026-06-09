//
//  VideoPlayerView.swift
//  VideoPromptOSC
//
//  Created for VideoPromptOSC App
//

import SwiftUI
import AVKit
import AVFoundation

struct VideoPlayerView: UIViewRepresentable {
    @ObservedObject var viewModel: VideoPlayerViewModel
    
    func makeUIView(context: Context) -> PlayerUIView {
        let view = PlayerUIView()
        view.backgroundColor = .black
        // Set initial player
        view.setPlayer(viewModel.player)
        return view
    }
    
    func updateUIView(_ uiView: PlayerUIView, context: Context) {
        // Only update if player instance actually changed
        uiView.setPlayer(viewModel.player)
    }
}

// Custom UIView that hosts AVPlayerLayer for better control
class PlayerUIView: UIView {
    
    override class var layerClass: AnyClass {
        return AVPlayerLayer.self
    }
    
    private var playerLayer: AVPlayerLayer {
        return layer as! AVPlayerLayer
    }
    
    private weak var currentPlayer: AVPlayer?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupPlayerLayer()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupPlayerLayer()
    }
    
    private func setupPlayerLayer() {
        playerLayer.videoGravity = .resizeAspect
        playerLayer.backgroundColor = UIColor.black.cgColor
    }
    
    func setPlayer(_ player: AVPlayer?) {
        // Only update if the player instance is different
        guard currentPlayer !== player else { return }
        currentPlayer = player
        playerLayer.player = player
    }
}

// MARK: - Remote Control and Keyboard Handling View
struct RemoteControlView: UIViewControllerRepresentable {
    let onRemoteControl: () -> Void
    let onNextPressed: () -> Void
    let onPreviousPressed: () -> Void
    let onSpacePressed: () -> Void
    
    func makeUIViewController(context: Context) -> RemoteControlViewController {
        let controller = RemoteControlViewController()
        controller.onRemoteControl = onRemoteControl
        controller.onNextPressed = onNextPressed
        controller.onPreviousPressed = onPreviousPressed
        controller.onSpacePressed = onSpacePressed
        return controller
    }
    
    func updateUIViewController(_ uiViewController: RemoteControlViewController, context: Context) {
        uiViewController.onRemoteControl = onRemoteControl
        uiViewController.onNextPressed = onNextPressed
        uiViewController.onPreviousPressed = onPreviousPressed
        uiViewController.onSpacePressed = onSpacePressed
    }
}

class RemoteControlViewController: UIViewController {
    var onRemoteControl: (() -> Void)?
    var onNextPressed: (() -> Void)?
    var onPreviousPressed: (() -> Void)?
    var onSpacePressed: (() -> Void)?
    
    private var observers: [NSObjectProtocol] = []
    
    override var canBecomeFirstResponder: Bool {
        return true
    }
    
    override var keyCommands: [UIKeyCommand]? {
        let rightArrow = UIKeyCommand(input: UIKeyCommand.inputRightArrow, modifierFlags: [], action: #selector(handleRightArrow))
        rightArrow.wantsPriorityOverSystemBehavior = true
        
        let leftArrow = UIKeyCommand(input: UIKeyCommand.inputLeftArrow, modifierFlags: [], action: #selector(handleLeftArrow))
        leftArrow.wantsPriorityOverSystemBehavior = true
        
        let space = UIKeyCommand(input: " ", modifierFlags: [], action: #selector(handleSpace))
        space.wantsPriorityOverSystemBehavior = true
        
        return [rightArrow, leftArrow, space]
    }
    
    @objc private func handleRightArrow() {
        onNextPressed?()
    }
    
    @objc private func handleLeftArrow() {
        onPreviousPressed?()
    }
    
    @objc private func handleSpace() {
        onSpacePressed?()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupObservers()
    }
    
    private func setupObservers() {
        // Reclaim first responder when app becomes active
        let activeObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.reclaimFirstResponder()
        }
        observers.append(activeObserver)
        
        // Reclaim first responder when video playback ends
        let endObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            // Delay slightly to ensure we reclaim after any system changes
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self?.reclaimFirstResponder()
            }
        }
        observers.append(endObserver)
        
        // Reclaim first responder when a new player item is loaded
        let newItemObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemNewAccessLogEntry,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self?.reclaimFirstResponder()
            }
        }
        observers.append(newItemObserver)
        
        // Reclaim first responder when video becomes ready to play
        let videoLoadedObserver = NotificationCenter.default.addObserver(
            forName: Notification.Name("VideoDidLoad"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                self?.reclaimFirstResponder()
            }
        }
        observers.append(videoLoadedObserver)
    }
    
    private func reclaimFirstResponder() {
        if !isFirstResponder {
            becomeFirstResponder()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        UIApplication.shared.beginReceivingRemoteControlEvents()
        
        // Try multiple times to become first responder during initial setup
        // This handles race conditions with video loading
        for delay in [0.1, 0.3, 0.5, 1.0] {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                self?.reclaimFirstResponder()
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        UIApplication.shared.endReceivingRemoteControlEvents()
        resignFirstResponder()
        
        // Clean up observers
        for observer in observers {
            NotificationCenter.default.removeObserver(observer)
        }
        observers.removeAll()
    }
    
    override func remoteControlReceived(with event: UIEvent?) {
        guard let event = event, event.type == .remoteControl else { return }
        
        switch event.subtype {
        case .remoteControlTogglePlayPause,
             .remoteControlPlay,
             .remoteControlPause:
            onRemoteControl?()
        default:
            break
        }
    }
}

#Preview {
    VideoPlayerView(viewModel: VideoPlayerViewModel())
}
