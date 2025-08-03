import XCTest

class CoreWorkflowTests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }
    
    func testDailyProgressTracking() {
        // Test the core user workflow of tracking daily progress
        
        // Navigate to Today tab (should be default)
        let todayTab = app.tabBars.buttons["Today"]
        XCTAssertTrue(todayTab.exists, "Today tab should exist")
        
        // Check for day indicator
        let dayIndicator = app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'Day'")).firstMatch
        XCTAssertTrue(dayIndicator.exists, "Day indicator should be visible")
        
        // Find a DSA problem checkbox
        let problemCheckbox = app.buttons.matching(identifier: "problem_checkbox").firstMatch
        XCTAssertTrue(problemCheckbox.exists, "DSA problem checkbox should exist")
        
        // Tap to complete the problem
        problemCheckbox.tap()
        
        // Verify completion (button should change state)
        // Wait for animation to complete
        Thread.sleep(forTimeInterval: 0.5)
        
        // Check for progress update
        let progressBar = app.progressIndicators.firstMatch
        XCTAssertTrue(progressBar.exists, "Progress bar should exist")
        
        // Test adding notes
        let notesButton = app.buttons["Add Notes"].firstMatch
        if notesButton.exists {
            notesButton.tap()
            
            // Should open notes view
            let notesTextView = app.textViews.firstMatch
            XCTAssertTrue(notesTextView.exists, "Notes text view should exist")
            
            // Add some text
            notesTextView.tap()
            notesTextView.typeText("Test note for automation")
            
            // Save notes
            let saveButton = app.buttons["Save"]
            if saveButton.exists {
                saveButton.tap()
            } else {
                // If auto-save, just navigate back
                app.navigationBars.buttons.firstMatch.tap()
            }
        }
        
        // Test time tracking
        let timeButton = app.buttons["Track Time"].firstMatch
        if timeButton.exists {
            timeButton.tap()
            
            // Should open time tracker
            let timeView = app.otherElements["timeTracker"]
            XCTAssertTrue(timeView.exists, "Time tracker should open")
            
            // Add some time
            let plus30Button = app.buttons["+30m"]
            if plus30Button.exists {
                plus30Button.tap()
            }
            
            // Close time tracker
            let doneButton = app.buttons["Done"]
            if doneButton.exists {
                doneButton.tap()
            }
        }
    }
    
    func testNavigationBetweenTabs() {
        // Test smooth navigation between tabs
        
        // Start on Today tab
        let todayTab = app.tabBars.buttons["Today"]
        todayTab.tap()
        XCTAssertTrue(todayTab.isSelected, "Today tab should be selected")
        
        // Navigate to Progress tab
        let progressTab = app.tabBars.buttons["Progress"]
        progressTab.tap()
        XCTAssertTrue(progressTab.isSelected, "Progress tab should be selected")
        
        // Check for progress content
        let progressContent = app.otherElements["progressView"]
        XCTAssertTrue(progressContent.exists, "Progress view should be visible")
        
        // Navigate to Settings tab
        let settingsTab = app.tabBars.buttons["Settings"]
        settingsTab.tap()
        XCTAssertTrue(settingsTab.isSelected, "Settings tab should be selected")
        
        // Check for settings content
        let settingsContent = app.tables.firstMatch
        XCTAssertTrue(settingsContent.exists, "Settings table should be visible")
        
        // Navigate back to Today
        todayTab.tap()
        XCTAssertTrue(todayTab.isSelected, "Should return to Today tab")
    }
    
    func testProgressVisualization() {
        // Navigate to Progress tab
        let progressTab = app.tabBars.buttons["Progress"]
        progressTab.tap()
        
        // Check for overall progress
        let overallProgress = app.staticTexts.containing(NSPredicate(format: "label CONTAINS '%'")).firstMatch
        XCTAssertTrue(overallProgress.exists, "Overall progress percentage should be visible")
        
        // Check for streak information
        let streakInfo = app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'streak'")).firstMatch
        XCTAssertTrue(streakInfo.exists, "Streak information should be visible")
        
        // Check for progress charts/visualizations
        let chartView = app.otherElements["progressChart"]
        XCTAssertTrue(chartView.exists, "Progress chart should be visible")
        
        // Test interaction with heat map if present
        let heatMap = app.otherElements["heatMap"]
        if heatMap.exists {
            heatMap.tap()
            // Verify interaction response
        }
    }
    
    func testSettingsConfiguration() {
        // Navigate to Settings tab
        let settingsTab = app.tabBars.buttons["Settings"]
        settingsTab.tap()
        
        // Test notification settings
        let notificationSettings = app.cells["Notifications"]
        if notificationSettings.exists {
            notificationSettings.tap()
            
            // Should open notification configuration
            let morningTime = app.datePickers.firstMatch
            XCTAssertTrue(morningTime.exists, "Morning time picker should exist")
            
            // Navigate back
            app.navigationBars.buttons.firstMatch.tap()
        }
        
        // Test theme settings
        let themeSettings = app.cells["Theme"]
        if themeSettings.exists {
            themeSettings.tap()
            
            // Should show theme options
            let lightTheme = app.buttons["Light"]
            let darkTheme = app.buttons["Dark"]
            
            if lightTheme.exists && darkTheme.exists {
                // Test theme switching
                darkTheme.tap()
                Thread.sleep(forTimeInterval: 0.5)
                
                lightTheme.tap()
                Thread.sleep(forTimeInterval: 0.5)
            }
            
            // Navigate back
            app.navigationBars.buttons.firstMatch.tap()
        }
        
        // Test backup functionality
        let backupSettings = app.cells["Backup"]
        if backupSettings.exists {
            backupSettings.tap()
            
            // Test manual backup creation
            let createBackupButton = app.buttons["Create Backup"]
            if createBackupButton.exists {
                createBackupButton.tap()
                
                // Wait for backup creation
                Thread.sleep(forTimeInterval: 2.0)
                
                // Should show success message or updated backup list
            }
            
            // Navigate back
            app.navigationBars.buttons.firstMatch.tap()
        }
    }
    
    func testAccessibilityFeatures() {
        // Test VoiceOver accessibility
        if UIAccessibility.isVoiceOverRunning {
            // Test accessibility labels and hints
            let todayTab = app.tabBars.buttons["Today"]
            XCTAssertNotEqual(todayTab.label, "", "Today tab should have accessibility label")
            
            // Test problem accessibility
            let problemCheckbox = app.buttons.matching(identifier: "problem_checkbox").firstMatch
            if problemCheckbox.exists {
                XCTAssertNotEqual(problemCheckbox.label, "", "Problem checkbox should have accessibility label")
                XCTAssertNotEqual(problemCheckbox.hint, "", "Problem checkbox should have accessibility hint")
            }
            
            // Test progress accessibility
            let progressTab = app.tabBars.buttons["Progress"]
            progressTab.tap()
            
            let progressBar = app.progressIndicators.firstMatch
            if progressBar.exists {
                XCTAssertNotEqual(progressBar.label, "", "Progress bar should have accessibility label")
            }
        }
    }
    
    func testErrorHandling() {
        // Test app behavior under error conditions
        
        // Navigate to Settings
        let settingsTab = app.tabBars.buttons["Settings"]
        settingsTab.tap()
        
        // Try to trigger an error scenario (e.g., backup with no space)
        // This is challenging to test in UI tests, but we can test error display
        
        // Look for any error alerts or messages
        let errorAlert = app.alerts.firstMatch
        if errorAlert.exists {
            // If an error appears, test that it can be dismissed
            let okButton = errorAlert.buttons["OK"]
            if okButton.exists {
                okButton.tap()
            }
        }
    }
    
    func testLaunchPerformance() {
        // Test app launch time
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            app.terminate()
            app.launch()
        }
        
        // Verify app loads to usable state quickly
        let todayTab = app.tabBars.buttons["Today"]
        XCTAssertTrue(todayTab.waitForExistence(timeout: 2.0), "Today tab should appear within 2 seconds")
        
        // Verify content loads
        let dayIndicator = app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'Day'")).firstMatch
        XCTAssertTrue(dayIndicator.waitForExistence(timeout: 3.0), "Day content should load within 3 seconds")
    }
}