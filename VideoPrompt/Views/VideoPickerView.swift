//
//  VideoPickerView.swift
//  VideoPromptOSC
//
//  Created for VideoPromptOSC App
//

import SwiftUI
import PhotosUI

struct VideoPickerView: UIViewControllerRepresentable {
    let onVideoSelected: (URL?) -> Void
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var configuration = PHPickerConfiguration()
        configuration.filter = .videos
        configuration.selectionLimit = 1
        configuration.preferredAssetRepresentationMode = .current
        
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onVideoSelected: onVideoSelected)
    }
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let onVideoSelected: (URL?) -> Void
        
        init(onVideoSelected: @escaping (URL?) -> Void) {
            self.onVideoSelected = onVideoSelected
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            guard let result = results.first else {
                onVideoSelected(nil)
                return
            }
            
            let itemProvider = result.itemProvider
            
            // Check if we can load a video
            if itemProvider.hasItemConformingToTypeIdentifier(UTType.movie.identifier) {
                itemProvider.loadFileRepresentation(forTypeIdentifier: UTType.movie.identifier) { [weak self] url, error in
                    if let error = error {
                        print("Error loading video: \(error)")
                        DispatchQueue.main.async {
                            self?.onVideoSelected(nil)
                        }
                        return
                    }
                    
                    guard let url = url else {
                        DispatchQueue.main.async {
                            self?.onVideoSelected(nil)
                        }
                        return
                    }
                    
                    // Copy to temporary location since the original URL is temporary
                    let tempURL = FileManager.default.temporaryDirectory
                        .appendingPathComponent(UUID().uuidString)
                        .appendingPathExtension(url.pathExtension)
                    
                    do {
                        try FileManager.default.copyItem(at: url, to: tempURL)
                        DispatchQueue.main.async {
                            self?.onVideoSelected(tempURL)
                        }
                    } catch {
                        print("Error copying video: \(error)")
                        DispatchQueue.main.async {
                            self?.onVideoSelected(nil)
                        }
                    }
                }
            } else {
                onVideoSelected(nil)
            }
        }
    }
}
