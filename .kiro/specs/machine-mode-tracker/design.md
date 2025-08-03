# Design Document

## Overview

The Machine Mode Tracker is a comprehensive iOS application designed to support a 100-day intensive software engineering interview preparation program. The app must handle the complete curriculum from sssss.md (100 days of DSA problems and System Design topics), implement robust data persistence across 7-day rebuild cycles, and provide a seamless user experience for daily progress tracking.

The design integrates three critical components:
1. **Complete Curriculum Data**: All 100 days of DSA problems (with LeetCode numbers, difficulty levels) and System Design topics (with descriptions, tasks, and goals)
2. **Persistent Data Architecture**: Core Data implementation that survives app rebuilds every 7 days
3. **Comprehensive Feature Set**: Daily tracking, notifications, progress visualization, export functionality, and backup systems

## Architecture

### High-Level System Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    SwiftUI Views Layer                      │
│  ┌──────────────┐ ┌──────────────┐ ┌──────────────────────┐ │
│  │  Today View  │ │Progress View │ │   Settings View     │ │
│  │              │ │              │ │                     │ │
│  │- Day Counter │ │- Heat Map    │ │- Notifications      │ │
│  │- DSA Section │ │- Statistics  │ │- Backup Management  │ │
│  │- System      │ │- Charts      │ │- Export Options     │ │
│  │  Design      │ │- Streaks     │ │- App Status         │ │
│  │- Reflection  │ │              │ │                     │ │
│  └──────────────┘ └──────────────┘ └──────────────────────┘ │
├─────────────────────────────────────────────────────────────┤
│                  Business Logic Layer                      │
│  ┌──────────────┐ ┌──────────────┐ ┌──────────────────────┐ │
│  │Notification  │ │   Backup     │ │    Export           │ │
│  │  Manager     │ │   Manager    │ │    Manager          │ │
│  │              │ │              │ │                     │ │
│  │- Daily       │ │- Auto Backup │ │- Markdown Export    │ │
│  │  Reminders   │ │- Manual      │ │- JSON Export        │ │
│  │- Streak      │ │  Backup      │ │- Progress Reports   │ │
│  │  Alerts      │ │- Recovery    │ │- Share Integration  │ │
│  │- Expiration  │ │- Cleanup     │ │                     │ │
│  │  Warnings    │ │              │ │                     │ │
│  └──────────────┘ └──────────────┘ └──────────────────────┘ │
├─────────────────────────────────────────────────────────────┤
│                 Data Management Layer                      │
│  ┌──────────────┐ ┌──────────────┐ ┌──────────────────────┐ │
│  │Data          │ │App Version   │ │   Curriculum        │ │
│  │Initializer   │ │Manager       │ │   Data Provider     │ │
│  │              │ │              │ │                     │ │
│  │- 100-Day     │ │- Rebuild     │ │- DSA Problems       │ │
│  │  Curriculum  │ │  Detection   │ │- System Design      │ │
│  │- Problem     │ │- Expiration  │ │- Weekly Themes      │ │
│  │  Loading     │ │  Tracking    │ │- Difficulty Levels  │ │
│  │- Topic       │ │- Data        │ │- LeetCode Numbers   │ │
│  │  Loading     │ │  Integrity   │ │                     │ │
│  └──────────────┘ └──────────────┘ └──────────────────────┘ │
├─────────────────────────────────────────────────────────────┤
│                 Data Persistence Layer                     │
│  ┌──────────────┐ ┌──────────────┐ ┌──────────────────────┐ │
│  │  Core Data   │ │ UserDefaults │ │   File Manager      │ │
│  │   Context    │ │   Settings   │ │     Backups         │ │
│  │              │ │              │ │                     │ │
│  │- Day Entity  │ │- Notification│ │- SQLite Backups     │ │
│  │- DSAProblem  │ │  Times       │ │- JSON Exports       │ │
│  │- SystemTopic │ │- App Version │ │- Documents Storage  │ │
│  │- UserSettings│ │- Install Date│ │- Automatic Cleanup  │ │
│  │- Relationships│ │              │ │                     │ │
│  └──────────────┘ └──────────────┘ └──────────────────────┘ │
├─────────────────────────────────────────────────────────────┤
│                   Storage Layer                            │
│  ┌──────────────┐ ┌──────────────┐ ┌──────────────────────┐ │
│  │   SQLite     │ │  Property    │ │   Documents         │ │
│  │  Database    │ │    Lists     │ │   Directory         │ │
│  │              │ │              │ │                     │ │
│  │- Persistent  │ │- User Prefs  │ │- Backup Files       │ │
│  │  Across      │ │- App State   │ │- Export Files       │ │
│  │  Rebuilds    │ │- Settings    │ │- Persistent Across  │ │
│  │- ACID        │ │              │ │  Rebuilds           │ │
│  │  Properties  │ │              │ │                     │ │
│  └──────────────┘ └──────────────┘ └──────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

### Data Flow Architecture

The application follows a unidirectional data flow pattern optimized for persistence:

```
User Interaction → SwiftUI View → Core Data Context → SQLite Database (Documents Directory)
                ↓                ↓                  ↓
            UI Update ← Business Logic ← Data Persistence ← Automatic Backup
```

## Components and Interfaces

### Core Data Model

#### Day Entity
```swift
class Day: NSManagedObject {
    @NSManaged var dayNumber: Int32           // 1-100
    @NSManaged var date: Date                 // Scheduled date for this day
    @NSManaged var dsaProgress: Float         // 0.0-1.0 completion percentage
    @NSManaged var systemDesignProgress: Float // 0.0-1.0 completion percentage
    @NSManaged var isCompleted: Bool          // Overall day completion
    @NSManaged var dailyReflection: String?   // Optional user notes
    @NSManaged var createdAt: Date
    @NSManaged var updatedAt: Date
    
    // Relationships
    @NSManaged var dsaProblems: NSSet?        // To-many relationship
    @NSManaged var systemDesignTopics: NSSet? // To-many relationship
}
```

#### DSAProblem Entity
```swift
class DSAProblem: NSManagedObject {
    @NSManaged var problemName: String        // e.g., "Two Sum"
    @NSManaged var leetcodeNumber: String?    // e.g., "1"
    @NSManaged var isCompleted: Bool
    @NSManaged var timeSpent: Int32           // Minutes spent
    @NSManaged var notes: String?             // User solution notes
    @NSManaged var difficulty: String         // "Easy", "Medium", "Hard"
    @NSManaged var isBonusProblem: Bool       // User-added extra problems
    @NSManaged var completedAt: Date?         // Completion timestamp
    @NSManaged var createdAt: Date
    @NSManaged var updatedAt: Date
    
    // Relationships
    @NSManaged var day: Day                   // To-one relationship
}
```

#### SystemDesignTopic Entity
```swift
class SystemDesignTopic: NSManagedObject {
    @NSManaged var topicName: String          // e.g., "DNS & Domain Resolution"
    @NSManaged var description: String?       // Task description
    @NSManaged var isCompleted: Bool
    @NSManaged var videoWatched: Bool         // For video-based tasks
    @NSManaged var taskCompleted: Bool        // For practical tasks
    @NSManaged var notes: String?             // User insights
    @NSManaged var completedAt: Date?
    @NSManaged var createdAt: Date
    @NSManaged var updatedAt: Date
    
    // Relationships
    @NSManaged var day: Day                   // To-one relationship
}
```

#### UserSettings Entity
```swift
class UserSettings: NSManagedObject {
    @NSManaged var morningNotificationTime: Date
    @NSManaged var eveningNotificationTime: Date
    @NSManaged var isNotificationsEnabled: Bool
    @NSManaged var currentStreak: Int32
    @NSManaged var longestStreak: Int32
    @NSManaged var startDate: Date
    @NSManaged var lastBackupDate: Date?
    @NSManaged var appVersion: String
}
```

### Curriculum Data Provider

The curriculum data is structured to match the complete 100-day program from sssss.md:

```swift
struct CurriculumDataProvider {
    // Week-based organization matching sssss.md structure
    static let weeklyThemes = [
        1: "FOUNDATIONS",
        2: "SLIDING WINDOWS & HASH MAPS", 
        3: "STACKS, LINKED LISTS & RATE LIMITING",
        4: "BINARY SEARCH & RECURSION",
        5: "BACKTRACKING & TREES",
        6: "TREES ADVANCED & WHATSAPP",
        7: "GRAPHS I & YOUTUBE",
        8: "GRAPHS II & UBER",
        9: "DYNAMIC PROGRAMMING I & TWITTER",
        10: "DYNAMIC PROGRAMMING II & NOTIFICATIONS",
        11: "GREEDY & SYSTEM DESIGN REVISION",
        12: "MIXED REVISION & MOCK PREP",
        13: "MOCK WEEK 1 - PRESSURE TESTING",
        14: "MOCK WEEK 2 - FINAL PREPARATION"
    ]
    
    static func getDSAProblems(for day: Int) -> [DSAProblemData] {
        // Complete implementation of all 100 days from sssss.md
        switch day {
        case 1:
            return [
                DSAProblemData(name: "Build Array from Permutation", leetcodeNumber: "1920", difficulty: "Easy"),
                DSAProblemData(name: "Running Sum of 1d Array", leetcodeNumber: "1480", difficulty: "Easy"),
                DSAProblemData(name: "Find Numbers with Even Number of Digits", leetcodeNumber: "1295", difficulty: "Easy"),
                DSAProblemData(name: "How Many Numbers Are Smaller Than the Current Number", leetcodeNumber: "1365", difficulty: "Easy"),
                DSAProblemData(name: "Merge Sorted Array", leetcodeNumber: "88", difficulty: "Easy")
            ]
        case 2:
            return [
                DSAProblemData(name: "Move Zeroes", leetcodeNumber: "283", difficulty: "Easy"),
                DSAProblemData(name: "Two Sum II - Input Array Is Sorted", leetcodeNumber: "167", difficulty: "Easy"),
                DSAProblemData(name: "Reverse String", leetcodeNumber: "344", difficulty: "Easy"),
                DSAProblemData(name: "Remove Element", leetcodeNumber: "27", difficulty: "Easy"),
                DSAProblemData(name: "Remove Duplicates from Sorted Array", leetcodeNumber: "26", difficulty: "Easy")
            ]
        // ... Continue for all 100 days with exact data from sssss.md
        default:
            return generateProblemsForDay(day)
        }
    }
    
    static func getSystemDesignTopics(for day: Int) -> [SystemDesignTopicData] {
        // Complete implementation matching sssss.md system design topics
        switch day {
        case 1:
            return [
                SystemDesignTopicData(name: "DNS & Domain Resolution", 
                                    description: "Watch: 'DNS Explained - How Domain Name System Works' - PowerCert Animated Videos"),
                SystemDesignTopicData(name: "Draw DNS Resolution Flow", 
                                    description: "Client → Resolver → Root → TLD → Authoritative"),
                SystemDesignTopicData(name: "DNS Explanation Exercise", 
                                    description: "Write a 100-word explanation of DNS as if explaining to a child")
            ]
        case 2:
            return [
                SystemDesignTopicData(name: "Load Balancing", 
                                    description: "Watch: 'Load Balancers Explained' - Gaurav Sen"),
                SystemDesignTopicData(name: "Load Balancer Diagram", 
                                    description: "Diagram Client → Load Balancer → App Servers (Round Robin, Least Connections)"),
                SystemDesignTopicData(name: "Layer 4 vs Layer 7", 
                                    description: "Compare Layer 4 vs Layer 7 load balancing in 3 sentences")
            ]
        // ... Continue for all 100 days with exact data from sssss.md
        default:
            return generateTopicsForDay(day)
        }
    }
}
```

### Persistence Controller

```swift
struct PersistenceController {
    static let shared = PersistenceController()
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
        }
        
        container.loadPersistentStores { _, error in
            if let error = error {
                print("Core Data error: \(error)")
            }
        }
        
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }
    
    private var documentsDirectory: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    }
}
```

### Data Initialization System

```swift
class DataInitializer {
    static let shared = DataInitializer()
    
    func initializeDataIfNeeded() {
        let context = PersistenceController.shared.container.viewContext
        let request: NSFetchRequest<Day> = Day.fetchRequest()
        
        do {
            let count = try context.count(for: request)
            if count == 0 {
                print("🚀 Initializing complete 100-day curriculum...")
                initializeAllDays()
                print("✅ All 100 days initialized with complete curriculum data")
            }
        } catch {
            print("❌ Error checking existing data: \(error)")
        }
    }
    
    private func initializeAllDays() {
        let context = PersistenceController.shared.container.viewContext
        let startDate = Date()
        
        for dayNumber in 1...100 {
            let day = Day(context: context)
            day.dayNumber = Int32(dayNumber)
            day.date = Calendar.current.date(byAdding: .day, value: dayNumber - 1, to: startDate)
            day.dsaProgress = 0.0
            day.systemDesignProgress = 0.0
            day.isCompleted = false
            day.createdAt = Date()
            day.updatedAt = Date()
            
            // Load DSA problems from curriculum data
            let dsaProblems = CurriculumDataProvider.getDSAProblems(for: dayNumber)
            for problemData in dsaProblems {
                let problem = DSAProblem(context: context)
                problem.problemName = problemData.name
                problem.leetcodeNumber = problemData.leetcodeNumber
                problem.difficulty = problemData.difficulty
                problem.isCompleted = false
                problem.timeSpent = 0
                problem.isBonusProblem = false
                problem.createdAt = Date()
                problem.updatedAt = Date()
                problem.day = day
            }
            
            // Load System Design topics from curriculum data
            let systemTopics = CurriculumDataProvider.getSystemDesignTopics(for: dayNumber)
            for topicData in systemTopics {
                let topic = SystemDesignTopic(context: context)
                topic.topicName = topicData.name
                topic.description = topicData.description
                topic.isCompleted = false
                topic.videoWatched = false
                topic.taskCompleted = false
                topic.createdAt = Date()
                topic.updatedAt = Date()
                topic.day = day
            }
        }
        
        do {
            try context.save()
            print("✅ Successfully initialized all 100 days with complete curriculum")
        } catch {
            print("❌ Error saving initialized data: \(error)")
        }
    }
}
```

### Backup and Recovery System

```swift
class BackupManager: ObservableObject {
    static let shared = BackupManager()
    
    func setupAutomaticBackup() {
        // Create backup on app launch
        createDailyBackup()
        
        // Schedule periodic backups
        Timer.scheduledTimer(withTimeInterval: 24 * 60 * 60, repeats: true) { _ in
            self.createDailyBackup()
        }
    }
    
    func createDailyBackup() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let todayString = dateFormatter.string(from: Date())
        
        let backupName = "MachineMode_Backup_\(todayString).sqlite"
        let backupURL = documentsDirectory.appendingPathComponent(backupName)
        
        // Check if today's backup already exists
        if FileManager.default.fileExists(atPath: backupURL.path) {
            return
        }
        
        createBackup(named: backupName)
        createJSONBackup(named: "MachineMode_Backup_\(todayString).json")
        cleanOldBackups()
    }
    
    private func createBackup(named fileName: String) {
        let storeURL = documentsDirectory.appendingPathComponent("MachineMode.sqlite")
        let backupURL = documentsDirectory.appendingPathComponent(fileName)
        
        do {
            // Ensure Core Data is saved before backup
            PersistenceController.shared.save()
            
            // Copy the database file
            try FileManager.default.copyItem(at: storeURL, to: backupURL)
            print("✅ SQLite backup created: \(fileName)")
            
            // Update last backup date
            UserDefaults.standard.set(Date(), forKey: "lastBackupDate")
        } catch {
            print("❌ SQLite backup failed: \(error)")
        }
    }
}
```

### App Version Management

```swift
class AppVersionManager: ObservableObject {
    static let shared = AppVersionManager()
    
    func checkForRebuild() {
        let currentVersion = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        let storedVersion = UserDefaults.standard.string(forKey: "AppVersion")
        
        if storedVersion != currentVersion {
            handleNewBuild(currentVersion: currentVersion, previousVersion: storedVersion)
        }
        
        UserDefaults.standard.set(currentVersion, forKey: "AppVersion")
        
        if UserDefaults.standard.object(forKey: "InstallDate") == nil {
            UserDefaults.standard.set(Date(), forKey: "InstallDate")
        }
    }
    
    private func handleNewBuild(currentVersion: String, previousVersion: String?) {
        print("🔄 App rebuild detected!")
        print("Previous version: \(previousVersion ?? "none")")
        print("Current version: \(currentVersion)")
        
        // Create backup before proceeding
        BackupManager.shared.createManualBackup()
        
        // Verify data integrity
        verifyDataIntegrity()
        
        // Schedule rebuild success notification
        NotificationManager.shared.scheduleRebuildNotification()
    }
    
    func daysUntilExpiration() -> Int {
        guard let installDate = UserDefaults.standard.object(forKey: "InstallDate") as? Date else {
            return 7
        }
        
        let daysSinceInstall = Calendar.current.dateComponents([.day], from: installDate, to: Date()).day ?? 0
        let daysRemaining = 7 - daysSinceInstall
        
        return max(0, daysRemaining)
    }
}
```

## Data Models

### Curriculum Data Structures

```swift
struct DSAProblemData {
    let name: String
    let leetcodeNumber: String?
    let difficulty: String
    let goal: String?           // From sssss.md goal descriptions
    let weekTheme: String       // Week theme from curriculum
}

struct SystemDesignTopicData {
    let name: String
    let description: String?
    let taskType: TaskType      // Video, Diagram, Exercise, etc.
    let videoReference: String? // YouTube video references
    let weekTheme: String       // Week theme from curriculum
}

enum TaskType {
    case video(String)          // Video to watch
    case diagram(String)        // Diagram to draw
    case exercise(String)       // Exercise to complete
    case bonus(String)          // Bonus task
}
```

### Progress Tracking Models

```swift
struct DayProgress {
    let dayNumber: Int
    let date: Date
    let dsaProgress: Float
    let systemDesignProgress: Float
    let isCompleted: Bool
    let weekTheme: String
    let totalProblems: Int
    let completedProblems: Int
    let totalTopics: Int
    let completedTopics: Int
}

struct WeeklyProgress {
    let weekNumber: Int
    let theme: String
    let days: [DayProgress]
    let overallProgress: Float
    let completedDays: Int
}

struct OverallProgress {
    let totalDays: Int
    let completedDays: Int
    let currentStreak: Int
    let longestStreak: Int
    let totalDSAProblems: Int
    let completedDSAProblems: Int
    let totalSystemTopics: Int
    let completedSystemTopics: Int
    let weeklyBreakdown: [WeeklyProgress]
}
```

## Error Handling

### Data Persistence Error Handling

```swift
enum DataError: Error {
    case coreDataInitializationFailed
    case saveOperationFailed(Error)
    case fetchOperationFailed(Error)
    case backupCreationFailed(Error)
    case dataCorruption
    case migrationFailed(Error)
}

class ErrorHandler {
    static func handle(_ error: DataError) {
        switch error {
        case .coreDataInitializationFailed:
            // Attempt to recover from backup
            BackupRecoveryManager.shared.attemptRecovery()
            
        case .saveOperationFailed(let underlyingError):
            print("❌ Save failed: \(underlyingError)")
            // Rollback context and notify user
            
        case .dataCorruption:
            // Attempt recovery from most recent backup
            BackupRecoveryManager.shared.recoverFromLatestBackup()
            
        default:
            print("❌ Data error: \(error)")
        }
    }
}
```

### Backup Recovery System

```swift
class BackupRecoveryManager {
    static let shared = BackupRecoveryManager()
    
    func attemptRecovery() -> Bool {
        // Try to restore from most recent backup
        if restoreFromSQLiteBackup() {
            return true
        }
        
        // Try to restore from JSON backup
        if restoreFromJSONBackup() {
            return true
        }
        
        // Last resort: reinitialize with curriculum data
        DataInitializer.shared.initializeDataIfNeeded()
        return false
    }
    
    private func restoreFromSQLiteBackup() -> Bool {
        let backups = BackupManager.shared.listBackups()
            .filter { $0.pathExtension == "sqlite" }
            .sorted { $0.lastPathComponent > $1.lastPathComponent }
        
        guard let latestBackup = backups.first else { return false }
        
        do {
            let storeURL = documentsDirectory.appendingPathComponent("MachineMode.sqlite")
            try? FileManager.default.removeItem(at: storeURL)
            try FileManager.default.copyItem(at: latestBackup, to: storeURL)
            print("✅ Restored from backup: \(latestBackup.lastPathComponent)")
            return true
        } catch {
            print("❌ Failed to restore from backup: \(error)")
            return false
        }
    }
}
```

## Testing Strategy

### Unit Testing

```swift
class DataInitializerTests: XCTestCase {
    func testCurriculumInitialization() {
        let context = PersistenceController(inMemory: true).container.viewContext
        DataInitializer.shared.initializeDataIfNeeded()
        
        let request: NSFetchRequest<Day> = Day.fetchRequest()
        let days = try! context.fetch(request)
        
        XCTAssertEqual(days.count, 100, "Should initialize exactly 100 days")
        
        // Test Day 1 has correct DSA problems from sssss.md
        let day1 = days.first { $0.dayNumber == 1 }!
        let day1Problems = day1.dsaProblems?.allObjects as! [DSAProblem]
        
        XCTAssertEqual(day1Problems.count, 5, "Day 1 should have 5 DSA problems")
        XCTAssertTrue(day1Problems.contains { $0.problemName == "Build Array from Permutation" })
        XCTAssertTrue(day1Problems.contains { $0.leetcodeNumber == "1920" })
    }
    
    func testSystemDesignTopicsInitialization() {
        let context = PersistenceController(inMemory: true).container.viewContext
        DataInitializer.shared.initializeDataIfNeeded()
        
        let request: NSFetchRequest<Day> = Day.fetchRequest()
        let days = try! context.fetch(request)
        
        let day1 = days.first { $0.dayNumber == 1 }!
        let day1Topics = day1.systemDesignTopics?.allObjects as! [SystemDesignTopic]
        
        XCTAssertEqual(day1Topics.count, 3, "Day 1 should have 3 system design topics")
        XCTAssertTrue(day1Topics.contains { $0.topicName == "DNS & Domain Resolution" })
    }
}

class BackupManagerTests: XCTestCase {
    func testBackupCreation() {
        let expectation = self.expectation(description: "Backup created")
        
        BackupManager.shared.createManualBackup()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            let backups = BackupManager.shared.listBackups()
            XCTAssertGreaterThan(backups.count, 0, "Should create at least one backup")
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 2.0)
    }
}
```

### Integration Testing

```swift
class AppLifecycleTests: XCTestCase {
    func testRebuildDataPersistence() {
        // Simulate app rebuild by changing version
        let oldVersion = UserDefaults.standard.string(forKey: "AppVersion")
        UserDefaults.standard.set("2", forKey: "AppVersion")
        
        // Check rebuild detection
        AppVersionManager.shared.checkForRebuild()
        
        // Verify backup was created
        let backups = BackupManager.shared.listBackups()
        XCTAssertGreaterThan(backups.count, 0, "Should create backup on rebuild")
        
        // Restore original version
        if let oldVersion = oldVersion {
            UserDefaults.standard.set(oldVersion, forKey: "AppVersion")
        }
    }
}
```

This design document provides a comprehensive foundation for implementing the Machine Mode Tracker app with complete curriculum integration, robust data persistence, and all the features specified in the PRD and implementation guide.