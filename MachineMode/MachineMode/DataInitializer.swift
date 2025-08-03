import Foundation
import CoreData

class DataInitializer {
    static let shared = DataInitializer()
    
    private init() {}
    
    func initializeDataIfNeeded() {
        let context = PersistenceController.shared.container.viewContext
        let request: NSFetchRequest<Day> = Day.fetchRequest()
        
        do {
            let count = try context.count(for: request)
            if count == 0 {
                print("🚀 Initializing complete 100-day curriculum...")
                initializeAllDays()
                print("✅ All 100 days initialized with complete curriculum data")
            } else {
                print("📚 Curriculum data already exists (\(count) days found)")
            }
            
            // Always check and initialize user settings
            initializeUserSettingsIfNeeded()
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
                topic.topicDescription = topicData.description
                topic.isCompleted = false
                topic.videoWatched = false
                topic.taskCompleted = false
                topic.createdAt = Date()
                topic.updatedAt = Date()
                topic.day = day
            }
            
            // Print progress every 10 days
            if dayNumber % 10 == 0 {
                print("📅 Initialized \(dayNumber)/100 days...")
            }
        }
        
        do {
            try context.save()
            print("✅ Successfully initialized all 100 days with complete curriculum")
        } catch {
            print("❌ Error saving initialized data: \(error)")
        }
    }
    
    private func initializeUserSettingsIfNeeded() {
        let context = PersistenceController.shared.container.viewContext
        let request: NSFetchRequest<UserSettings> = UserSettings.fetchRequest()
        
        do {
            let count = try context.count(for: request)
            if count == 0 {
                print("⚙️ Initializing user settings...")
                
                let userSettings = UserSettings(context: context)
                
                // Set default notification times
                let calendar = Calendar.current
                userSettings.morningNotificationTime = calendar.date(bySettingHour: 8, minute: 0, second: 0, of: Date()) ?? Date()
                userSettings.eveningNotificationTime = calendar.date(bySettingHour: 20, minute: 0, second: 0, of: Date()) ?? Date()
                
                // Enable notifications by default
                userSettings.isNotificationsEnabled = true
                
                // Initialize streak counters
                userSettings.currentStreak = 0
                userSettings.longestStreak = 0
                
                // Set start date to today
                userSettings.startDate = Date()
                
                // Set app version
                userSettings.appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
                
                try context.save()
                print("✅ User settings initialized with default values")
            } else {
                print("⚙️ User settings already exist")
            }
        } catch {
            print("❌ Error initializing user settings: \(error)")
        }
    }
    
    // Method to reinitialize data if needed (for testing or data corruption recovery)
    func reinitializeData() {
        let context = PersistenceController.shared.container.viewContext
        
        // Delete all existing data
        let dayRequest: NSFetchRequest<NSFetchRequestResult> = Day.fetchRequest()
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: dayRequest)
        
        do {
            try context.execute(deleteRequest)
            try context.save()
            print("🗑️ Cleared existing curriculum data")
            
            // Reinitialize
            initializeAllDays()
        } catch {
            print("❌ Error reinitializing data: \(error)")
        }
    }
    
    // Method to get curriculum statistics
    func getCurriculumStats() -> (totalDays: Int, totalDSAProblems: Int, totalSystemTopics: Int) {
        var totalDSAProblems = 0
        var totalSystemTopics = 0
        
        for day in 1...100 {
            totalDSAProblems += CurriculumDataProvider.getDSAProblems(for: day).count
            totalSystemTopics += CurriculumDataProvider.getSystemDesignTopics(for: day).count
        }
        
        return (totalDays: 100, totalDSAProblems: totalDSAProblems, totalSystemTopics: totalSystemTopics)
    }
    
    // MARK: - Testing and Validation Methods
    
    func validateCurriculumData() -> Bool {
        print("🔍 Validating curriculum data...")
        
        var isValid = true
        var totalProblems = 0
        var totalTopics = 0
        
        for day in 1...100 {
            let problems = CurriculumDataProvider.getDSAProblems(for: day)
            let topics = CurriculumDataProvider.getSystemDesignTopics(for: day)
            
            totalProblems += problems.count
            totalTopics += topics.count
            
            // Validate that each day has at least some content
            if problems.isEmpty && topics.isEmpty {
                print("⚠️ Day \(day) has no content")
                isValid = false
            }
            
            // Validate problem data structure
            for problem in problems {
                if problem.name.isEmpty {
                    print("⚠️ Day \(day): Problem with empty name")
                    isValid = false
                }
                if problem.difficulty.isEmpty {
                    print("⚠️ Day \(day): Problem '\(problem.name)' has no difficulty")
                    isValid = false
                }
            }
            
            // Validate topic data structure
            for topic in topics {
                if topic.name.isEmpty {
                    print("⚠️ Day \(day): Topic with empty name")
                    isValid = false
                }
            }
        }
        
        print("📊 Curriculum validation complete:")
        print("   Total DSA Problems: \(totalProblems)")
        print("   Total System Topics: \(totalTopics)")
        print("   Status: \(isValid ? "✅ Valid" : "❌ Invalid")")
        
        return isValid
    }
    
    func printSampleData() {
        print("\n📋 Sample Curriculum Data:")
        
        for day in 1...5 {
            print("\n--- Day \(day) (\(CurriculumDataProvider.getWeekTheme(for: day))) ---")
            
            let problems = CurriculumDataProvider.getDSAProblems(for: day)
            print("DSA Problems (\(problems.count)):")
            for (index, problem) in problems.enumerated() {
                print("  \(index + 1). \(problem.name) (LC \(problem.leetcodeNumber ?? "N/A")) - \(problem.difficulty)")
            }
            
            let topics = CurriculumDataProvider.getSystemDesignTopics(for: day)
            print("System Design Topics (\(topics.count)):")
            for (index, topic) in topics.enumerated() {
                print("  \(index + 1). \(topic.name)")
            }
        }
    }
}