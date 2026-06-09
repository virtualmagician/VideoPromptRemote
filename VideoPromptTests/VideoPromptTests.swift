//
//  VideoPromptTests.swift
//  VideoPromptTests
//
//  Created for VideoPrompt App
//

import XCTest
@testable import VideoPrompt

final class VideoPromptTests: XCTestCase {
    
    // MARK: - TimeFormatter Tests
    
    func testTimeFormatterWithZeroSeconds() {
        let result = TimeFormatter.format(seconds: 0)
        XCTAssertEqual(result, "00:00")
    }
    
    func testTimeFormatterWithSeconds() {
        let result = TimeFormatter.format(seconds: 45)
        XCTAssertEqual(result, "00:45")
    }
    
    func testTimeFormatterWithMinutesAndSeconds() {
        let result = TimeFormatter.format(seconds: 125)
        XCTAssertEqual(result, "02:05")
    }
    
    func testTimeFormatterWithHours() {
        let result = TimeFormatter.format(seconds: 3665)
        XCTAssertEqual(result, "1:01:05")
    }
    
    func testTimeFormatterWithNegativeValue() {
        let result = TimeFormatter.format(seconds: -10)
        XCTAssertEqual(result, "00:00")
    }
    
    func testTimeFormatterWithInfiniteValue() {
        let result = TimeFormatter.format(seconds: Double.infinity)
        XCTAssertEqual(result, "00:00")
    }
    
    func testTimeFormatterWithNaN() {
        let result = TimeFormatter.format(seconds: Double.nan)
        XCTAssertEqual(result, "00:00")
    }
    
    // MARK: - VideoStorageService Tests
    
    func testGetSavedVideoURLWithNoSavedVideo() {
        // Clear any existing saved video
        UserDefaults.standard.removeObject(forKey: "savedVideoFileName")
        
        let service = VideoStorageService()
        let result = service.getSavedVideoURL()
        
        XCTAssertNil(result)
    }
}
