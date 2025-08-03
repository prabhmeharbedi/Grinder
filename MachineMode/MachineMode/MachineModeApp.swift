import SwiftUI
import UserNotifications

@main
struct MachineModeApp: App {
    let persistenceController = PersistenceController.shared
    @StateObject private var appInitializer = AppInitializer()
    @StateObject private var errorHandler = ErrorHandler.shared
    @StateObject private var accessibilityManager = AccessibilityManager.shared
    @StateObject private var performanceMonitor = PerformanceMonitor.shared
    @StateObject private var launchOptimizer = LaunchOptimizer.shared
    
    init() {
        LaunchOptimizer.shared.startLaunchTracking()
        AppVersionManager.shared.initialize()
        
        NotificationManager.shared.requestNotificationPermission { granted in
            print(granted ? "✅ Notifications enabled" : "⚠️ Notifications disabled")
        }
        
        PerformanceMonitor.shared.startMonitoring()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environmentObject(appInitializer)
                .environmentObject(errorHandler)
                .environmentObject(accessibilityManager)
                .environmentObject(performanceMonitor)
                .environmentObject(launchOptimizer)
                .themeAware()
                .onAppear {
                    appInitializer.initializeApp()
                }
                .alert("Error Occurred", isPresented: $errorHandler.isShowingError) {
                    Button("Retry") {
                        errorHandler.retryLastOperation()
                    }
                    Button("OK") {
                        errorHandler.clearError()
                    }
                } message: {
                    if let error = errorHandler.currentError {
                        VStack {
                            Text(error.errorDescription ?? "An unexpected error occurred")
                            if let suggestion = error.recoverySuggestion {
                                Text(suggestion)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                    NotificationManager.shared.clearBadge()
                    AppVersionManager.shared.checkForRebuild()
                }
        }
    }
}