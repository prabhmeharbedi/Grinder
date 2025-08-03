import XCTest
import UserNotifications
@testable import MachineMode

class NotificationManagerTests: XCTestCase {
    
    func testNotificationManagerSingleton() {
        let manager1 = NotificationManager.shared
        let manager2 = NotificationManager.shared
        
        XCTAssertTrue(manager1 === manager2, "NotificationManager should be a singleton")
    }
    
    func testScheduleMorningMotivation() {
        let expectation = self.expectation(description: "Morning notification scheduled")
        
        let calendar = Calendar.current
        let morningTime = calendar.date(bySettingHour: 8, minute: 0, second: 0, of: Date())!
        
        NotificationManager.shared.scheduleMorningMotivation(time: morningTime)
        
        // Check if notification was scheduled
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            let morningNotification = requests.first { $0.identifier == "morning_motivation" }
            XCTAssertNotNil(morningNotification, "Morning motivation notification should be scheduled")
            XCTAssertEqual(morningNotification?.content.categoryIdentifier, "MORNING_MOTIVATION")
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 2.0)
    }
    
    func testScheduleEveningProgressCheck() {
        let expectation = self.expectation(description: "Evening notification scheduled")
        
        let calendar = Calendar.current
        let eveningTime = calendar.date(bySettingHour: 20, minute: 0, second: 0, of: Date())!
        
        NotificationManager.shared.scheduleEveningProgressCheck(time: eveningTime)
        
        // Check if notification was scheduled
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            let eveningNotification = requests.first { $0.identifier == "evening_progress" }
            XCTAssertNotNil(eveningNotification, "Evening progress notification should be scheduled")
            XCTAssertEqual(eveningNotification?.content.categoryIdentifier, "EVENING_PROGRESS")
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 2.0)
    }
    
    func testScheduleWeeklyReview() {
        let expectation = self.expectation(description: "Weekly review scheduled")
        
        NotificationManager.shared.scheduleWeeklyReview()
        
        // Check if notification was scheduled
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            let weeklyNotification = requests.first { $0.identifier == "weekly_review" }
            XCTAssertNotNil(weeklyNotification, "Weekly review notification should be scheduled")
            XCTAssertEqual(weeklyNotification?.content.categoryIdentifier, "WEEKLY_REVIEW")
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 2.0)
    }
    
    func testRebuildReminderScheduling() {
        let expectation = self.expectation(description: "Rebuild reminder scheduled")
        
        NotificationManager.shared.scheduleRebuildReminder(daysUntilExpiration: 1)
        
        // Check if notification was scheduled
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            let rebuildNotification = requests.first { $0.identifier == "rebuild_reminder_1" }
            XCTAssertNotNil(rebuildNotification, "Rebuild reminder notification should be scheduled")
            XCTAssertEqual(rebuildNotification?.content.categoryIdentifier, "REBUILD_REMINDER")
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 2.0)
    }
    
    func testCancelAllNotifications() {
        // First schedule some notifications
        NotificationManager.shared.scheduleAllNotifications()
        
        let expectation = self.expectation(description: "All notifications cancelled")
        
        // Then cancel them
        NotificationManager.shared.cancelAllNotifications()
        
        // Verify they're cancelled
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            XCTAssertEqual(requests.count, 0, "All notifications should be cancelled")
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 2.0)
    }
    
    func testNotificationCategories() {
        let expectation = self.expectation(description: "Notification categories set")
        
        UNUserNotificationCenter.current().getNotificationCategories { categories in
            let categoryIdentifiers = categories.map { $0.identifier }
            
            XCTAssertTrue(categoryIdentifiers.contains("MORNING_MOTIVATION"))
            XCTAssertTrue(categoryIdentifiers.contains("EVENING_PROGRESS"))
            XCTAssertTrue(categoryIdentifiers.contains("STREAK_ALERT"))
            XCTAssertTrue(categoryIdentifiers.contains("MILESTONE_ACHIEVEMENT"))
            XCTAssertTrue(categoryIdentifiers.contains("GENTLE_REMINDER"))
            XCTAssertTrue(categoryIdentifiers.contains("WEEKLY_REVIEW"))
            XCTAssertTrue(categoryIdentifiers.contains("REBUILD_REMINDER"))
            
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 2.0)
    }
    
    override func tearDown() {
        // Clean up after each test
        NotificationManager.shared.cancelAllNotifications()
        super.tearDown()
    }
}

// MARK: - Basic Integration Tests

class NotificationManagerIntegrationTests {
    
    static func runBasicTests() {
        print("🧪 Running NotificationManager integration tests...")
        
        testNotificationPermissionRequest()
        testScheduleAllNotifications()
        testNotificationCategoriesSetup()
        
        print("✅ NotificationManager integration tests completed")
    }
    
    private static func testNotificationPermissionRequest() {
        print("  Testing notification permission request...")
        
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            switch settings.authorizationStatus {
            case .authorized:
                print("    ✅ Notifications authorized")
            case .denied:
                print("    ❌ Notifications denied")
            case .notDetermined:
                print("    ⚠️ Notification permission not determined")
            case .provisional:
                print("    📱 Provisional notification access")
            case .ephemeral:
                print("    ⏰ Ephemeral notification access")
            @unknown default:
                print("    ❓ Unknown notification status")
            }
        }
    }
    
    private static func testScheduleAllNotifications() {
        print("  Testing schedule all notifications...")
        
        NotificationManager.shared.scheduleAllNotifications()
        
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            print("    📱 Scheduled \(requests.count) notifications")
            for request in requests {
                print("      - \(request.identifier): \(request.content.title)")
            }
        }
    }
    
    private static func testNotificationCategoriesSetup() {
        print("  Testing notification categories setup...")
        
        UNUserNotificationCenter.current().getNotificationCategories { categories in
            print("    📂 Configured \(categories.count) notification categories")
            for category in categories {
                print("      - \(category.identifier) (\(category.actions.count) actions)")
            }
        }
    }
}