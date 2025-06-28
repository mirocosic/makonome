//
//  makonomeUITests.swift
//  makonomeUITests
//
//  Created by Miro on 23.06.2025..
//

import XCTest

final class makonomeUITests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    
    // MARK: - Metronome UI Tests
    
    @MainActor
    func testMetronomeDefaultScreen() throws {
        let app = XCUIApplication()
        app.launch()
        
        // App should launch with Metronome tab selected by default
        XCTAssertTrue(app.staticTexts["Metronome"].exists)
        XCTAssertTrue(app.staticTexts["120 BPM"].exists)
        XCTAssertTrue(app.buttons["Start"].exists)
        XCTAssertTrue(app.staticTexts["Subdivision"].exists)
    }
    
    @MainActor
    func testMetronomeStartStop() throws {
        let app = XCUIApplication()
        app.launch()
        
        // Initially should show "Start" button
        let startButton = app.buttons["Start"]
        let stopButton = app.buttons["Stop"]
        
        XCTAssertTrue(startButton.exists)
        XCTAssertFalse(stopButton.exists)
        
        // Tap Start button
        startButton.tap()
        
        // Should now show "Stop" button and beat indicator
        XCTAssertTrue(stopButton.exists)
        XCTAssertFalse(startButton.exists)
        XCTAssertTrue(app.staticTexts["Beat: 1"].exists)
        
        // Wait a moment for beats to increment
        sleep(1)
        
        // Tap Stop button
        stopButton.tap()
        
        // Should return to "Start" and hide beat indicator
        XCTAssertTrue(startButton.exists)
        XCTAssertFalse(stopButton.exists)
        XCTAssertFalse(app.staticTexts.matching(identifier: "Beat:").firstMatch.exists)
    }
    
    @MainActor
    func testMetronomeSubdivisionMenu() throws {
        let app = XCUIApplication()
        app.launch()
        
        // Should show default quarter notes elements
        XCTAssertTrue(app.staticTexts["♩"].exists)
        XCTAssertTrue(app.staticTexts["Quarter Notes"].exists)
        XCTAssertTrue(app.staticTexts["Subdivision"].exists)
        
        // Find the subdivision menu button (it's the one with the chevron)
        let subdivisionMenuButton = app.buttons.containing(.staticText, identifier:"♩").firstMatch
        XCTAssertTrue(subdivisionMenuButton.exists)
        
        // Tap the subdivision menu
        subdivisionMenuButton.tap()
        
        // Menu should appear with all options - now with proper accessibility labels
        XCTAssertTrue(app.buttons["♩"].exists)
        XCTAssertTrue(app.buttons["♫"].exists)
        XCTAssertTrue(app.buttons["♪♪♪"].exists)
        
        // Select eighth notes
        app.buttons["♫ Eighth Notes"].tap()
        
        // Should update to show eighth notes
        XCTAssertTrue(app.staticTexts["♫"].exists)
        XCTAssertTrue(app.staticTexts["Eighth Notes"].exists)
        XCTAssertFalse(app.staticTexts["♩"].exists)
    }
    
    @MainActor
    func testMetronomeBPMSlider() throws {
        let app = XCUIApplication()
        app.launch()
        
        // Should show default 120 BPM
        XCTAssertTrue(app.staticTexts["120 BPM"].exists)
        
        // Find and adjust BPM slider
        let slider = app.sliders.firstMatch
        XCTAssertTrue(slider.exists)
        
        // Adjust slider to increase BPM
        slider.adjust(toNormalizedSliderPosition: 0.75) // Should be around 310 BPM
        
        // BPM should have changed (exact value may vary due to slider precision)
        XCTAssertFalse(app.staticTexts["120 BPM"].exists)
        
        // Start metronome to test that slider gets disabled
        app.buttons["Start"].tap()
        
        // Slider should be disabled when playing
        XCTAssertFalse(slider.isEnabled)
        
        // Stop metronome
        app.buttons["Stop"].tap()
        
        // Slider should be enabled again
        XCTAssertTrue(slider.isEnabled)
    }
    
    @MainActor
    func testTabNavigation() throws {
        let app = XCUIApplication()
        app.launch()
        
        // Should start on Metronome tab
        XCTAssertTrue(app.staticTexts["Metronome"].exists)
        
        // Navigate to Settings tab
        app.tabBars.buttons["Settings"].tap()
        XCTAssertTrue(app.staticTexts["Settings"].exists)
        
        // Navigate back to Metronome tab
        app.tabBars.buttons["Metronome"].tap()
        XCTAssertTrue(app.staticTexts["Metronome"].exists)
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'BPM'")).firstMatch.exists)
    }
    
    @MainActor
    func testLaunchPerformance() throws {
        if #available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 7.0, *) {
            // This measures how long it takes to launch your application.
            measure(metrics: [XCTApplicationLaunchMetric()]) {
                XCUIApplication().launch()
            }
        }
    }
}
