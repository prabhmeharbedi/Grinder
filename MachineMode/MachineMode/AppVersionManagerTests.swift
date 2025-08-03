import Foundation
import XCTest
@testable import MachineMode

class AppVersionManagerTests {
    
    static func runBasicTests() {
        print("🧪 Running AppVersionManager basic tests...")
        
        testVersionDetection()
        testExpirationCalculation()
        testRebuildDetection()
        testDataIntegrityStatus()
        
        print("✅ AppVersionManager basic tests completed")
    }
    
    private static func testVersionDetection() {
        let manager = AppVersionManager.shared
        
        // Test that version is detected
        assert(!manager.currentVersion.isEmpty, "Current version should not be empty")
        print("✅ Version detection test passed: \(manager.currentVersion)")
    }
    
    private static func testExpirationCalculation() {
        let manager = AppVersionManager.shared
        
        // Test expiration calculation
        let daysUntilExpiration = manager.getDaysUntilExpiration()
        assert(daysUntilExpiration >= 0, "Days until expiration should be non-negative")
        assert(daysUntilExpiration <= 7, "Days until expiration should not exceed 7")
        
        print("✅ Expiration calculation test passed: \(daysUntilExpiration) days remaining")
    }
    
    private static func testRebuildDetection() {
        let manager = AppVersionManager.shared
        
        // Test that rebuild detection doesn't crash
        manager.checkForRebuild()
        
        // Test status text generation
        let statusText = manager.getExpirationStatusText()
        assert(!statusText.isEmpty, "Status text should not be empty")
        
        print("✅ Rebuild detection test passed: \(statusText)")
    }
    
    private static func testDataIntegrityStatus() {
        let manager = AppVersionManager.shared
        
        // Test that data integrity status is accessible
        let status = manager.dataIntegrityStatus
        let description = status.description
        assert(!description.isEmpty, "Data integrity status description should not be empty")
        
        print("✅ Data integrity status test passed: \(description)")
    }
    
    // MARK: - Mock Tests for Edge Cases
    
    static func testExpirationEdgeCases() {
        print("🧪 Testing expiration edge cases...")
        
        // Test with mock install date (7 days ago - should be expired)
        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
        UserDefaults.standard.set(sevenDaysAgo, forKey: "InstallDate")
        
        let manager = AppVersionManager.shared
        let daysRemaining = manager.getDaysUntilExpiration()
        assert(daysRemaining == 0, "App should be expired when installed 7 days ago")
        assert(manager.hasAppExpired(), "App should report as expired")
        
        print("✅ Expiration edge case test passed")
        
        // Reset to current date for normal operation
        UserDefaults.standard.removeObject(forKey: "InstallDate")
    }
    
    static func testAppStatusInfo() {
        print("🧪 Testing app status info...")
        
        let manager = AppVersionManager.shared
        let statusInfo = manager.getAppStatusInfo()
        
        assert(!statusInfo.currentVersion.isEmpty, "Status info should have current version")
        assert(statusInfo.daysUntilExpiration >= 0, "Status info should have valid expiration days")
        
        // Test formatted dates don't crash
        let _ = statusInfo.formattedInstallDate
        let _ = statusInfo.formattedExpirationDate
        let _ = statusInfo.formattedLastRebuildDate
        
        print("✅ App status info test passed")
    }
    
    static func testNotificationScheduling() {
        print("🧪 Testing notification scheduling...")
        
        let manager = AppVersionManager.shared
        
        // Test that notification scheduling doesn't crash
        manager.scheduleRebuildWarningNotifications()
        manager.scheduleRebuildSuccessNotification()
        
        print("✅ Notification scheduling test passed")
    }
    
    static func testBackupIntegration() {
        print("🧪 Testing backup integration...")
        
        let manager = AppVersionManager.shared
        let expectation = XCTestExpectation(description: "Backup creation")
        
        manager.createPreRebuildBackup { success, error in
            // Should not crash, regardless of success
            print("Pre-rebuild backup result: \(success), error: \(error ?? "none")")
            expectation.fulfill()
        }
        
        // Wait briefly for async operation
        let result = XCTWaiter.wait(for: [expectation], timeout: 5.0)
        assert(result == .completed, "Backup operation should complete")
        
        print("✅ Backup integration test passed")
    }
    
    // MARK: - Integration Test
    
    static func runIntegrationTests() {
        print("🧪 Running AppVersionManager integration tests...")
        
        testExpirationEdgeCases()
        testAppStatusInfo()
        testNotificationScheduling()
        testBackupIntegration()
        
        print("✅ AppVersionManager integration tests completed")
    }
}

// MARK: - Test Utilities

extension AppVersionManagerTests {
    
    static func simulateRebuild() {
        // Simulate a rebuild by changing the stored version
        let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let currentBuild = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        let newVersion = "\(currentVersion).\(Int(currentBuild)! + 1)"
        
        UserDefaults.standard.set("old_version", forKey: "AppVersion")
        
        // Trigger rebuild detection
        AppVersionManager.shared.checkForRebuild()
        
        print("🔄 Simulated rebuild from old_version to \(newVersion)")
    }
    
    static func resetTestState() {
        // Clean up test state
        UserDefaults.standard.removeObject(forKey: "InstallDate")
        UserDefaults.standard.removeObject(forKey: "AppVersion")
        UserDefaults.standard.removeObject(forKey: "LastRebuildDate")
        UserDefaults.standard.removeObject(forKey: "LastRebuildInfo")
        UserDefaults.standard.removeObject(forKey: "LastIntegrityCheck")
        
        print("🧹 Test state reset")
    }
}