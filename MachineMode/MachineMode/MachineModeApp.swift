import SwiftUI
import UserNotifications

@main
struct MachineModeApp: App {
    let persistenceController = PersistenceController.shared
    @StateObject private var appInitializer = AppInitializer()
    
    init() {
        // Optimize app launch performance
        optimizeAppLaunch()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environmentObject(appInitializer)
                .themeAware() // Apply theme management
                .onAppear {
                    // Perform lazy initialization in background
                    appInitializer.initializeApp()
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                    // Clear notification badges when app becomes active
                    NotificationManager.shared.clearBadge()
                    
                    // Check for streak resets when app becomes active
                    NotificationManager.shared.resetStreakIfNeeded()
                }
        }
    }
    
    private func optimizeAppLaunch() {
        // Minimal initialization for fast launch
        NotificationManager.shared.requestPermission()
        
        // Pre-warm Core Data stack
        _ = persistenceController.container.viewContext
    }
}

// MARK: - App Initializer for Lazy Loading
class AppInitializer: ObservableObject {
    @Published var isInitialized = false
    @Published var initializationProgress: Double = 0.0
    
    private var hasInitialized = false
    
    func initializeApp() {
        guard !hasInitialized else { return }
        hasInitialized = true
        
        // Perform initialization in background to avoid blocking UI
        Task {
            await performBackgroundInitialization()
        }
    }
    
    @MainActor
    private func performBackgroundInitialization() async {
        // Step 1: App version management (10%)
        await updateProgress(0.1)
        AppVersionManager.shared.checkForRebuild()
        
        // Step 2: Core Data validation (20%)
        await updateProgress(0.2)
        let coreDataValid = CoreDataValidator.runAllValidations()
        
        if coreDataValid {
            // Step 3: Initialize curriculum data (40%)
            await updateProgress(0.4)
            DataInitializer.shared.initializeDataIfNeeded()
            
            // Step 4: Validate curriculum data (60%)
            await updateProgress(0.6)
            let isValid = DataInitializer.shared.validateCurriculumData()
            if isValid {
                print("✅ Curriculum data validation passed")
            } else {
                print("❌ Curriculum data validation failed")
            }
            
            // Step 5: Initialize backup system (80%)
            await updateProgress(0.8)
            BackupManager.shared.setupAutomaticBackup()
            
            // Step 6: Initialize notification system (90%)
            await updateProgress(0.9)
            NotificationManager.shared.checkNotificationStatus()
            AppVersionManager.shared.scheduleRebuildWarningNotifications()
            
            // Step 7: Background tests (100%)
            await updateProgress(1.0)
            await performBackgroundTests()
            
            // Print app status information
            let appStatus = AppVersionManager.shared.getAppStatusInfo()
            print("📱 App Status: \(appStatus.currentVersion) - \(AppVersionManager.shared.getExpirationStatusText())")
            print("📊 Data Integrity: \(appStatus.dataIntegrityStatus.description)")
        } else {
            print("❌ Core Data validation failed - app may not function correctly")
            await updateProgress(1.0)
        }
        
        isInitialized = true
    }
    
    private func updateProgress(_ progress: Double) async {
        await MainActor.run {
            initializationProgress = progress
        }
        // Small delay to prevent UI blocking
        try? await Task.sleep(nanoseconds: 10_000_000) // 10ms
    }
    
    private func performBackgroundTests() async {
        // Run tests in background without blocking UI
        Task.detached {
            BackupSystemTests.runBasicTests()
            AppVersionManagerTests.runBasicTests()
            NotificationManagerIntegrationTests.runBasicTests()
            DataInitializer.shared.printSampleData()
        }
    }
}