import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var appInitializer: AppInitializer
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var selectedTab = 0
    
    var body: some View {
        ZStack {
            if appInitializer.isInitialized {
                // Main app content with optimized tab view
                OptimizedTabView(selectedTab: $selectedTab)
                    .transition(.opacity.animation(.easeInOut(duration: 0.3)))
            } else {
                // Loading screen with progress
                LoadingView(progress: appInitializer.initializationProgress)
                    .transition(.opacity.animation(.easeInOut(duration: 0.3)))
            }
            
            #if DEBUG
            // Performance overlay for debugging (triple tap to show/hide)
            PerformanceOverlay()
            #endif
        }
        .animation(.easeInOut(duration: 0.3), value: appInitializer.isInitialized)
    }
}

// MARK: - Optimized Tab View
struct OptimizedTabView: View {
    @Binding var selectedTab: Int
    @Environment(\.colorScheme) private var colorScheme
    
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
            
            // Progress Tab - Lazy loaded
            LazyTabContent(isActive: selectedTab == 1) {
                ProgressView()
            }
            .tabItem {
                Image(systemName: "chart.line.uptrend.xyaxis")
                Text("Progress")
            }
            .tag(1)
            
            // Settings Tab - Lazy loaded
            LazyTabContent(isActive: selectedTab == 2) {
                SettingsView()
            }
            .tabItem {
                Image(systemName: "gear")
                Text("Settings")
            }
            .tag(2)
        }
        .accentColor(.adaptiveBlue)
        .animation(.easeInOut(duration: 0.2), value: selectedTab)
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
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(spacing: 30) {
            // App icon or logo placeholder
            Image(systemName: "brain.head.profile")
                .font(.system(size: 80))
                .foregroundColor(.adaptiveBlue)
                .scaleEffect(1.0 + sin(Date().timeIntervalSince1970 * 2) * 0.1)
                .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: Date().timeIntervalSince1970)
            
            VStack(spacing: 16) {
                Text("Machine Mode")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text("Initializing your 100-day journey...")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                // Progress bar
                VStack(spacing: 8) {
                    ProgressView(value: progress)
                        .progressViewStyle(LinearProgressViewStyle(tint: .adaptiveBlue))
                        .scaleEffect(x: 1, y: 2, anchor: .center)
                        .animation(.easeInOut(duration: 0.3), value: progress)
                    
                    Text("\(Int(progress * 100))%")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                }
                .frame(width: 200)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(colorScheme == .dark ? Color.black : Color.white)
    }
}

// MARK: - Placeholder Views for Future Implementation



struct SettingsPlaceholderView: View {
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "gear")
                    .font(.system(size: 60))
                    .foregroundColor(.gray)
                
                Text("Settings")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Coming Soon")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                Text("Configure notifications, backups, and app preferences here.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            .navigationTitle("Settings")
        }
    }
}