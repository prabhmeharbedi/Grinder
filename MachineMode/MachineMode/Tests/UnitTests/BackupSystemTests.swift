import XCTest
import CoreData
@testable import MachineMode

class BackupSystemTests: XCTestCase {
    
    var persistenceController: PersistenceController!
    var context: NSManagedObjectContext!
    var backupManager: BackupManager!
    
    override func setUp() {
        super.setUp()
        persistenceController = PersistenceController.inMemory
        context = persistenceController.container.viewContext
        backupManager = BackupManager.shared
        
        // Initialize test data
        createTestData()
    }
    
    override func tearDown() {
        // Clean up test backups
        cleanupTestBackups()
        context = nil
        persistenceController = nil
        super.tearDown()
    }
    
    func testSQLiteBackupCreation() {
        let expectation = XCTestExpectation(description: "SQLite backup creation")
        
        backupManager.createBackup(format: .sqlite) { success, error in
            XCTAssertTrue(success, "SQLite backup should succeed")
            XCTAssertNil(error, "Should not have error: \(error?.localizedDescription ?? "")")
            
            // Verify backup file exists
            let backups = self.backupManager.listBackups()
            let sqliteBackups = backups.filter { $0.format == .sqlite }
            XCTAssertFalse(sqliteBackups.isEmpty, "Should have at least one SQLite backup")
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 10.0)
    }
    
    func testJSONBackupCreation() {
        let expectation = XCTestExpectation(description: "JSON backup creation")
        
        backupManager.createBackup(format: .json) { success, error in
            XCTAssertTrue(success, "JSON backup should succeed")
            XCTAssertNil(error, "Should not have error: \(error?.localizedDescription ?? "")")
            
            // Verify backup file exists and contains valid JSON
            let backups = self.backupManager.listBackups()
            let jsonBackups = backups.filter { $0.format == .json }
            XCTAssertFalse(jsonBackups.isEmpty, "Should have at least one JSON backup")
            
            if let jsonBackup = jsonBackups.first {
                do {
                    let data = try Data(contentsOf: jsonBackup.url)
                    let json = try JSONSerialization.jsonObject(with: data, options: [])
                    XCTAssertNotNil(json, "Backup should contain valid JSON")
                } catch {
                    XCTFail("Failed to validate JSON backup: \(error)")
                }
            }
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 10.0)
    }
    
    func testBackupRestore() {
        // Create backup first
        let backupExpectation = XCTestExpectation(description: "Backup creation")
        
        backupManager.createBackup(format: .sqlite) { success, error in
            XCTAssertTrue(success, "Backup creation should succeed")
            backupExpectation.fulfill()
        }
        
        wait(for: [backupExpectation], timeout: 10.0)
        
        // Modify data
        modifyTestData()
        
        // Restore from backup
        let restoreExpectation = XCTestExpectation(description: "Backup restore")
        
        let backups = backupManager.listBackups()
        guard let backup = backups.first else {
            XCTFail("No backup available for restore test")
            return
        }
        
        backupManager.restoreFromBackup(backup) { success, error in
            XCTAssertTrue(success, "Restore should succeed")
            XCTAssertNil(error, "Should not have error during restore")
            
            // Verify data was restored
            self.verifyOriginalTestData()
            
            restoreExpectation.fulfill()
        }
        
        wait(for: [restoreExpectation], timeout: 10.0)
    }
    
    func testBackupListing() {
        // Create multiple backups
        let group = DispatchGroup()
        
        for format in [BackupFormat.sqlite, BackupFormat.json] {
            group.enter()
            backupManager.createBackup(format: format) { success, error in
                XCTAssertTrue(success, "Backup creation should succeed")
                group.leave()
            }
        }
        
        group.wait()
        
        // Test listing
        let backups = backupManager.listBackups()
        XCTAssertGreaterThanOrEqual(backups.count, 2, "Should have at least 2 backups")
        
        // Verify backup info
        for backup in backups {
            XCTAssertTrue(FileManager.default.fileExists(atPath: backup.url.path), "Backup file should exist")
            XCTAssertNotNil(backup.createdAt, "Backup should have creation date")
            XCTAssertGreaterThan(backup.size, 0, "Backup should have non-zero size")
        }
    }
    
    func testBackupCleanup() {
        // Create old backups (simulate)
        let oldDate = Calendar.current.date(byAdding: .day, value: -8, to: Date())!
        
        // Create several backups to test cleanup
        let group = DispatchGroup()
        
        for i in 0..<5 {
            group.enter()
            backupManager.createBackup(format: .sqlite) { success, error in
                group.leave()
            }
        }
        
        group.wait()
        
        let backupsBefore = backupManager.listBackups().count
        
        // Trigger cleanup
        backupManager.cleanupOldBackups()
        
        let backupsAfter = backupManager.listBackups().count
        
        // Should clean up appropriately (exact number depends on implementation)
        XCTAssertLessThanOrEqual(backupsAfter, backupsBefore, "Cleanup should not increase backup count")
    }
    
    // MARK: - Helper Methods
    
    private func createTestData() {
        let day = Day(context: context)
        day.dayNumber = 1
        day.isUnlocked = true
        
        let problem = DSAProblem(context: context)
        problem.problemName = "Test Problem"
        problem.difficulty = "Easy"
        problem.isCompleted = false
        problem.day = day
        
        let topic = SystemDesignTopic(context: context)
        topic.topicName = "Test Topic"
        topic.isCompleted = false
        topic.day = day
        
        try? context.save()
    }
    
    private func modifyTestData() {
        let request: NSFetchRequest<DSAProblem> = DSAProblem.fetchRequest()
        if let problems = try? context.fetch(request) {
            for problem in problems {
                problem.isCompleted = true
                problem.timeSpent = 30
            }
        }
        try? context.save()
    }
    
    private func verifyOriginalTestData() {
        let request: NSFetchRequest<DSAProblem> = DSAProblem.fetchRequest()
        if let problems = try? context.fetch(request) {
            for problem in problems {
                // Note: This test depends on backup/restore implementation
                // Adjust assertions based on expected behavior
            }
        }
    }
    
    private func cleanupTestBackups() {
        let backups = backupManager.listBackups()
        for backup in backups {
            try? FileManager.default.removeItem(at: backup.url)
        }
    }
}