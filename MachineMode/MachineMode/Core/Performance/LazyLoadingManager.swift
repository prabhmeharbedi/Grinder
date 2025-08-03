import SwiftUI
import CoreData

class LazyLoadingManager: ObservableObject {
    static let shared = LazyLoadingManager()
    
    @Published var isInitialDataLoaded = false
    @Published var loadingProgress: Double = 0.0
    
    private let loadingSteps = 5
    private var currentStep = 0
    
    private init() {}
    
    func loadInitialData() async {
        await MainActor.run {
            loadingProgress = 0.0
            currentStep = 0
        }
        
        // Step 1: Load user settings
        await updateProgress("Loading user preferences...")
        await loadUserSettings()
        
        // Step 2: Load current day
        await updateProgress("Loading today's progress...")
        await loadCurrentDay()
        
        // Step 3: Load recent progress
        await updateProgress("Loading recent progress...")
        await loadRecentProgress()
        
        // Step 4: Setup notifications
        await updateProgress("Configuring notifications...")
        await setupNotifications()
        
        // Step 5: Final initialization
        await updateProgress("Finalizing setup...")
        await finalizeSetup()
        
        await MainActor.run {
            self.isInitialDataLoaded = true
            self.loadingProgress = 1.0
        }
    }
    
    @MainActor
    private func updateProgress(_ message: String) async {
        currentStep += 1
        loadingProgress = Double(currentStep) / Double(loadingSteps)
        print("📱 \(message) (\(currentStep)/\(loadingSteps))")
    }
    
    private func loadUserSettings() async {
        // Load essential user settings
        await MainActor.run {
            let context = PersistenceController.shared.container.viewContext
            let request: NSFetchRequest<UserSettings> = UserSettings.fetchRequest()
            
            do {
                let settings = try context.fetch(request)
                if settings.isEmpty {
                    // Create default settings if none exist
                    let newSettings = UserSettings(context: context)
                    newSettings.currentStreak = 0
                    newSettings.longestStreak = 0
                    newSettings.morningNotificationTime = Date()
                    newSettings.eveningNotificationTime = Date()
                    
                    try context.save()
                }
            } catch {
                print("❌ Error loading user settings: \(error)")
            }
        }
    }
    
    private func loadCurrentDay() async {
        await MainActor.run {
            let context = PersistenceController.shared.container.viewContext
            let currentDayNumber = UserDefaults.standard.integer(forKey: "CurrentDay")
            
            let request: NSFetchRequest<Day> = Day.fetchRequest()
            request.predicate = NSPredicate(format: "dayNumber == %d", currentDayNumber)
            request.fetchLimit = 1
            
            do {
                _ = try context.fetch(request)
            } catch {
                print("❌ Error loading current day: \(error)")
            }
        }
    }
    
    private func loadRecentProgress() async {
        await MainActor.run {
            let context = PersistenceController.shared.container.viewContext
            let request: NSFetchRequest<Day> = Day.fetchRequest()
            request.sortDescriptors = [NSSortDescriptor(keyPath: \Day.dayNumber, ascending: false)]
            request.fetchLimit = 7 // Load last 7 days
            
            do {
                _ = try context.fetch(request)
            } catch {
                print("❌ Error loading recent progress: \(error)")
            }
        }
    }
    
    private func setupNotifications() async {
        // Initialize notification manager
        NotificationManager.shared.requestNotificationPermission { granted in
            if granted {
                NotificationManager.shared.scheduleDailyNotifications()
            }
        }
    }
    
    private func finalizeSetup() async {
        // Complete any final setup tasks
        await MainActor.run {
            LaunchOptimizer.shared.completeLaunch()
        }
    }
}