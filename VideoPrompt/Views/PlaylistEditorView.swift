//
//  PlaylistEditorView.swift
//  VideoPromptOSC
//
//  Created for VideoPromptOSC App
//

import SwiftUI
import PhotosUI
import AVFoundation

struct PlaylistEditorView: View {
    @ObservedObject var playlistService: PlaylistService
    @ObservedObject var viewModel: VideoPlayerViewModel
    @ObservedObject var keyboardService: KeyboardService
    @Environment(\.dismiss) private var dismiss
    
    @State private var showVideoPicker = false
    @State private var showKeyboardSettings = false
    @State private var editMode: EditMode = .inactive
    
    var body: some View {
        NavigationView {
            List {
                // Playlist section
                if playlistService.isEmpty {
                    emptyStateView
                } else {
                    Section("Videos") {
                        ForEach(Array(playlistService.items.enumerated()), id: \.element.id) { index, item in
                            PlaylistRowView(
                                item: item,
                                isCurrentItem: index == playlistService.currentIndex,
                                onTap: {
                                    playlistService.setCurrentIndex(index)
                                    viewModel.loadCurrentPlaylistItem()
                                    dismiss()
                                }
                            )
                        }
                        .onMove { source, destination in
                            playlistService.move(from: source, to: destination)
                        }
                        .onDelete { offsets in
                            playlistService.remove(at: offsets)
                            if playlistService.isEmpty {
                                viewModel.loadCurrentPlaylistItem()
                            }
                        }
                    }
                }
                
                // Settings section
                Section("Settings") {
                    Button {
                        showKeyboardSettings = true
                    } label: {
                        HStack {
                            Image(systemName: "keyboard")
                                .foregroundColor(.accentColor)
                                .frame(width: 28)
                            Text("Keyboard Controls")
                                .foregroundColor(.primary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.secondary.opacity(0.5))
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Playlist & Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 16) {
                        if !playlistService.isEmpty {
                            EditButton()
                        }
                        
                        Button {
                            showVideoPicker = true
                        } label: {
                            Image(systemName: "plus")
                        }
                    }
                }
            }
            .environment(\.editMode, $editMode)
        }
        .sheet(isPresented: $showVideoPicker) {
            VideoPickerView { url in
                if let url = url {
                    _ = playlistService.add(from: url)
                    // If this is the first video, load it
                    if playlistService.items.count == 1 {
                        viewModel.loadCurrentPlaylistItem()
                    }
                }
                showVideoPicker = false
            }
        }
        .sheet(isPresented: $showKeyboardSettings) {
            KeyboardSettingsView(keyboardService: keyboardService)
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "film.stack")
                .font(.system(size: 50))
                .foregroundColor(.secondary)
            
            Text("No Videos")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("Tap + to add videos from your library\nor use AirDrop to send videos from your Mac")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button {
                showVideoPicker = true
            } label: {
                Label("Add Video", systemImage: "plus.circle.fill")
                    .font(.headline)
            }
            .buttonStyle(.borderedProminent)
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .listRowBackground(Color.clear)
    }
}

// MARK: - Playlist Row View

struct PlaylistRowView: View {
    let item: PlaylistItem
    let isCurrentItem: Bool
    let onTap: () -> Void
    
    @State private var thumbnail: UIImage?
    @State private var duration: String = ""
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Thumbnail
                ZStack {
                    if let thumbnail = thumbnail {
                        Image(uiImage: thumbnail)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } else {
                        Color.gray.opacity(0.3)
                        Image(systemName: "film")
                            .foregroundColor(.secondary)
                    }
                }
                .frame(width: 80, height: 45)
                .cornerRadius(6)
                .clipped()
                
                // Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.displayName)
                        .font(.system(size: 15, weight: isCurrentItem ? .semibold : .regular))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    if !duration.isEmpty {
                        Text(duration)
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Current item indicator
                if isCurrentItem {
                    Image(systemName: "play.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.accentColor)
                }
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
        .task {
            await loadMetadata()
        }
    }
    
    private func loadMetadata() async {
        guard item.exists else { return }
        
        let asset = AVAsset(url: item.fileURL)
        
        // Load duration
        do {
            let cmDuration = try await asset.load(.duration)
            let seconds = CMTimeGetSeconds(cmDuration)
            await MainActor.run {
                duration = formatDuration(seconds)
            }
        } catch {
            print("Failed to load duration: \(error)")
        }
        
        // Generate thumbnail
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.maximumSize = CGSize(width: 160, height: 90)
        
        do {
            let cgImage = try generator.copyCGImage(at: .zero, actualTime: nil)
            await MainActor.run {
                thumbnail = UIImage(cgImage: cgImage)
            }
        } catch {
            print("Failed to generate thumbnail: \(error)")
        }
    }
    
    private func formatDuration(_ seconds: Double) -> String {
        guard seconds.isFinite && seconds >= 0 else { return "" }
        
        let totalSeconds = Int(seconds)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let secs = totalSeconds % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, secs)
        } else {
            return String(format: "%d:%02d", minutes, secs)
        }
    }
}

#Preview {
    PlaylistEditorView(
        playlistService: PlaylistService(),
        viewModel: VideoPlayerViewModel(),
        keyboardService: KeyboardService()
    )
}
