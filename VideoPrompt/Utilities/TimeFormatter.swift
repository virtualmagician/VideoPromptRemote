//
//  TimeFormatter.swift
//  VideoPromptOSC
//
//  Created for VideoPromptOSC App
//

import Foundation

enum TimeFormatter {
    
    /// Format seconds into MM:SS string
    /// For videos longer than an hour, formats as HH:MM:SS
    static func format(seconds: Double) -> String {
        guard seconds.isFinite && seconds >= 0 else {
            return "00:00"
        }
        
        let totalSeconds = Int(seconds)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let secs = totalSeconds % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, secs)
        } else {
            return String(format: "%02d:%02d", minutes, secs)
        }
    }
}
