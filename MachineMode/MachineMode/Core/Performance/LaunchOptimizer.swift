import SwiftUI
import CoreData

class LaunchOptimizer: ObservableObject {
    static let shared = LaunchOptimizer()
    
    @Published var isLaunchComplete = false
    @Published var launchTime: TimeInterval = 0
    
    private var launchStartTime: CFAbsoluteTime = 0
    private var launchEndTime: CFAbsoluteTime = 0
    
    private init() {}
    
    func startLaunchTracking() {
        launchStartTime = CFAbsoluteTimeGetCurrent()
        print("🚀 Launch tracking started at: \(launchStartTime)")
    }
    
    func completeLaunch() {
        launchEndTime = CFAbsoluteTimeGetCurrent()
        launchTime = launchEndTime - launchStartTime
        isLaunchComplete = true
        
        print("✅ Launch completed in: \(String(format: "%.3f", launchTime))s")
        
        // Log performance metrics
        logLaunchMetrics()
        
        // Warn if launch time exceeds 2 seconds
        if launchTime > 2.0 {
            print("⚠️ Launch time exceeded 2 seconds: \(String(format: "%.3f", launchTime))s")
        }
    }
    
    private func logLaunchMetrics() {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        
        let launchData = [
            "timestamp": formatter.string(from: Date()),
            "launchTime": String(format: "%.3f", launchTime),
            "deviceModel": UIDevice.current.model,
            "systemVersion": UIDevice.current.systemVersion
        ]
        
        // Store launch metrics for analysis
        UserDefaults.standard.set(launchData, forKey: "LastLaunchMetrics")
    }
    
    // MARK: - Lazy Loading Helpers
    
    func preloadCriticalData() async {
        await withTaskGroup(of: Void.self) { group in
            // Preload user settings
            group.addTask {
                await self.preloadUserSettings()
            }
            
            // Preload current day data
            group.addTask {
                await self.preloadCurrentDayData()
            }
            
            // Preload theme preferences
            group.addTask {
                await self.preloadThemePreferences()
            }
        }
    }
    
    @MainActor
    private func preloadUserSettings() async {
        // Preload essential user settings
        let context = PersistenceController.shared.container.viewContext
        let request: NSFetchRequest<UserSettings> = UserSettings.fetchRequest()
        request.fetchLimit = 1
        
        do {
            _ = try context.fetch(request)
        } catch {
            print("⚠️ Failed to preload user settings: \(error)")
        }
    }
    
    @MainActor
    private func preloadCurrentDayData() async {
        // Preload current day to show immediately
        let context = PersistenceController.shared.container.viewContext
        let request: NSFetchRequest<Day> = Day.fetchRequest()
        request.predicate = NSPredicate(format: "dayNumber == %d", UserDefaults.standard.integer(forKey: "CurrentDay"))
        request.fetchLimit = 1
        
        do {
            _ = try context.fetch(request)
        } catch {
            print("⚠️ Failed to preload current day: \(error)")
        }
    }
    
    private func preloadThemePreferences() async {
        // Ensure theme is loaded quickly
        _ = ThemeManager.shared.currentTheme
    }
}