//
//  PlayerOverlayView.swift
//  VideoPromptOSC
//
//  Created for VideoPromptOSC App
//

import SwiftUI

struct PlayerOverlayView: View {
    @ObservedObject var viewModel: VideoPlayerViewModel
    let onSettingsTapped: () -> Void
    
    var body: some View {
        VStack {
            HStack {
                Spacer()
                
                // Time display and settings HUD
                HStack(spacing: 12) {
                    // Time display - isolated to prevent full overlay re-renders
                    TimeDisplayContainer(viewModel: viewModel)
                    
                    // Divider
                    Rectangle()
                        .fill(Color.white.opacity(0.3))
                        .frame(width: 1, height: 20)
                    
                    // Settings gear button
                    Button(action: onSettingsTapped) {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.white.opacity(0.9))
                    }
                    .buttonStyle(PlainButtonStyle())
                    .focusable(false)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.black.opacity(0.5))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )
                )
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            
            Spacer()
        }
        // Remote control and keyboard handling via UIKit
        .background(
            RemoteControlView(
                onRemoteControl: {
                    viewModel.togglePlayPause()
                },
                onNextPressed: {
                    if viewModel.hasNext {
                        viewModel.loadNext(autoPlay: true)
                    }
                },
                onPreviousPressed: {
                    if viewModel.hasPrevious {
                        viewModel.loadPrevious(autoPlay: false)
                    }
                },
                onSpacePressed: {
                    viewModel.togglePlayPause()
                }
            )
            .frame(width: 0, height: 0)
        )
    }
}

// Isolated container for time display to minimize re-render scope
struct TimeDisplayContainer: View {
    @ObservedObject var viewModel: VideoPlayerViewModel
    
    var body: some View {
        TimeDisplayView(
            currentTime: viewModel.currentTime,
            duration: viewModel.duration
        )
    }
}

#Preview {
    ZStack {
        Color.black
        PlayerOverlayView(
            viewModel: VideoPlayerViewModel(),
            onSettingsTapped: {}
        )
    }
}
