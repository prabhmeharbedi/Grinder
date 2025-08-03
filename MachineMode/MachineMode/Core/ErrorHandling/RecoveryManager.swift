import CoreData
import SwiftUI

class RecoveryManager: ObservableObject {
    static let shared = RecoveryManager()
    
    @Published var isRecovering = false
    @Published var recoveryProgress: Double = 0.0
    @Published var recoveryMessage = ""
    
    private init() {}
    
    func attemptDataRecovery() {
        guard !isRecovering else { return }
        
        Task {
            await performDataRecovery()
        }
    }
    
    @MainActor
    private func performDataRecovery() async {
        isRecovering = true
        recoveryProgress = 0.0
        
        do {
            // Step 1: Backup current state
            recoveryMessage = "Creating safety backup..."
            recoveryProgress = 0.2
            try await createSafetyBackup()
            
            // Step 2: Verify data integrity
            recoveryMessage = "Checking data integrity..."
            recoveryProgress = 0.4
            let integrityResult = await verifyDataIntegrity()
            
            // Step 3: Attempt repairs
            if integrityResult.hasIssues {
                recoveryMessage = "Repairing data issues..."
                recoveryProgress = 0.6
                try await repairDataIssues(integrityResult)
            }
            
            // Step 4: Restore from backup if needed
            if integrityResult.severity == .critical {
                recoveryMessage = "Restoring from backup..."
                recoveryProgress = 0.8
                try await restoreFromBackup()
            }
            
            // Step 5: Finalize recovery
            recoveryMessage = "Finalizing recovery..."
            recoveryProgress = 1.0
            await finalizeRecovery()
            
            AccessibilityManager.shared.announceForVoiceOver("Data recovery completed successfully")
            
        } catch {
            print("❌ Recovery failed: \(error)")
            ErrorHandler.shared.handle(error: .dataCorruption("Recovery failed: \(error.localizedDescription)"))
        }
        
        isRecovering = false
    }
    
    private func createSafetyBackup() async throws {
        return try await withCheckedThrowingContinuation { continuation in
            BackupManager.shared.createBackup(format: .both) { success, error in
                if success {
                    continuation.resume()
                } else {
                    continuation.resume(throwing: error ?? AppError.backupFailed("Safety backup failed"))
                }
            }
        }
    }
    
    private func verifyDataIntegrity() async -> IntegrityResult {
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .utility).async {
                let result = BackupRecoveryManager.shared.verifyAndRepairDataIntegrity()
                continuation.resume(returning: result)
            }
        }
    }
    
    private func repairDataIssues(_ result: IntegrityResult) async throws {
        let context = PersistenceController.shared.container.viewContext
        
        await context.perform {
            do {
                // Attempt to fix data inconsistencies
                let validator = DataValidator()
                let fixedCount = try validator.fixDataInconsistencies(in: context)
                
                if fixedCount > 0 {
                    try context.save()
                    print("✅ Fixed \(fixedCount) data inconsistencies")
                }
            } catch {
                print("❌ Failed to repair data: \(error)")
                throw AppError.dataCorruption("Failed to repair data: \(error.localizedDescription)")
            }
        }
    }
    
    private func restoreFromBackup() async throws {
        let backups = BackupManager.shared.listBackups()
        
        guard let latestBackup = backups.first else {
            throw AppError.dataCorruption("No backups available for recovery")
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            BackupManager.shared.restoreFromBackup(latestBackup) { success, error in
                if success {
                    continuation.resume()
                } else {
                    continuation.resume(throwing: error ?? AppError.dataCorruption("Backup restoration failed"))
                }
            }
        }
    }
    
    private func finalizeRecovery() async {
        // Refresh all views and data
        NotificationCenter.default.post(name: NSNotification.Name("DataRecoveryCompleted"), object: nil)
        
        // Update app version manager
        AppVersionManager.shared.checkDataIntegrity()
        
        // Verify recovery was successful
        let finalCheck = await verifyDataIntegrity()
        if finalCheck.severity == .healthy {
            print("✅ Data recovery completed successfully")
        }
    }
    
    func recoverCoreDataContext() {
        let context = PersistenceController.shared.container.viewContext
        
        context.perform {
            if context.hasChanges {
                context.rollback()
            }
            
            // Reset the context
            context.reset()
            
            print("✅ Core Data context recovered")
        }
    }
}