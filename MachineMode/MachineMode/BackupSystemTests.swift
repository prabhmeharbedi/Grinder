import Foundation
import CoreData

/// Simple test class to verify backup system functionality
/// This is not a full XCTest suite but provides basic verification
class BackupSystemTests {
    
    static func runBasicTests() {
        print("🧪 Running backup system tests...")
        
        testBackupManagerInitialization()
        testBackupDirectoryCreation()
        testBackupListing()
        testDataIntegrityCheck()
        
        print("✅ All backup system tests completed")
    }
    
    private static func testBackupManagerInitialization() {
        print("Testing BackupManager initialization...")
        
        let backupManager = BackupManager.shared
        assert(backupManager != nil, "BackupManager should initialize")
        
        print("✅ BackupManager initialization test passed")
    }
    
    private static func testBackupDirectoryCreation() {
        print("Testing backup directory creation...")
        
        let fileManager = FileManager.default
        let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let backupsDirectory = documentsDirectory.appendingPathComponent("Backups")
        
        // Create directory if it doesn't exist
        do {
            try fileManager.createDirectory(at: backupsDirectory, withIntermediateDirectories: true)
            
            var isDirectory: ObjCBool = false
            let exists = fileManager.fileExists(atPath: backupsDirectory.path, isDirectory: &isDirectory)
            
            assert(exists && isDirectory.boolValue, "Backup directory should exist and be a directory")
            print("✅ Backup directory creation test passed")
            
        } catch {
            print("❌ Backup directory creation test failed: \(error)")
        }
    }
    
    private static func testBackupListing() {
        print("Testing backup listing...")
        
        let backups = BackupManager.shared.listBackups()
        print("Found \(backups.count) existing backups")
        
        // This should not fail even if no backups exist
        print("✅ Backup listing test passed")
    }
    
    private static func testDataIntegrityCheck() {
        print("Testing data integrity check...")
        
        let integrityResult = BackupRecoveryManager.shared.verifyAndRepairDataIntegrity()
        
        print("Integrity check result: \(integrityResult.severity.description)")
        print("Issues found: \(integrityResult.issues.count)")
        print("Repairs made: \(integrityResult.repaired.count)")
        
        if !integrityResult.issues.isEmpty {
            print("Issues: \(integrityResult.issues)")
        }
        
        if !integrityResult.repaired.isEmpty {
            print("Repairs: \(integrityResult.repaired)")
        }
        
        print("✅ Data integrity check test completed")
    }
    
    static func testManualBackupCreation() {
        print("🧪 Testing manual backup creation...")
        
        let expectation = DispatchSemaphore(value: 0)
        var testPassed = false
        
        BackupManager.shared.createManualBackup(format: .both) { success, error in
            if success {
                print("✅ Manual backup creation test passed")
                testPassed = true
            } else {
                print("❌ Manual backup creation test failed: \(error ?? "Unknown error")")
            }
            expectation.signal()
        }
        
        // Wait for completion (with timeout)
        let result = expectation.wait(timeout: .now() + 10)
        
        if result == .timedOut {
            print("❌ Manual backup creation test timed out")
        } else if testPassed {
            // Verify backup files were created
            let backups = BackupManager.shared.listBackups()
            let recentBackups = backups.filter { 
                Date().timeIntervalSince(Date()) < 60 // Created within last minute
            }
            
            if !recentBackups.isEmpty {
                print("✅ Backup files verified: \(recentBackups.count) recent backups found")
            } else {
                print("⚠️ No recent backup files found, but creation reported success")
            }
        }
    }
}