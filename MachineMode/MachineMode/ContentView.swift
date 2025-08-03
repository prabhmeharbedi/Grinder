import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var appInitializer: AppInitializer
    @EnvironmentObject private var errorHandler: ErrorHandler
    @EnvironmentObject private var accessibilityManager: AccessibilityManager
    @EnvironmentObject private var performanceMonitor: PerformanceMonitor
    @Environment(\.scenePhase) private var scenePhase
    
    @State private var selectedTab = 0
    
    var body: some View {
        ZStack {
            if appInitializer.isInitialized {
                // Main app content with optimized tab view
                OptimizedTabView(selectedTab: $selectedTab)
                    .transition(.opacity.animation(.easeInOut(duration: 0.3)))
            } else {
                // Loading screen with progress
                LoadingView(
                    progress: appInitializer.initializationProgress,
                    currentStep: appInitializer.currentStep
                )
                .transition(.opacity.animation(.easeInOut(duration: 0.3)))
            }
            
            #if DEBUG
            // Performance overlay for debugging (triple tap to show/hide)
            PerformanceOverlay()
            #endif
        }
        .animation(.easeInOut(duration: 0.3), value: appInitializer.isInitialized)
        .onChange(of: scenePhase) { newPhase in
            handleScenePhaseChange(newPhase)
        }
    }
    
    private func handleScenePhaseChange(_ phase: ScenePhase) {
        switch phase {
        case .background:
            handleAppBackground()
        case .active:
            handleAppActive()
        case .inactive:
            break
        @unknown default:
            break
        }
    }
    
    private func handleAppBackground() {
        do {
            try viewContext.save()
        } catch {
            errorHandler.handle(error: .coreDataError(error), source: "ContentView.background")
        }
        
        BackupManager.shared.createBackup(format: .sqlite) { success, error in
            if !success {
                print("⚠️ Background backup failed: \(error?.localizedDescription ?? "Unknown error")")
            }
        }
        
        performanceMonitor.stopMonitoring()
    }
    
    private func handleAppActive() {
        NotificationManager.shared.clearBadge()
        AppVersionManager.shared.checkForRebuild()
        performanceMonitor.startMonitoring()
        NotificationManager.shared.scheduleDailyNotifications()
    }
}

// MARK: - Optimized Tab View
struct OptimizedTabView: View {
    @Binding var selectedTab: Int
    @EnvironmentObject private var accessibilityManager: AccessibilityManager
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Today Tab - Always loaded for immediate access
            LazyTabContent(isActive: selectedTab == 0) {
                TodayView()
            }
            .tabItem {
                Image(systemName: "calendar.badge.clock")
                Text("Today")
            }
            .tag(0)
            .accessibilityLabel("Today tab")
            .accessibilityHint("View today's problems and progress")
            
            // Progress Tab - Lazy loaded
            LazyTabContent(isActive: selectedTab == 1) {
                ProgressView()
            }
            .tabItem {
                Image(systemName: "chart.line.uptrend.xyaxis")
                Text("Progress")
            }
            .tag(1)
            .accessibilityLabel("Progress tab")
            .accessibilityHint("View overall progress and statistics")
            
            // Settings Tab - Lazy loaded
            LazyTabContent(isActive: selectedTab == 2) {
                SettingsView()
            }
            .tabItem {
                Image(systemName: "gear")
                Text("Settings")
            }
            .tag(2)
            .accessibilityLabel("Settings tab")
            .accessibilityHint("Configure app settings and preferences")
        }
        .accentColor(.adaptiveBlue)
        .animation(.easeInOut(duration: 0.2), value: selectedTab)
        .onChange(of: selectedTab) { newTab in
            let tabNames = ["Today", "Progress", "Settings"]
            if newTab < tabNames.count {
                accessibilityManager.announceForVoiceOver("\(tabNames[newTab]) tab selected")
            }
        }
    }
}

// MARK: - Lazy Tab Content
struct LazyTabContent<Content: View>: View {
    let isActive: Bool
    let content: () -> Content
    
    @State private var hasLoaded = false
    
    var body: some View {
        Group {
            if hasLoaded {
                content()
            } else if isActive {
                content()
                    .onAppear {
                        hasLoaded = true
                    }
            } else {
                // Placeholder for unloaded tabs
                Color.clear
                    .onAppear {
                        if isActive {
                            hasLoaded = true
                        }
                    }
            }
        }
    }
}

// MARK: - Loading View
struct LoadingView: View {
    let progress: Double
    let currentStep: String
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(spacing: 30) {
            // App icon or logo placeholder
            Image(systemName: "brain.head.profile")
                .font(.system(size: 80))
                .foregroundColor(.adaptiveBlue)
                .scaleEffect(1.0 + sin(Date().timeIntervalSince1970 * 2) * 0.1)
                .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: Date().timeIntervalSince1970)
                .accessibilityHidden(true)
            
            VStack(spacing: 16) {
                Text("Machine Mode")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    .accessibilityAddTraits(.isHeader)
                
                Text("Initializing your 100-day journey...")
                    .font(.headline)
                    .foregroundColor(.secondary)
                    .accessibilityLabel("Initializing your 100-day coding journey")
                
                // Progress bar
                VStack(spacing: 8) {
                    ProgressView(value: progress)
                        .progressViewStyle(LinearProgressViewStyle(tint: .adaptiveBlue))
                        .scaleEffect(x: 1, y: 2, anchor: .center)
                        .animation(.easeInOut(duration: 0.3), value: progress)
                        .accessibilityLabel("Initialization progress: \(Int(progress * 100))%")
                    
                    Text("\(Int(progress * 100))%")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                        .accessibilityHidden(true)
                }
                .frame(width: 200)
                
                Text(currentStep)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .accessibilityLabel("Current step: \(currentStep)")
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(colorScheme == .dark ? Color.black : Color.white)
        .accessibilityElement(children: .contain)
    }
}