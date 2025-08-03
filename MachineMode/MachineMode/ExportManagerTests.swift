import XCTest
import CoreData
@testable import MachineMode

class ExportManagerTests: XCTestCase {
    var exportManager: ExportManager!
    var testContext: NSManagedObjectContext!
    
    override func setUp() {
        super.setUp()
        exportManager = ExportManager.shared
        
        // Create in-memory Core Data stack for testing
        let persistentContainer = NSPersistentContainer(name: "MachineMode")
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        persistentContainer.persistentStoreDescriptions = [description]
        
        persistentContainer.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Failed to load test store: \(error)")
            }
        }
        
        testContext = persistentContainer.viewContext
        
        // Create test data
        createTestData()
    }
    
    override func tearDown() {
        exportManager = nil
        testContext = nil
        super.tearDown()
    }
    
    func testMarkdownReportGeneration() {
        let expectation = self.expectation(description: "Markdown report generated")
        
        exportManager.createMarkdownReport { success, url, error in
            XCTAssertTrue(success, "Markdown report generation should succeed")
            XCTAssertNotNil(url, "Report URL should not be nil")
            XCTAssertNil(error, "Error should be nil")
            
            if let url = url {
                XCTAssertTrue(FileManager.default.fileExists(atPath: url.path), "Report file should exist")
                XCTAssertTrue(url.pathExtension == "md", "Report should be markdown file")
                
                // Verify content
                do {
                    let content = try String(contentsOf: url)
                    XCTAssertTrue(content.contains("# Machine Mode - 100 Day Progress Report"), "Should contain report title")
                    XCTAssertTrue(content.contains("## 📊 Overall Progress"), "Should contain overall progress section")
                    XCTAssertTrue(content.contains("### 🧮 DSA Problems"), "Should contain DSA section")
                    XCTAssertTrue(content.contains("### 🏗️ System Design"), "Should contain System Design section")
                } catch {
                    XCTFail("Failed to read report content: \(error)")
                }
            }
            
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 10.0)
    }
    
    func testJSONExportGeneration() {
        let expectation = self.expectation(description: "JSON export generated")
        
        exportManager.createJSONExport { success, url, error in
            XCTAssertTrue(success, "JSON export generation should succeed")
            XCTAssertNotNil(url, "Export URL should not be nil")
            XCTAssertNil(error, "Error should be nil")
            
            if let url = url {
                XCTAssertTrue(FileManager.default.fileExists(atPath: url.path), "Export file should exist")
                XCTAssertTrue(url.pathExtension == "json", "Export should be JSON file")
                
                // Verify JSON structure
                do {
                    let data = try Data(contentsOf: url)
                    let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                    
                    XCTAssertNotNil(json, "Should be valid JSON")
                    XCTAssertNotNil(json?["exportInfo"], "Should contain export info")
                    XCTAssertNotNil(json?["overallStatistics"], "Should contain overall statistics")
                    XCTAssertNotNil(json?["weeklyStatistics"], "Should contain weekly statistics")
                    XCTAssertNotNil(json?["dailyProgress"], "Should contain daily progress")
                    XCTAssertNotNil(json?["userSettings"], "Should contain user settings")
                } catch {
                    XCTFail("Failed to parse JSON export: \(error)")
                }
            }
            
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 10.0)
    }
    
    func testComprehensiveExport() {
        let expectation = self.expectation(description: "Comprehensive export generated")
        
        exportManager.createComprehensiveExport { success, urls, error in
            XCTAssertTrue(success, "Comprehensive export should succeed")
            XCTAssertEqual(urls.count, 2, "Should generate 2 files (markdown + JSON)")
            XCTAssertNil(error, "Error should be nil")
            
            let markdownURL = urls.first { $0.pathExtension == "md" }
            let jsonURL = urls.first { $0.pathExtension == "json" }
            
            XCTAssertNotNil(markdownURL, "Should include markdown file")
            XCTAssertNotNil(jsonURL, "Should include JSON file")
            
            if let markdownURL = markdownURL {
                XCTAssertTrue(FileManager.default.fileExists(atPath: markdownURL.path), "Markdown file should exist")
            }
            
            if let jsonURL = jsonURL {
                XCTAssertTrue(FileManager.default.fileExists(atPath: jsonURL.path), "JSON file should exist")
            }
            
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 15.0)
    }
    
    func testExportStatusUpdates() {
        XCTAssertEqual(exportManager.exportStatus, .idle, "Initial status should be idle")
        XCTAssertFalse(exportManager.isExporting, "Should not be exporting initially")
        
        let expectation = self.expectation(description: "Status updates during export")
        
        exportManager.createMarkdownReport { success, url, error in
            XCTAssertEqual(self.exportManager.exportStatus, .success("Markdown report created successfully"), "Should show success status")
            XCTAssertFalse(self.exportManager.isExporting, "Should not be exporting after completion")
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 10.0)
    }
    
    // MARK: - Test Data Creation
    
    private func createTestData() {
        // Create test days with DSA problems and System Design topics
        for dayNumber in 1...5 {
            let day = Day(context: testContext)
            day.dayNumber = Int32(dayNumber)
            day.date = Calendar.current.date(byAdding: .day, value: dayNumber - 1, to: Date())
            day.dsaProgress = dayNumber <= 3 ? 1.0 : 0.5
            day.systemDesignProgress = dayNumber <= 2 ? 1.0 : 0.0
            day.isCompleted = dayNumber <= 2
            day.dailyReflection = "Test reflection for day \(dayNumber)"
            day.createdAt = Date()
            day.updatedAt = Date()
            
            // Create test DSA problems
            for problemIndex in 1...3 {
                let problem = DSAProblem(context: testContext)
                problem.problemName = "Test Problem \(problemIndex) - Day \(dayNumber)"
                problem.leetcodeNumber = "\(dayNumber * 100 + problemIndex)"
                problem.difficulty = problemIndex == 1 ? "Easy" : (problemIndex == 2 ? "Medium" : "Hard")
                problem.isCompleted = dayNumber <= 3 && problemIndex <= 2
                problem.timeSpent = Int32(problemIndex * 15)
                problem.notes = "Test notes for problem \(problemIndex)"
                problem.isBonusProblem = problemIndex == 3
                problem.createdAt = Date()
                problem.updatedAt = Date()
                problem.day = day
                
                if problem.isCompleted {
                    problem.completedAt = Date()
                }
            }
            
            // Create test System Design topics
            for topicIndex in 1...2 {
                let topic = SystemDesignTopic(context: testContext)
                topic.topicName = "Test Topic \(topicIndex) - Day \(dayNumber)"
                topic.topicDescription = "Test description for topic \(topicIndex)"
                topic.isCompleted = dayNumber <= 2
                topic.videoWatched = dayNumber <= 2
                topic.taskCompleted = dayNumber <= 2
                topic.notes = "Test notes for topic \(topicIndex)"
                topic.createdAt = Date()
                topic.updatedAt = Date()
                topic.day = day
                
                if topic.isCompleted {
                    topic.completedAt = Date()
                }
            }
        }
        
        // Create test user settings
        let settings = UserSettings(context: testContext)
        settings.morningNotificationTime = Calendar.current.date(bySettingHour: 8, minute: 0, second: 0, of: Date())
        settings.eveningNotificationTime = Calendar.current.date(bySettingHour: 20, minute: 0, second: 0, of: Date())
        settings.isNotificationsEnabled = true
        settings.currentStreak = 3
        settings.longestStreak = 5
        settings.startDate = Calendar.current.date(byAdding: .day, value: -10, to: Date())
        settings.appVersion = "1.0"
        
        // Save test data
        do {
            try testContext.save()
        } catch {
            fatalError("Failed to save test data: \(error)")
        }
    }
}