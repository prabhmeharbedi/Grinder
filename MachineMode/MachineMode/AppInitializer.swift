import SwiftUI
import CoreData

@MainActor
class AppInitializer: ObservableObject {
    @Published var isInitialized = false
    @Published var initializationProgress: Double = 0.0
    @Published var currentStep = ""
    
    private var hasInitialized = false
    
    func initializeApp() {
        guard !hasInitialized else { return }
        hasInitialized = true
        
        Task {
            await performBackgroundInitialization()
        }
    }
    
    private func performBackgroundInitialization() async {
        currentStep = "Starting initialization..."
        
        await updateProgress(0.2, "Checking app version...")
        AppVersionManager.shared.checkForRebuild()
        
        await updateProgress(0.4, "Validating data...")
        let coreDataValid = await validateCoreData()
        
        if coreDataValid {
            await updateProgress(0.6, "Loading curriculum...")
            await initializeCurriculumData()
            
            await updateProgress(0.8, "Setting up backups...")
            await setupBackupSystem()
            
            await updateProgress(1.0, "Finalizing...")
            await finalizeInitialization()
        } else {
            print("❌ Core Data validation failed")
            await updateProgress(1.0, "Initialization completed with errors")
        }
        
        isInitialized = true
        LaunchOptimizer.shared.completeLaunch()
    }
    
    private func updateProgress(_ progress: Double, _ step: String) async {
        initializationProgress = progress
        currentStep = step
        print("📱 \(step) (\(Int(progress * 100))%)")
        
        try? await Task.sleep(nanoseconds: 50_000_000)
    }
    
    private func validateCoreData() async -> Bool {
        return await withCheckedContinuation { continuation in
            let context = PersistenceController.shared.container.viewContext
            context.perform {
                do {
                    let request: NSFetchRequest<Day> = Day.fetchRequest()
                    request.fetchLimit = 1
                    _ = try context.fetch(request)
                    continuation.resume(returning: true)
                } catch {
                    print("❌ Core Data validation error: \(error)")
                    continuation.resume(returning: false)
                }
            }
        }
    }
    
    private func initializeCurriculumData() async {
        await withCheckedContinuation { continuation in
            let context = PersistenceController.shared.container.viewContext
            
            let request: NSFetchRequest<Day> = Day.fetchRequest()
            
            do {
                let existingDays = try context.fetch(request)
                if existingDays.isEmpty {
                    print("📅 Creating initial curriculum data...")
                    createInitialDays(context: context)
                } else {
                    print("📅 Curriculum data already exists (\(existingDays.count) days)")
                }
            } catch {
                print("❌ Error checking existing data: \(error)")
            }
            
            continuation.resume()
        }
    }
    
    private func createInitialDays(context: NSManagedObjectContext) {
        for dayNumber in 1...100 {
            let day = Day(context: context)
            day.dayNumber = Int32(dayNumber)
            day.date = Calendar.current.date(byAdding: .day, value: dayNumber - 1, to: Date()) ?? Date()
            day.isUnlocked = dayNumber == 1
            day.dsaProgress = 0.0
            day.systemDesignProgress = 0.0
            day.isCompleted = false
            day.createdAt = Date()
            day.updatedAt = Date()
            
            let problem = DSAProblem(context: context)
            problem.problemName = "Day \(dayNumber) Problem"
            problem.difficulty = ["Easy", "Medium", "Hard"].randomElement() ?? "Medium"
            problem.isCompleted = false
            problem.timeSpent = 0
            problem.day = day
            problem.createdAt = Date()
            problem.updatedAt = Date()
            
            let topic = SystemDesignTopic(context: context)
            topic.topicName = "Day \(dayNumber) System Design"
            topic.isCompleted = false
            topic.day = day
            topic.createdAt = Date()
            topic.updatedAt = Date()
        }
        
        let settings = UserSettings(context: context)
        settings.currentStreak = 0
        settings.longestStreak = 0
        settings.morningNotificationTime = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date()) ?? Date()
        settings.eveningNotificationTime = Calendar.current.date(bySettingHour: 21, minute: 0, second: 0, of: Date()) ?? Date()
        settings.isNotificationsEnabled = true
        settings.startDate = Date()
        
        do {
            try context.save()
            print("✅ Initial curriculum data created")
        } catch {
            print("❌ Error creating initial data: \(error)")
        }
    }
    
    private func setupBackupSystem() async {
        BackupManager.shared.setupAutomaticBackup()
        
        NotificationManager.shared.requestNotificationPermission { granted in
            if granted {
                NotificationManager.shared.scheduleDailyNotifications()
            }
        }
        
        AppVersionManager.shared.scheduleRebuildWarningNotifications()
    }
    
    private func finalizeInitialization() async {
        let appStatus = AppVersionManager.shared.getAppStatusInfo()
        print("📱 App Status: \(appStatus.currentVersion)")
    }
}