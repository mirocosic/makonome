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

    @MainActor
    func testStopwatchButtonToggle() throws {
        let app = XCUIApplication()
        app.launch()
        
        // Find the Start/Stop button
        let startButton = app.buttons["Start"]
        let stopButton = app.buttons["Stop"]
        
        // Initially should show "Start"
        XCTAssertTrue(startButton.exists)
        XCTAssertFalse(stopButton.exists)
        
        // Tap Start button
        startButton.tap()
        
        // Should now show "Stop"
        XCTAssertTrue(stopButton.exists)
        XCTAssertFalse(startButton.exists)
        
        // Tap Stop button
        stopButton.tap()
        
        // Should return to "Start"
        XCTAssertTrue(startButton.exists)
        XCTAssertFalse(stopButton.exists)
    }
    
    @MainActor
    func testStopwatchUI() throws {
        let app = XCUIApplication()
        app.launch()
        
        // Check that initial UI elements exist
        XCTAssertTrue(app.staticTexts["Stopwatch"].exists)
        XCTAssertTrue(app.staticTexts["00:00.00"].exists)
        XCTAssertTrue(app.buttons["Start"].exists)
        
        // Start the timer
        app.buttons["Start"].tap()
        
        // Wait a moment and check that time has changed
        sleep(1)
        
        // Stop the timer
        app.buttons["Stop"].tap()
        
        // Check that time has reset to 00:00.00
        XCTAssertTrue(app.staticTexts["00:00.00"].exists)
        
        // Check if "Previous Times" section appeared
        XCTAssertTrue(app.staticTexts["Previous Times"].exists)
    }

    @MainActor
    func testLoggedTimes() throws {
        let app = XCUIApplication()
        app.launch()
        
        // Initially no "Previous Times" should be visible
        XCTAssertFalse(app.staticTexts["Previous Times"].exists)
        
        // Start and stop timer to log first time
        app.buttons["Start"].tap()
        sleep(2) // Wait 2 seconds
        app.buttons["Stop"].tap()
        
        // Check that "Previous Times" section appeared
        XCTAssertTrue(app.staticTexts["Previous Times"].exists)
        
        // Check that first logged time exists
        XCTAssertTrue(app.staticTexts["#1"].exists)
        
        // Start and stop timer again to log second time
        app.buttons["Start"].tap()
        sleep(1) // Wait 1 second
        app.buttons["Stop"].tap()
        
        // Check that second logged time exists
        XCTAssertTrue(app.staticTexts["#2"].exists)
        
        // Timer should reset to 00:00.00 after each stop
        XCTAssertTrue(app.staticTexts["00:00.00"].exists)
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
