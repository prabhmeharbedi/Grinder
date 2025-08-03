import SwiftUI
import CoreData

struct TodayView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var todayManager = TodayManager()
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \UserSettings.startDate, ascending: true)],
        animation: .default
    )
    private var userSettings: FetchedResults<UserSettings>
    
    @State private var currentDay: Day?
    @State private var isLoading = true
    @State private var showingReflectionSheet = false
    @State private var reflectionText = ""
    @State private var showingAddBonusProblem = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    if isLoading {
                        loadingView
                    } else if let day = currentDay {
                        dayHeaderView(day: day)
                        progressOverviewView(day: day)
                        dsaSectionView(day: day)
                        systemDesignSectionView(day: day)
                        reflectionSectionView(day: day)
                    } else {
                        errorView
                    }
                }
                .padding()
            }
            .navigationTitle("Today")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                loadTodayData()
            }
            .refreshable {
                loadTodayData()
            }
            .sheet(isPresented: $showingReflectionSheet) {
                reflectionSheetView
            }
            .sheet(isPresented: $showingAddBonusProblem) {
                if let day = currentDay {
                    AddBonusProblemView(day: day)
                }
            }
        }
    }
    
    // MARK: - Loading View
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                .scaleEffect(1.5)
            
            Text("Loading today's curriculum...")
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 100)
    }
    
    // MARK: - Day Header View
    private func dayHeaderView(day: Day) -> some View {
        VStack(spacing: 12) {
            // Day counter
            HStack {
                Text("Day \(day.dayNumber)/100")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Spacer()
                
                // Week theme badge
                Text(CurriculumDataProvider.getWeekTheme(for: Int(day.dayNumber)))
                    .font(.caption)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.blue.opacity(0.1))
                    .foregroundColor(.blue)
                    .cornerRadius(12)
            }
            
            // Date
            if let date = day.date {
                Text(date, style: .date)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            // Overall completion status
            if day.isCompleted {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Day Completed!")
                        .font(.headline)
                        .foregroundColor(.green)
                }
                .padding(.top, 8)
            }
        }
        .padding()
        .background(Color.cardBackground)
        .cornerRadius(16)
        .shadow(color: Color.shadowColor, radius: 8, x: 0, y: 2)
    }
    
    // MARK: - Progress Overview
    private func progressOverviewView(day: Day) -> some View {
        VStack(spacing: 16) {
            Text("Today's Progress")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack(spacing: 20) {
                // DSA Progress
                VStack(spacing: 8) {
                    Text("DSA Problems")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    ZStack {
                        OptimizedCircularProgress(
                            progress: Double(day.dsaProgress),
                            color: .adaptiveBlue,
                            lineWidth: 8,
                            size: 80
                        )
                        
                        VStack(spacing: 2) {
                            Text("\(Int(day.dsaProgress * 100))%")
                                .font(.caption)
                                .fontWeight(.bold)
                            
                            Text("\(day.dsaCompletionStats.completed)/\(day.dsaCompletionStats.total)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Spacer()
                
                // System Design Progress
                VStack(spacing: 8) {
                    Text("System Design")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    ZStack {
                        OptimizedCircularProgress(
                            progress: Double(day.systemDesignProgress),
                            color: .adaptiveOrange,
                            lineWidth: 8,
                            size: 80
                        )
                        
                        VStack(spacing: 2) {
                            Text("\(Int(day.systemDesignProgress * 100))%")
                                .font(.caption)
                                .fontWeight(.bold)
                            
                            Text("\(day.systemDesignCompletionStats.completed)/\(day.systemDesignCompletionStats.total)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            
            // Progress details
            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Time Spent")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(formatTime(day.totalTimeSpent))
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                
                Spacer()
                
                if day.bonusProblemsCount > 0 {
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Bonus Problems")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(day.bonusProblemsCount)")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.green)
                    }
                }
            }
            
            // Overall progress bar
            VStack(spacing: 8) {
                HStack {
                    Text("Overall Progress")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    Text("\(Int(day.overallProgress * 100))%")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(day.isCompleted ? .green : .primary)
                }
                
                OptimizedProgressView(
                    value: Double(day.overallProgress),
                    color: day.isCompleted ? .adaptiveGreen : .adaptiveBlue
                )
            }
        }
        .padding()
        .background(Color.cardBackground)
        .cornerRadius(16)
        .shadow(color: Color.shadowColor, radius: 8, x: 0, y: 2)
    }
    
    // MARK: - DSA Section View
    private func dsaSectionView(day: Day) -> some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "brain.head.profile")
                    .foregroundColor(.blue)
                    .font(.title2)
                
                Text("DSA Problems")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(day.dsaCompletionStats.completed)/\(day.dsaCompletionStats.total)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.blue)
                    
                    if day.bonusProblemsCount > 0 {
                        Text("+\(day.bonusProblemsCount) bonus")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                }
            }
            
            // Progress details
            if day.totalTimeSpent > 0 {
                HStack {
                    Image(systemName: "clock")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("Total time: \(formatTime(day.totalTimeSpent))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                }
            }
            
            LazyVStack(spacing: 12) {
                ForEach(day.dsaProblemsArray, id: \.objectID) { problem in
                    OptimizedDSAProblemRowView(problem: problem)
                        .onAppear {
                            // Update day progress when problem appears
                            day.updateProgress()
                        }
                }
            }
            
            // Add bonus problem button
            Button(action: { showingAddBonusProblem = true }) {
                HStack {
                    Image(systemName: "plus.circle")
                        .foregroundColor(.green)
                    Text("Add Bonus Problem")
                        .foregroundColor(.green)
                        .fontWeight(.medium)
                    Spacer()
                }
                .padding()
                .background(Color.green.opacity(0.1))
                .cornerRadius(12)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding()
        .background(Color.cardBackground)
        .cornerRadius(16)
        .shadow(color: Color.shadowColor, radius: 8, x: 0, y: 2)
    }
    
    // MARK: - System Design Section View
    private func systemDesignSectionView(day: Day) -> some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "network")
                    .foregroundColor(.orange)
                    .font(.title2)
                
                Text("System Design")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text("\(day.systemDesignCompletionStats.completed)/\(day.systemDesignCompletionStats.total)")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.orange)
            }
            
            // Progress breakdown
            let partiallyCompleted = day.systemDesignTopicsArray.filter { !$0.isCompleted && ($0.videoWatched || $0.taskCompleted) }.count
            if partiallyCompleted > 0 {
                HStack {
                    Image(systemName: "clock")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("\(partiallyCompleted) partially completed")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                }
            }
            
            LazyVStack(spacing: 12) {
                ForEach(day.systemDesignTopicsArray, id: \.objectID) { topic in
                    OptimizedSystemDesignTopicRowView(topic: topic)
                        .onAppear {
                            // Update day progress when topic appears
                            day.updateProgress()
                        }
                }
            }
        }
        .padding()
        .background(Color.cardBackground)
        .cornerRadius(16)
        .shadow(color: Color.shadowColor, radius: 8, x: 0, y: 2)
    }
    
    // MARK: - Reflection Section View
    private func reflectionSectionView(day: Day) -> some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "lightbulb")
                    .foregroundColor(.purple)
                    .font(.title2)
                
                Text("Daily Reflection")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button("Edit") {
                    reflectionText = day.dailyReflection ?? ""
                    showingReflectionSheet = true
                }
                .font(.subheadline)
                .foregroundColor(.blue)
            }
            
            if let reflection = day.dailyReflection, !reflection.isEmpty {
                Text(reflection)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
            } else {
                Text("Add your thoughts about today's learning...")
                    .font(.body)
                    .foregroundColor(.tertiary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color.gray.opacity(0.05))
                    .cornerRadius(12)
                    .onTapGesture {
                        reflectionText = ""
                        showingReflectionSheet = true
                    }
            }
        }
        .padding()
        .background(Color.cardBackground)
        .cornerRadius(16)
        .shadow(color: Color.shadowColor, radius: 8, x: 0, y: 2)
    }
    
    // MARK: - Reflection Sheet View
    private var reflectionSheetView: some View {
        OptimizedReflectionView(
            day: currentDay,
            reflectionText: $reflectionText,
            onDismiss: { showingReflectionSheet = false }
        )
    }
    
    // MARK: - Error View
    private var errorView: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 50))
                .foregroundColor(.orange)
            
            Text("Unable to load today's data")
                .font(.headline)
                .foregroundColor(.primary)
            
            Text("Please try refreshing or check your data initialization.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Retry") {
                loadTodayData()
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 100)
    }
    
    // MARK: - Helper Methods
    private func formatTime(_ minutes: Int32) -> String {
        if minutes == 0 {
            return "0m"
        } else if minutes < 60 {
            return "\(minutes)m"
        } else {
            let hours = minutes / 60
            let remainingMinutes = minutes % 60
            return remainingMinutes > 0 ? "\(hours)h \(remainingMinutes)m" : "\(hours)h"
        }
    }
    
    private func loadTodayData() {
        isLoading = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            let currentDayNumber = getCurrentDayNumber()
            currentDay = fetchDay(for: currentDayNumber)
            isLoading = false
        }
    }
    
    private func getCurrentDayNumber() -> Int {
        if let settings = userSettings.first {
            return settings.currentDayNumber
        } else {
            // Create default user settings if none exist
            let settings = UserSettings(context: viewContext)
            settings.startDate = Date()
            settings.currentStreak = 0
            settings.longestStreak = 0
            settings.isNotificationsEnabled = true
            settings.appVersion = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
            
            do {
                try viewContext.save()
                return 1
            } catch {
                print("Error creating user settings: \(error)")
                return 1
            }
        }
    }
    
    private func fetchDay(for dayNumber: Int) -> Day? {
        let request: NSFetchRequest<Day> = Day.fetchRequest()
        request.predicate = NSPredicate(format: "dayNumber == %d", dayNumber)
        request.fetchLimit = 1
        
        do {
            let days = try viewContext.fetch(request)
            return days.first
        } catch {
            print("Error fetching day \(dayNumber): \(error)")
            return nil
        }
    }
    

}

// MARK: - Today Manager
class TodayManager: ObservableObject {
    @Published var isRefreshing = false
    
    func refreshData() {
        isRefreshing = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.isRefreshing = false
        }
    }
}

// MARK: - Preview
struct TodayView_Previews: PreviewProvider {
    static var previews: some View {
        TodayView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}