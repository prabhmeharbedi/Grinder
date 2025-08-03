import Foundation
import CoreData
import UIKit

class BackupManager: ObservableObject {
    static let shared = BackupManager()
    
    @Published var isBackingUp = false
    @Published var lastBackupDate: Date?
    @Published var backupStatus: BackupStatus = .idle
    
    private let fileManager = FileManager.default
    private let maxBackupCount = 7 // Keep 7 days of backups
    private let backupQueue = DispatchQueue(label: "backup.queue", qos: .utility)
    
    enum BackupStatus {
        case idle
        case creating
        case success(String)
        case failed(String)
    }
    
    enum BackupFormat {
        case sqlite
        case json
        case both
    }
    
    private init() {
        loadLastBackupDate()
        setupAutomaticBackup()
    }
    
    // MARK: - Public Interface
    
    /// Sets up automatic daily backup system
    func setupAutomaticBackup() {
        // Create backup on app launch if needed
        checkAndCreateDailyBackup()
        
        // Schedule periodic backup checks
        Timer.scheduledTimer(withTimeInterval: 60 * 60, repeats: true) { _ in
            self.checkAndCreateDailyBackup()
        }
        
        // Create backup when app goes to background
        NotificationCenter.default.addObserver(
            forName: UIApplication.didEnterBackgroundNotification,
            object: nil,
            queue: .main
        ) { _ in
            self.createBackgroundBackup()
        }
        
        print("✅ Automatic backup system initialized")
    }
    
    /// Creates a manual backup with specified format
    func createManualBackup(format: BackupFormat = .both, completion: @escaping (Bool, String?) -> Void) {
        backupQueue.async {
            DispatchQueue.main.async {
                self.isBackingUp = true
                self.backupStatus = .creating
            }
            
            let timestamp = self.generateTimestamp()
            var success = true
            var errorMessage: String?
            
            do {
                switch format {
                case .sqlite:
                    try self.createSQLiteBackup(timestamp: timestamp)
                case .json:
                    try self.createJSONBackup(timestamp: timestamp)
                case .both:
                    try self.createSQLiteBackup(timestamp: timestamp)
                    try self.createJSONBackup(timestamp: timestamp)
                }
                
                self.updateLastBackupDate()
                self.cleanOldBackups()
                
                DispatchQueue.main.async {
                    self.backupStatus = .success("Manual backup created successfully")
                    print("✅ Manual backup created: \(timestamp)")
                }
                
            } catch {
                success = false
                errorMessage = error.localizedDescription
                
                DispatchQueue.main.async {
                    self.backupStatus = .failed("Backup failed: \(error.localizedDescription)")
                    print("❌ Manual backup failed: \(error)")
                }
            }
            
            DispatchQueue.main.async {
                self.isBackingUp = false
                completion(success, errorMessage)
            }
        }
    }
    
    /// Lists all available backups
    func listBackups() -> [BackupInfo] {
        do {
            let backupFiles = try fileManager.contentsOfDirectory(at: backupsDirectory, 
                                                                includingPropertiesForKeys: [.creationDateKey, .fileSizeKey],
                                                                options: [.skipsHiddenFiles])
            
            return backupFiles.compactMap { url in
                guard url.lastPathComponent.hasPrefix("MachineMode_Backup_") else { return nil }
                
                do {
                    let resourceValues = try url.resourceValues(forKeys: [.creationDateKey, .fileSizeKey])
                    let format: BackupFormat = url.pathExtension == "sqlite" ? .sqlite : .json
                    
                    return BackupInfo(
                        url: url,
                        creationDate: resourceValues.creationDate ?? Date(),
                        fileSize: resourceValues.fileSize ?? 0,
                        format: format
                    )
                } catch {
                    print("⚠️ Error reading backup file info: \(error)")
                    return nil
                }
            }.sorted { $0.creationDate > $1.creationDate }
            
        } catch {
            print("❌ Error listing backups: \(error)")
            return []
        }
    }
    
    /// Restores from a specific backup
    func restoreFromBackup(_ backupInfo: BackupInfo, completion: @escaping (Bool, String?) -> Void) {
        backupQueue.async {
            DispatchQueue.main.async {
                self.isBackingUp = true
                self.backupStatus = .creating
            }
            
            do {
                // Create a backup of current state before restore
                let preRestoreTimestamp = "PreRestore_\(self.generateTimestamp())"
                try self.createSQLiteBackup(timestamp: preRestoreTimestamp)
                
                // Perform the restore
                switch backupInfo.format {
                case .sqlite:
                    try self.restoreFromSQLiteBackup(backupInfo.url)
                case .json:
                    try self.restoreFromJSONBackup(backupInfo.url)
                case .both:
                    // For 'both', prioritize SQLite restore
                    try self.restoreFromSQLiteBackup(backupInfo.url)
                }
                
                // Verify data integrity after restore
                try self.verifyRestoredData()
                
                DispatchQueue.main.async {
                    self.backupStatus = .success("Restore completed successfully")
                    completion(true, nil)
                }
                
            } catch {
                DispatchQueue.main.async {
                    self.backupStatus = .failed("Restore failed: \(error.localizedDescription)")
                    completion(false, error.localizedDescription)
                }
            }
            
            DispatchQueue.main.async {
                self.isBackingUp = false
            }
        }
    }
    
    /// Attempts automatic recovery from the most recent backup
    func attemptAutomaticRecovery() -> Bool {
        let backups = listBackups().filter { $0.format == .sqlite }
        guard let latestBackup = backups.first else {
            print("❌ No SQLite backups available for recovery")
            return false
        }
        
        do {
            try restoreFromSQLiteBackup(latestBackup.url)
            try verifyRestoredData()
            print("✅ Automatic recovery successful from: \(latestBackup.url.lastPathComponent)")
            return true
        } catch {
            print("❌ Automatic recovery failed: \(error)")
            return false
        }
    }
    
    // MARK: - Private Implementation
    
    private func checkAndCreateDailyBackup() {
        let calendar = Calendar.current
        let now = Date()
        
        // Check if we need a daily backup
        if let lastBackup = lastBackupDate {
            if calendar.isDate(lastBackup, inSameDayAs: now) {
                return // Already backed up today
            }
        }
        
        // Create daily backup
        createDailyBackup()
    }
    
    private func createDailyBackup() {
        let timestamp = generateDailyTimestamp()
        
        backupQueue.async {
            do {
                // Check if today's backup already exists
                let sqliteBackupURL = self.backupsDirectory.appendingPathComponent("MachineMode_Backup_\(timestamp).sqlite")
                if self.fileManager.fileExists(atPath: sqliteBackupURL.path) {
                    return
                }
                
                try self.createSQLiteBackup(timestamp: timestamp)
                try self.createJSONBackup(timestamp: timestamp)
                
                self.updateLastBackupDate()
                self.cleanOldBackups()
                
                print("✅ Daily backup created: \(timestamp)")
                
            } catch {
                print("❌ Daily backup failed: \(error)")
            }
        }
    }
    
    private func createBackgroundBackup() {
        // Create a quick backup when app goes to background
        let timestamp = "Background_\(generateTimestamp())"
        
        backupQueue.async {
            do {
                try self.createSQLiteBackup(timestamp: timestamp)
                print("✅ Background backup created")
            } catch {
                print("❌ Background backup failed: \(error)")
            }
        }
    }
    
    private func createSQLiteBackup(timestamp: String) throws {
        // Ensure Core Data is saved before backup
        PersistenceController.shared.save()
        
        let sourceURL = documentsDirectory.appendingPathComponent("MachineMode.sqlite")
        let backupURL = backupsDirectory.appendingPathComponent("MachineMode_Backup_\(timestamp).sqlite")
        
        // Ensure backup directory exists
        try fileManager.createDirectory(at: backupsDirectory, withIntermediateDirectories: true)
        
        // Remove existing backup with same name
        if fileManager.fileExists(atPath: backupURL.path) {
            try fileManager.removeItem(at: backupURL)
        }
        
        // Copy the database file
        try fileManager.copyItem(at: sourceURL, to: backupURL)
        
        // Also backup the WAL and SHM files if they exist
        let walSource = sourceURL.appendingPathExtension("wal")
        let shmSource = sourceURL.appendingPathExtension("shm")
        
        if fileManager.fileExists(atPath: walSource.path) {
            let walBackup = backupURL.appendingPathExtension("wal")
            try? fileManager.copyItem(at: walSource, to: walBackup)
        }
        
        if fileManager.fileExists(atPath: shmSource.path) {
            let shmBackup = backupURL.appendingPathExtension("shm")
            try? fileManager.copyItem(at: shmSource, to: shmBackup)
        }
        
        print("✅ SQLite backup created: \(backupURL.lastPathComponent)")
    }
    
    private func createJSONBackup(timestamp: String) throws {
        let context = PersistenceController.shared.container.viewContext
        let backupURL = backupsDirectory.appendingPathComponent("MachineMode_Backup_\(timestamp).json")
        
        // Ensure backup directory exists
        try fileManager.createDirectory(at: backupsDirectory, withIntermediateDirectories: true)
        
        var backupData: [String: Any] = [:]
        backupData["timestamp"] = timestamp
        backupData["version"] = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        
        try context.performAndWait {
            // Export Days
            let daysRequest: NSFetchRequest<Day> = Day.fetchRequest()
            daysRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Day.dayNumber, ascending: true)]
            let days = try context.fetch(daysRequest)
            
            backupData["days"] = days.map { day in
                var dayData: [String: Any] = [
                    "dayNumber": day.dayNumber,
                    "date": ISO8601DateFormatter().string(from: day.date ?? Date()),
                    "dsaProgress": day.dsaProgress,
                    "systemDesignProgress": day.systemDesignProgress,
                    "isCompleted": day.isCompleted,
                    "dailyReflection": day.dailyReflection ?? "",
                    "createdAt": ISO8601DateFormatter().string(from: day.createdAt ?? Date()),
                    "updatedAt": ISO8601DateFormatter().string(from: day.updatedAt ?? Date())
                ]
                
                // Export DSA Problems
                if let dsaProblems = day.dsaProblems?.allObjects as? [DSAProblem] {
                    dayData["dsaProblems"] = dsaProblems.map { problem in
                        [
                            "problemName": problem.problemName ?? "",
                            "leetcodeNumber": problem.leetcodeNumber ?? "",
                            "isCompleted": problem.isCompleted,
                            "timeSpent": problem.timeSpent,
                            "notes": problem.notes ?? "",
                            "difficulty": problem.difficulty ?? "",
                            "isBonusProblem": problem.isBonusProblem,
                            "completedAt": problem.completedAt != nil ? ISO8601DateFormatter().string(from: problem.completedAt!) : nil,
                            "createdAt": ISO8601DateFormatter().string(from: problem.createdAt ?? Date()),
                            "updatedAt": ISO8601DateFormatter().string(from: problem.updatedAt ?? Date())
                        ]
                    }
                }
                
                // Export System Design Topics
                if let systemTopics = day.systemDesignTopics?.allObjects as? [SystemDesignTopic] {
                    dayData["systemDesignTopics"] = systemTopics.map { topic in
                        [
                            "topicName": topic.topicName ?? "",
                            "topicDescription": topic.topicDescription ?? "",
                            "isCompleted": topic.isCompleted,
                            "videoWatched": topic.videoWatched,
                            "taskCompleted": topic.taskCompleted,
                            "notes": topic.notes ?? "",
                            "completedAt": topic.completedAt != nil ? ISO8601DateFormatter().string(from: topic.completedAt!) : nil,
                            "createdAt": ISO8601DateFormatter().string(from: topic.createdAt ?? Date()),
                            "updatedAt": ISO8601DateFormatter().string(from: topic.updatedAt ?? Date())
                        ]
                    }
                }
                
                return dayData
            }
            
            // Export User Settings
            let settingsRequest: NSFetchRequest<UserSettings> = UserSettings.fetchRequest()
            if let settings = try context.fetch(settingsRequest).first {
                backupData["userSettings"] = [
                    "morningNotificationTime": ISO8601DateFormatter().string(from: settings.morningNotificationTime ?? Date()),
                    "eveningNotificationTime": ISO8601DateFormatter().string(from: settings.eveningNotificationTime ?? Date()),
                    "isNotificationsEnabled": settings.isNotificationsEnabled,
                    "currentStreak": settings.currentStreak,
                    "longestStreak": settings.longestStreak,
                    "startDate": ISO8601DateFormatter().string(from: settings.startDate ?? Date()),
                    "lastBackupDate": settings.lastBackupDate != nil ? ISO8601DateFormatter().string(from: settings.lastBackupDate!) : nil,
                    "appVersion": settings.appVersion ?? ""
                ]
            }
        }
        
        // Write JSON to file
        let jsonData = try JSONSerialization.data(withJSONObject: backupData, options: .prettyPrinted)
        try jsonData.write(to: backupURL)
        
        print("✅ JSON backup created: \(backupURL.lastPathComponent)")
    }
    
    private func restoreFromSQLiteBackup(_ backupURL: URL) throws {
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
    
    private func restoreFromJSONBackup(_ backupURL: URL) throws {
        let jsonData = try Data(contentsOf: backupURL)
        let backupData = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any]
        
        guard let backupData = backupData else {
            throw BackupError.invalidJSONFormat
        }
        
        let context = PersistenceController.shared.container.newBackgroundContext()
        
        try context.performAndWait {
            // Clear existing data
            try clearAllData(context: context)
            
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
            
            try context.save()
        }
        
        print("✅ JSON backup restored from: \(backupURL.lastPathComponent)")
    }
    
    private func verifyRestoredData() throws {
        let context = PersistenceController.shared.container.viewContext
        
        try context.performAndWait {
            // Check that we have days
            let daysRequest: NSFetchRequest<Day> = Day.fetchRequest()
            let dayCount = try context.count(for: daysRequest)
            
            if dayCount == 0 {
                throw BackupError.restoredDataEmpty
            }
            
            // Check for data consistency
            let days = try context.fetch(daysRequest)
            for day in days {
                if day.dayNumber < 1 || day.dayNumber > 100 {
                    throw BackupError.restoredDataCorrupted("Invalid day number: \(day.dayNumber)")
                }
            }
            
            print("✅ Restored data verification passed (\(dayCount) days)")
        }
    }
    
    private func cleanOldBackups() {
        let backups = listBackups()
        let backupsToDelete = backups.dropFirst(maxBackupCount)
        
        for backup in backupsToDelete {
            do {
                try fileManager.removeItem(at: backup.url)
                print("🗑️ Removed old backup: \(backup.url.lastPathComponent)")
            } catch {
                print("⚠️ Failed to remove old backup: \(error)")
            }
        }
    }
    
    private func clearAllData(context: NSManagedObjectContext) throws {
        let entityNames = ["DSAProblem", "SystemDesignTopic", "Day", "UserSettings"]
        
        for entityName in entityNames {
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
            try context.execute(deleteRequest)
        }
    }
    
    // MARK: - Utility Methods
    
    private func generateTimestamp() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        return formatter.string(from: Date())
    }
    
    private func generateDailyTimestamp() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }
    
    private func parseDate(_ dateString: String?) -> Date? {
        guard let dateString = dateString else { return nil }
        return ISO8601DateFormatter().date(from: dateString)
    }
    
    private func loadLastBackupDate() {
        lastBackupDate = UserDefaults.standard.object(forKey: "lastBackupDate") as? Date
    }
    
    private func updateLastBackupDate() {
        let now = Date()
        lastBackupDate = now
        UserDefaults.standard.set(now, forKey: "lastBackupDate")
    }
    
    private var documentsDirectory: URL {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
    }
    
    private var backupsDirectory: URL {
        documentsDirectory.appendingPathComponent("Backups")
    }
    

}

// MARK: - Supporting Types

struct BackupInfo {
    let url: URL
    let creationDate: Date
    let fileSize: Int
    let format: BackupManager.BackupFormat
    
    var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: Int64(fileSize), countStyle: .file)
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: creationDate)
    }
}

enum BackupError: LocalizedError {
    case invalidJSONFormat
    case restoredDataEmpty
    case restoredDataCorrupted(String)
    case backupDirectoryCreationFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidJSONFormat:
            return "Invalid JSON backup format"
        case .restoredDataEmpty:
            return "Restored data is empty"
        case .restoredDataCorrupted(let details):
            return "Restored data is corrupted: \(details)"
        case .backupDirectoryCreationFailed:
            return "Failed to create backup directory"
        }
    }
}