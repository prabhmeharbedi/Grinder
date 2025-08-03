import XCTest
import CoreData
@testable import MachineMode

class DataInitializationTests: XCTestCase {
    
    var persistenceController: PersistenceController!
    var context: NSManagedObjectContext!
    
    override func setUp() {
        super.setUp()
        persistenceController = PersistenceController.inMemory
        context = persistenceController.container.viewContext
    }
    
    override func tearDown() {
        context = nil
        persistenceController = nil
        super.tearDown()
    }
    
    func testCurriculumInitialization() {
        // Test that the curriculum initializes correctly
        let initializer = DataInitializer()
        
        let expectation = XCTestExpectation(description: "Curriculum initialization")
        
        initializer.initializeDefaultData(in: context) { success in
            XCTAssertTrue(success, "Curriculum initialization should succeed")
            
            // Verify days were created
            let dayRequest: NSFetchRequest<Day> = Day.fetchRequest()
            do {
                let days = try self.context.fetch(dayRequest)
                XCTAssertEqual(days.count, 100, "Should create 100 days")
                
                // Verify first day
                let firstDay = days.first { $0.dayNumber == 1 }
                XCTAssertNotNil(firstDay, "Day 1 should exist")
                
                // Verify DSA problems
                let dsaProblems = firstDay?.dsaProblems?.allObjects as? [DSAProblem]
                XCTAssertEqual(dsaProblems?.count, 2, "Day 1 should have 2 DSA problems")
                
                // Verify System Design topics
                let systemTopics = firstDay?.systemDesignTopics?.allObjects as? [SystemDesignTopic]
                XCTAssertEqual(systemTopics?.count, 1, "Day 1 should have 1 System Design topic")
                
            } catch {
                XCTFail("Failed to fetch days: \(error)")
            }
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 10.0)
    }
    
    func testUserSettingsInitialization() {
        let initializer = DataInitializer()
        
        initializer.initializeDefaultData(in: context) { success in
            XCTAssertTrue(success, "User settings initialization should succeed")
            
            let settingsRequest: NSFetchRequest<UserSettings> = UserSettings.fetchRequest()
            do {
                let settings = try self.context.fetch(settingsRequest)
                XCTAssertEqual(settings.count, 1, "Should create one UserSettings instance")
                
                let userSettings = settings.first!
                XCTAssertEqual(userSettings.currentStreak, 0, "Initial streak should be 0")
                XCTAssertEqual(userSettings.longestStreak, 0, "Initial longest streak should be 0")
                XCTAssertNotNil(userSettings.morningNotificationTime, "Morning notification time should be set")
                XCTAssertNotNil(userSettings.eveningNotificationTime, "Evening notification time should be set")
                
            } catch {
                XCTFail("Failed to fetch user settings: \(error)")
            }
        }
    }
    
    func testDuplicateInitialization() {
        let initializer = DataInitializer()
        
        // Initialize once
        initializer.initializeDefaultData(in: context) { success in
            XCTAssertTrue(success, "First initialization should succeed")
            
            // Initialize again
            initializer.initializeDefaultData(in: context) { secondSuccess in
                XCTAssertTrue(secondSuccess, "Second initialization should also succeed")
                
                // Verify no duplicates were created
                let dayRequest: NSFetchRequest<Day> = Day.fetchRequest()
                do {
                    let days = try self.context.fetch(dayRequest)
                    XCTAssertEqual(days.count, 100, "Should still have only 100 days")
                } catch {
                    XCTFail("Failed to fetch days: \(error)")
                }
            }
        }
    }
    
    func testDataConsistency() {
        let initializer = DataInitializer()
        
        initializer.initializeDefaultData(in: context) { success in
            XCTAssertTrue(success, "Initialization should succeed")
            
            // Test data relationships
            let dayRequest: NSFetchRequest<Day> = Day.fetchRequest()
            do {
                let days = try self.context.fetch(dayRequest)
                
                for day in days {
                    // Verify DSA problems are linked correctly
                    let dsaProblems = day.dsaProblems?.allObjects as? [DSAProblem]
                    for problem in dsaProblems ?? [] {
                        XCTAssertEqual(problem.day, day, "DSA problem should reference correct day")
                        XCTAssertFalse(problem.isCompleted, "Problems should start incomplete")
                        XCTAssertEqual(problem.timeSpent, 0, "Initial time spent should be 0")
                    }
                    
                    // Verify System Design topics are linked correctly
                    let systemTopics = day.systemDesignTopics?.allObjects as? [SystemDesignTopic]
                    for topic in systemTopics ?? [] {
                        XCTAssertEqual(topic.day, day, "System Design topic should reference correct day")
                        XCTAssertFalse(topic.isCompleted, "Topics should start incomplete")
                    }
                }
                
            } catch {
                XCTFail("Failed to verify data consistency: \(error)")
            }
        }
    }
}