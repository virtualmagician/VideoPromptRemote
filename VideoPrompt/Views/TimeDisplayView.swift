//
//  TimeDisplayView.swift
//  VideoPromptOSC
//
//  Created for VideoPromptOSC App
//

import SwiftUI

struct TimeDisplayView: View {
    let currentTime: Double
    let duration: Double
    
    var body: some View {
        HStack(spacing: 4) {
            Text(TimeFormatter.format(seconds: currentTime))
                .monospacedDigit()
            
            Text("/")
                .foregroundColor(.white.opacity(0.6))
            
            Text(TimeFormatter.format(seconds: duration))
                .monospacedDigit()
                .foregroundColor(.white.opacity(0.7))
        }
        .font(.system(size: 14, weight: .medium, design: .monospaced))
        .foregroundColor(.white)
    }
}

#Preview {
    ZStack {
        Color.black
        TimeDisplayView(currentTime: 65, duration: 180)
    }
}
