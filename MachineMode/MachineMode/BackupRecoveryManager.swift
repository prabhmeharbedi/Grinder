import Foundation
import CoreData

class BackupRecoveryManager {
    static let shared = BackupRecoveryManager()
    
    private init() {}
    
    // MARK: - Recovery Operations
    
    /// Attempts to recover from data corruption or loss
    func attemptRecovery() -> RecoveryResult {
        print("🔄 Starting data recovery process...")
        
        // Step 1: Try to restore from most recent SQLite backup
        if let sqliteResult = restoreFromSQLiteBackup(), sqliteResult.success {
            return sqliteResult
        }
        
        // Step 2: Try to restore from JSON backup
        if let jsonResult = restoreFromJSONBackup(), jsonResult.success {
            return jsonResult
        }
        
        // Step 3: Last resort - reinitialize with curriculum data
        return reinitializeWithCurriculumData()
    }
    
    /// Verifies data integrity and attempts repair if needed
    func verifyAndRepairDataIntegrity() -> IntegrityResult {
        let context = PersistenceController.shared.container.viewContext
        var issues: [String] = []
        var repaired: [String] = []
        
        do {
            try context.performAndWait {
                // Check 1: Verify we have the expected number of days
                let daysRequest: NSFetchRequest<Day> = Day.fetchRequest()
                let dayCount = try context.count(for: daysRequest)
                
                if dayCount == 0 {
                    issues.append("No days found in database")
                    return
                }
                
                if dayCount != 100 {
                    issues.append("Expected 100 days, found \(dayCount)")
                }
                
                // Check 2: Verify day number sequence
                let days = try context.fetch(daysRequest)
                let dayNumbers = Set(days.map { Int($0.dayNumber) })
                let expectedNumbers = Set(1...100)
                
                let missingDays = expectedNumbers.subtracting(dayNumbers)
                if !missingDays.isEmpty {
                    issues.append("Missing days: \(missingDays.sorted())")
                }
                
                let extraDays = dayNumbers.subtracting(expectedNumbers)
                if !extraDays.isEmpty {
                    issues.append("Extra days found: \(extraDays.sorted())")
                }
                
                // Check 3: Verify progress values are within valid range
                for day in days {
                    if day.dsaProgress < 0.0 || day.dsaProgress > 1.0 {
                        day.dsaProgress = max(0.0, min(1.0, day.dsaProgress))
                        repaired.append("Fixed DSA progress for day \(day.dayNumber)")
                    }
                    
                    if day.systemDesignProgress < 0.0 || day.systemDesignProgress > 1.0 {
                        day.systemDesignProgress = max(0.0, min(1.0, day.systemDesignProgress))
                        repaired.append("Fixed System Design progress for day \(day.dayNumber)")
                    }
                }
                
                // Check 4: Verify relationships integrity
                for day in days {
                    // Check for orphaned DSA problems
                    if let dsaProblems = day.dsaProblems?.allObjects as? [DSAProblem] {
                        for problem in dsaProblems {
                            if problem.day != day {
                                problem.day = day
                                repaired.append("Fixed DSA problem relationship for day \(day.dayNumber)")
                            }
                        }
                    }
                    
                    // Check for orphaned System Design topics
                    if let systemTopics = day.systemDesignTopics?.allObjects as? [SystemDesignTopic] {
                        for topic in systemTopics {
                            if topic.day != day {
                                topic.day = day
                                repaired.append("Fixed System Design topic relationship for day \(day.dayNumber)")
                            }
                        }
                    }
                }
                
                // Check 5: Look for orphaned records
                let orphanedProblemsRequest: NSFetchRequest<DSAProblem> = DSAProblem.fetchRequest()
                orphanedProblemsRequest.predicate = NSPredicate(format: "day == nil")
                let orphanedProblems = try context.fetch(orphanedProblemsRequest)
                
                if !orphanedProblems.isEmpty {
                    issues.append("Found \(orphanedProblems.count) orphaned DSA problems")
                    orphanedProblems.forEach { context.delete($0) }
                    repaired.append("Removed \(orphanedProblems.count) orphaned DSA problems")
                }
                
                let orphanedTopicsRequest: NSFetchRequest<SystemDesignTopic> = SystemDesignTopic.fetchRequest()
                orphanedTopicsRequest.predicate = NSPredicate(format: "day == nil")
                let orphanedTopics = try context.fetch(orphanedTopicsRequest)
                
                if !orphanedTopics.isEmpty {
                    issues.append("Found \(orphanedTopics.count) orphaned System Design topics")
                    orphanedTopics.forEach { context.delete($0) }
                    repaired.append("Removed \(orphanedTopics.count) orphaned System Design topics")
                }
                
                // Save repairs if any were made
                if !repaired.isEmpty {
                    try context.save()
                }
            }
            
            let severity: IntegrityResult.Severity = issues.isEmpty ? .healthy : 
                                                   (issues.count <= 2 ? .minor : .major)
            
            return IntegrityResult(
                severity: severity,
                issues: issues,
                repaired: repaired,
                success: true
            )
            
        } catch {
            return IntegrityResult(
                severity: .critical,
                issues: ["Data integrity check failed: \(error.localizedDescription)"],
                repaired: repaired,
                success: false
            )
        }
    }
    
    /// Creates an emergency backup before attempting recovery
    func createEmergencyBackup() -> Bool {
        let timestamp = "Emergency_\(generateTimestamp())"
        
        var success = false
        let semaphore = DispatchSemaphore(value: 0)
        
        BackupManager.shared.createManualBackup(format: .sqlite) { result, error in
            success = result
            if let error = error {
                print("❌ Emergency backup failed: \(error)")
            } else {
                print("✅ Emergency backup created: \(timestamp)")
            }
            semaphore.signal()
        }
        
        semaphore.wait()
        return success
    }
    
    // MARK: - Private Recovery Methods
    
    private func restoreFromSQLiteBackup() -> RecoveryResult? {
        let backups = BackupManager.shared.listBackups()
            .filter { $0.format == .sqlite }
            .sorted { $0.creationDate > $1.creationDate }
        
        guard let latestBackup = backups.first else {
            return RecoveryResult(
                success: false,
                method: .sqliteBackup,
                message: "No SQLite backups available",
                backupUsed: nil
            )
        }
        
        do {
            // Create emergency backup before restore
            _ = createEmergencyBackup()
            
            // Perform restore
            try restoreFromSQLiteFile(latestBackup.url)
            
            // Verify restored data
            let integrityResult = verifyAndRepairDataIntegrity()
            
            if integrityResult.success && integrityResult.severity != .critical {
                return RecoveryResult(
                    success: true,
                    method: .sqliteBackup,
                    message: "Successfully restored from SQLite backup",
                    backupUsed: latestBackup.url.lastPathComponent
                )
            } else {
                return RecoveryResult(
                    success: false,
                    method: .sqliteBackup,
                    message: "Restored data failed integrity check",
                    backupUsed: latestBackup.url.lastPathComponent
                )
            }
            
        } catch {
            return RecoveryResult(
                success: false,
                method: .sqliteBackup,
                message: "SQLite restore failed: \(error.localizedDescription)",
                backupUsed: latestBackup.url.lastPathComponent
            )
        }
    }
    
    private func restoreFromJSONBackup() -> RecoveryResult? {
        let backups = BackupManager.shared.listBackups()
            .filter { $0.format == .json }
            .sorted { $0.creationDate > $1.creationDate }
        
        guard let latestBackup = backups.first else {
            return RecoveryResult(
                success: false,
                method: .jsonBackup,
                message: "No JSON backups available",
                backupUsed: nil
            )
        }
        
        do {
            // Create emergency backup before restore
            _ = createEmergencyBackup()
            
            // Perform restore
            try restoreFromJSONFile(latestBackup.url)
            
            // Verify restored data
            let integrityResult = verifyAndRepairDataIntegrity()
            
            if integrityResult.success && integrityResult.severity != .critical {
                return RecoveryResult(
                    success: true,
                    method: .jsonBackup,
                    message: "Successfully restored from JSON backup",
                    backupUsed: latestBackup.url.lastPathComponent
                )
            } else {
                return RecoveryResult(
                    success: false,
                    method: .jsonBackup,
                    message: "Restored data failed integrity check",
                    backupUsed: latestBackup.url.lastPathComponent
                )
            }
            
        } catch {
            return RecoveryResult(
                success: false,
                method: .jsonBackup,
                message: "JSON restore failed: \(error.localizedDescription)",
                backupUsed: latestBackup.url.lastPathComponent
            )
        }
    }
    
    private func reinitializeWithCurriculumData() -> RecoveryResult {
        do {
            // Create emergency backup of whatever data exists
            _ = createEmergencyBackup()
            
            // Clear all existing data
            try PersistenceController.shared.deleteAllData()
            
            // Reinitialize with curriculum data
            DataInitializer.shared.initializeDataIfNeeded()
            
            // Verify the reinitialized data
            let integrityResult = verifyAndRepairDataIntegrity()
            
            if integrityResult.success {
                return RecoveryResult(
                    success: true,
                    method: .curriculumReinit,
                    message: "Successfully reinitialized with curriculum data",
                    backupUsed: nil
                )
            } else {
                return RecoveryResult(
                    success: false,
                    method: .curriculumReinit,
                    message: "Reinitialization failed integrity check",
                    backupUsed: nil
                )
            }
            
        } catch {
            return RecoveryResult(
                success: false,
                method: .curriculumReinit,
                message: "Reinitialization failed: \(error.localizedDescription)",
                backupUsed: nil
            )
        }
    }
    
    private func restoreFromSQLiteFile(_ backupURL: URL) throws {
        let fileManager = FileManager.default
        let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let storeURL = documentsDirectory.appendingPathComponent("MachineMode.sqlite")
        
        // Remove current database files
        try? fileManager.removeItem(at: storeURL)
        try? fileManager.removeItem(at: storeURL.appendingPathExtension("wal"))
        try? fileManager.removeItem(at: storeURL.appendingPathExtension("shm"))
        
        // Copy backup to main location
        try fileManager.copyItem(at: backupURL, to: storeURL)
        
        // Copy WAL and SHM files if they exist
        let walBackup = backupURL.appendingPathExtension("wal")
        let shmBackup = backupURL.appendingPathExtension("shm")
        
        if fileManager.fileExists(atPath: walBackup.path) {
            try fileManager.copyItem(at: walBackup, to: storeURL.appendingPathExtension("wal"))
        }
        
        if fileManager.fileExists(atPath: shmBackup.path) {
            try fileManager.copyItem(at: shmBackup, to: storeURL.appendingPathExtension("shm"))
        }
        
        print("✅ SQLite backup restored from: \(backupURL.lastPathComponent)")
    }
    
    private func restoreFromJSONFile(_ backupURL: URL) throws {
        let jsonData = try Data(contentsOf: backupURL)
        let backupData = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any]
        
        guard let backupData = backupData else {
            throw BackupError.invalidJSONFormat
        }
        
        let context = PersistenceController.shared.container.newBackgroundContext()
        
        try context.performAndWait {
            // Clear existing data
            try clearAllData(context: context)
            
            // Restore data from JSON
            try restoreDataFromJSON(backupData, context: context)
            
            try context.save()
        }
        
        print("✅ JSON backup restored from: \(backupURL.lastPathComponent)")
    }
    
    private func clearAllData(context: NSManagedObjectContext) throws {
        let entityNames = ["DSAProblem", "SystemDesignTopic", "Day", "UserSettings"]
        
        for entityName in entityNames {
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
            try context.execute(deleteRequest)
        }
    }
    
    private func restoreDataFromJSON(_ backupData: [String: Any], context: NSManagedObjectContext) throws {
        // Restore Days and related data
        if let daysData = backupData["days"] as? [[String: Any]] {
            for dayData in daysData {
                let day = Day(context: context)
                day.dayNumber = dayData["dayNumber"] as? Int32 ?? 0
                day.date = parseDate(dayData["date"] as? String)
                day.dsaProgress = dayData["dsaProgress"] as? Float ?? 0.0
                day.systemDesignProgress = dayData["systemDesignProgress"] as? Float ?? 0.0
                day.isCompleted = dayData["isCompleted"] as? Bool ?? false
                day.dailyReflection = dayData["dailyReflection"] as? String
                day.createdAt = parseDate(dayData["createdAt"] as? String)
                day.updatedAt = parseDate(dayData["updatedAt"] as? String)
                
                // Restore DSA Problems
                if let problemsData = dayData["dsaProblems"] as? [[String: Any]] {
                    for problemData in problemsData {
                        let problem = DSAProblem(context: context)
                        problem.problemName = problemData["problemName"] as? String
                        problem.leetcodeNumber = problemData["leetcodeNumber"] as? String
                        problem.isCompleted = problemData["isCompleted"] as? Bool ?? false
                        problem.timeSpent = problemData["timeSpent"] as? Int32 ?? 0
                        problem.notes = problemData["notes"] as? String
                        problem.difficulty = problemData["difficulty"] as? String
                        problem.isBonusProblem = problemData["isBonusProblem"] as? Bool ?? false
                        problem.completedAt = parseDate(problemData["completedAt"] as? String)
                        problem.createdAt = parseDate(problemData["createdAt"] as? String)
                        problem.updatedAt = parseDate(problemData["updatedAt"] as? String)
                        problem.day = day
                    }
                }
                
                // Restore System Design Topics
                if let topicsData = dayData["systemDesignTopics"] as? [[String: Any]] {
                    for topicData in topicsData {
                        let topic = SystemDesignTopic(context: context)
                        topic.topicName = topicData["topicName"] as? String
                        topic.topicDescription = topicData["topicDescription"] as? String
                        topic.isCompleted = topicData["isCompleted"] as? Bool ?? false
                        topic.videoWatched = topicData["videoWatched"] as? Bool ?? false
                        topic.taskCompleted = topicData["taskCompleted"] as? Bool ?? false
                        topic.notes = topicData["notes"] as? String
                        topic.completedAt = parseDate(topicData["completedAt"] as? String)
                        topic.createdAt = parseDate(topicData["createdAt"] as? String)
                        topic.updatedAt = parseDate(topicData["updatedAt"] as? String)
                        topic.day = day
                    }
                }
            }
        }
        
        // Restore User Settings
        if let settingsData = backupData["userSettings"] as? [String: Any] {
            let settings = UserSettings(context: context)
            settings.morningNotificationTime = parseDate(settingsData["morningNotificationTime"] as? String)
            settings.eveningNotificationTime = parseDate(settingsData["eveningNotificationTime"] as? String)
            settings.isNotificationsEnabled = settingsData["isNotificationsEnabled"] as? Bool ?? true
            settings.currentStreak = settingsData["currentStreak"] as? Int32 ?? 0
            settings.longestStreak = settingsData["longestStreak"] as? Int32 ?? 0
            settings.startDate = parseDate(settingsData["startDate"] as? String)
            settings.lastBackupDate = parseDate(settingsData["lastBackupDate"] as? String)
            settings.appVersion = settingsData["appVersion"] as? String ?? ""
        }
    }
    
    // MARK: - Utility Methods
    
    private func generateTimestamp() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        return formatter.string(from: Date())
    }
    
    private func parseDate(_ dateString: String?) -> Date? {
        guard let dateString = dateString else { return nil }
        return ISO8601DateFormatter().date(from: dateString)
    }
}

// MARK: - Supporting Types

struct RecoveryResult {
    let success: Bool
    let method: RecoveryMethod
    let message: String
    let backupUsed: String?
    
    enum RecoveryMethod {
        case sqliteBackup
        case jsonBackup
        case curriculumReinit
    }
}

struct IntegrityResult {
    let severity: Severity
    let issues: [String]
    let repaired: [String]
    let success: Bool
    
    enum Severity {
        case healthy
        case minor
        case major
        case critical
        
        var description: String {
            switch self {
            case .healthy: return "Healthy"
            case .minor: return "Minor Issues"
            case .major: return "Major Issues"
            case .critical: return "Critical Issues"
            }
        }
    }
}