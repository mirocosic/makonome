//
//  makonomeTests.swift
//  makonomeTests
//
//  Created by Miro on 23.06.2025..
//

import Testing
import SwiftUI
@testable import makonome

struct makonomeTests {

    // Test timer formatting function
    @Test func testTimeFormatting() async throws {
        let contentView = ContentView()
        
        // Test zero time
        #expect(contentView.formatTime(0) == "00:00.00")
        
        // Test seconds only
        #expect(contentView.formatTime(5.67) == "00:05.67")
        
        // Test minutes and seconds
        #expect(contentView.formatTime(125.34) == "02:05.34")
        
        // Test rounding of centiseconds
        #expect(contentView.formatTime(1.999) == "00:01.99")
        #expect(contentView.formatTime(1.001) == "00:01.00")
    }
    
    // Test edge cases in time formatting
    @Test func testTimeFormattingEdgeCases() async throws {
        let contentView = ContentView()
        
        // Test exactly one minute
        #expect(contentView.formatTime(60.0) == "01:00.00")
        
        // Test maximum reasonable time (99:59.99)
        #expect(contentView.formatTime(5999.99) == "99:59.98")
        
        // Test fractional seconds
        #expect(contentView.formatTime(10.123) == "00:10.12")
        #expect(contentView.formatTime(10.987) == "00:10.98")
    }

}
