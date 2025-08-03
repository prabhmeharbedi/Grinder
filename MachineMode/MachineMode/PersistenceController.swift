import CoreData
import Foundation
import UIKit

struct PersistenceController {
    static let shared = PersistenceController()
    
    static var preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        
        // Create sample data for previews
        let sampleDay = Day(context: viewContext)
        sampleDay.dayNumber = 1
        sampleDay.date = Date()
        sampleDay.dsaProgress = 0.6
        sampleDay.systemDesignProgress = 0.4
        sampleDay.isCompleted = false
        sampleDay.createdAt = Date()
        sampleDay.updatedAt = Date()
        
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        return result
    }()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "MachineMode")
        
        if !inMemory {
            // Configure store in Documents directory for rebuild persistence
            let storeURL = documentsDirectory.appendingPathComponent("MachineMode.sqlite")
            container.persistentStoreDescriptions.first?.url = storeURL
            
            // Enable persistent history tracking for data integrity
            container.persistentStoreDescriptions.first?.setOption(true as NSNumber, 
                                                                   forKey: NSPersistentHistoryTrackingKey)
            container.persistentStoreDescriptions.first?.setOption(true as NSNumber,
                                                                   forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
            
            // Enable automatic lightweight migration
            container.persistentStoreDescriptions.first?.setOption(true as NSNumber,
                                                                   forKey: NSMigratePersistentStoresAutomaticallyOption)
            container.persistentStoreDescriptions.first?.setOption(true as NSNumber,
                                                                   forKey: NSInferMappingModelAutomaticallyOption)
        } else {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        
        container.loadPersistentStores { storeDescription, error in
            if let error = error as NSError? {
                print("❌ Core Data error: \(error), \(error.userInfo)")
                
                // Attempt recovery if possible
                if !inMemory {
                    self.handleStoreLoadError(error: error, storeURL: storeDescription.url)
                } else {
                    fatalError("Unresolved error \(error), \(error.userInfo)")
                }
            } else {
                print("✅ Core Data store loaded successfully at: \(storeDescription.url?.path ?? "unknown")")
                
                // Perform integrity check after successful load
                if !inMemory {
                    self.performDataIntegrityCheck()
                }
            }
        }
        
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        
        // Set up automatic save on context changes
        setupAutomaticSave()
    }
    
    private var documentsDirectory: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    }
    
    // MARK: - Save Operations
    func save() {
        let context = container.viewContext

        if context.hasChanges {
            do {
                try context.save()
                print("✅ Core Data context saved successfully")
            } catch {
                handleSaveError(error: error, context: context)
            }
        }
    }
    
    func saveWithValidation() throws {
        let context = container.viewContext
        
        if context.hasChanges {
            // Validate all inserted and updated objects
            try validateContextObjects(context)
            
            do {
                try context.save()
                print("✅ Core Data context saved successfully with validation")
            } catch {
                print("❌ Core Data save error after validation: \(error)")
                throw PersistenceError.saveOperationFailed(error)
            }
        }
    }
    
    // MARK: - Data Integrity
    func performDataIntegrityCheck() {
        let context = container.viewContext
        
        Task {
            await context.perform {
                do {
                    // Check for orphaned records
                    try self.checkForOrphanedRecords(context: context)
                    
                    // Validate data consistency
                    try self.validateDataConsistency(context: context)
                    
                    // Update progress calculations
                    self.updateAllProgressCalculations(context: context)
                    
                    print("✅ Data integrity check completed successfully")
                } catch {
                    print("⚠️ Data integrity issues found: \(error)")
                }
            }
        }
    }
    
    private func checkForOrphanedRecords(context: NSManagedObjectContext) throws {
        // Check for DSA problems without days
        let orphanedProblemsRequest: NSFetchRequest<DSAProblem> = DSAProblem.fetchRequest()
        orphanedProblemsRequest.predicate = NSPredicate(format: "day == nil")
        
        let orphanedProblems = try context.fetch(orphanedProblemsRequest)
        if !orphanedProblems.isEmpty {
            print("⚠️ Found \(orphanedProblems.count) orphaned DSA problems")
            // Clean up orphaned problems
            orphanedProblems.forEach { context.delete($0) }
        }
        
        // Check for system design topics without days
        let orphanedTopicsRequest: NSFetchRequest<SystemDesignTopic> = SystemDesignTopic.fetchRequest()
        orphanedTopicsRequest.predicate = NSPredicate(format: "day == nil")
        
        let orphanedTopics = try context.fetch(orphanedTopicsRequest)
        if !orphanedTopics.isEmpty {
            print("⚠️ Found \(orphanedTopics.count) orphaned system design topics")
            // Clean up orphaned topics
            orphanedTopics.forEach { context.delete($0) }
        }
        
        if !orphanedProblems.isEmpty || !orphanedTopics.isEmpty {
            try context.save()
        }
    }
    
    private func validateDataConsistency(context: NSManagedObjectContext) throws {
        // Fetch all days and validate their data
        let daysRequest: NSFetchRequest<Day> = Day.fetchRequest()
        let days = try context.fetch(daysRequest)
        
        for day in days {
            // Validate day number range
            if day.dayNumber < 1 || day.dayNumber > 100 {
                print("⚠️ Invalid day number found: \(day.dayNumber)")
                throw PersistenceError.dataCorruption("Invalid day number: \(day.dayNumber)")
            }
            
            // Validate progress values
            if day.dsaProgress < 0.0 || day.dsaProgress > 1.0 {
                print("⚠️ Invalid DSA progress found: \(day.dsaProgress)")
                day.dsaProgress = max(0.0, min(1.0, day.dsaProgress))
            }
            
            if day.systemDesignProgress < 0.0 || day.systemDesignProgress > 1.0 {
                print("⚠️ Invalid System Design progress found: \(day.systemDesignProgress)")
                day.systemDesignProgress = max(0.0, min(1.0, day.systemDesignProgress))
            }
        }
    }
    
    private func updateAllProgressCalculations(context: NSManagedObjectContext) {
        let daysRequest: NSFetchRequest<Day> = Day.fetchRequest()
        
        do {
            let days = try context.fetch(daysRequest)
            for day in days {
                day.updateProgress()
            }
            
            if context.hasChanges {
                try context.save()
            }
        } catch {
            print("⚠️ Error updating progress calculations: \(error)")
        }
    }
    
    // MARK: - Error Handling
    private func handleStoreLoadError(error: NSError, storeURL: URL?) {
        print("🔄 Attempting to recover from store load error...")
        
        // First, try automatic recovery using backup system
        let recoveryResult = BackupRecoveryManager.shared.attemptRecovery()
        
        if recoveryResult.success {
            print("✅ Successfully recovered using backup system: \(recoveryResult.message)")
            
            // Try to load the store again after recovery
            container.loadPersistentStores { _, secondError in
                if let secondError = secondError {
                    print("❌ Recovery succeeded but store still won't load: \(secondError)")
                    self.fallbackRecovery(storeURL: storeURL)
                } else {
                    print("✅ Store loaded successfully after backup recovery")
                }
            }
        } else {
            print("⚠️ Backup recovery failed: \(recoveryResult.message)")
            fallbackRecovery(storeURL: storeURL)
        }
    }
    
    private func fallbackRecovery(storeURL: URL?) {
        // Last resort: remove corrupted store and recreate
        if let url = storeURL {
            do {
                try FileManager.default.removeItem(at: url)
                print("🗑️ Removed corrupted store file")
                
                // Try to load again
                container.loadPersistentStores { _, secondError in
                    if let secondError = secondError {
                        print("❌ Recovery failed: \(secondError)")
                        fatalError("Unable to recover from Core Data error: \(secondError)")
                    } else {
                        print("✅ Successfully recovered from store corruption")
                        // Reinitialize with curriculum data
                        DataInitializer.shared.initializeDataIfNeeded()
                    }
                }
            } catch {
                print("❌ Failed to remove corrupted store: \(error)")
                fatalError("Unable to recover from Core Data error: \(error)")
            }
        }
    }
    
    private func handleSaveError(error: Error, context: NSManagedObjectContext) {
        print("❌ Core Data save error: \(error)")
        
        // Rollback the context to last saved state
        context.rollback()
        print("🔄 Context rolled back to last saved state")
        
        // Log detailed error information
        if let nsError = error as NSError? {
            print("Error domain: \(nsError.domain)")
            print("Error code: \(nsError.code)")
            print("Error userInfo: \(nsError.userInfo)")
            
            // Handle specific validation errors
            if nsError.domain == NSCocoaErrorDomain {
                switch nsError.code {
                case NSValidationMissingMandatoryPropertyError:
                    print("⚠️ Missing mandatory property error")
                case NSValidationRelationshipLacksMinimumCountError:
                    print("⚠️ Relationship lacks minimum count error")
                case NSValidationRelationshipExceedsMaximumCountError:
                    print("⚠️ Relationship exceeds maximum count error")
                default:
                    print("⚠️ Other validation error: \(nsError.code)")
                }
            }
        }
    }
    
    private func validateContextObjects(_ context: NSManagedObjectContext) throws {
        // Validate all inserted objects
        for object in context.insertedObjects {
            try object.validateForInsert()
        }
        
        // Validate all updated objects
        for object in context.updatedObjects {
            try object.validateForUpdate()
        }
    }
    
    // MARK: - Automatic Save
    private func setupAutomaticSave() {
        // Save context when app goes to background
        NotificationCenter.default.addObserver(
            forName: UIApplication.willResignActiveNotification,
            object: nil,
            queue: .main
        ) { _ in
            self.save()
        }
        
        // Save context when app terminates
        NotificationCenter.default.addObserver(
            forName: UIApplication.willTerminateNotification,
            object: nil,
            queue: .main
        ) { _ in
            self.save()
        }
    }
    
    // MARK: - Utility Methods
    func deleteAllData() throws {
        let context = container.viewContext
        
        // Delete all entities in order (respecting relationships)
        let entityNames = ["DSAProblem", "SystemDesignTopic", "Day", "UserSettings"]
        
        for entityName in entityNames {
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
            
            try context.execute(deleteRequest)
        }
        
        try context.save()
        print("🗑️ All data deleted successfully")
    }
    
    func exportDatabaseURL() -> URL? {
        return documentsDirectory.appendingPathComponent("MachineMode.sqlite")
    }
}

// MARK: - Persistence Errors
enum PersistenceError: LocalizedError {
    case saveOperationFailed(Error)
    case dataCorruption(String)
    case migrationFailed(Error)
    
    var errorDescription: String? {
        switch self {
        case .saveOperationFailed(let error):
            return "Failed to save data: \(error.localizedDescription)"
        case .dataCorruption(let details):
            return "Data corruption detected: \(details)"
        case .migrationFailed(let error):
            return "Database migration failed: \(error.localizedDescription)"
        }
    }
}