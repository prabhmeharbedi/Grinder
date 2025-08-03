import SwiftUI
import CoreData

struct TodayView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var accessibilityManager: AccessibilityManager
    @EnvironmentObject private var errorHandler: ErrorHandler
    @EnvironmentObject private var performanceMonitor: PerformanceMonitor
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
            .accessibilityElement(children: .contain)
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
                .accessibilityLabel("Loading")
            
            Text("Loading today's curriculum...")
                .font(.headline)
                .foregroundColor(.secondary)
                .accessibilityLabel("Loading today's curriculum data")
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 100)
        .accessibilityElement(children: .combine)
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
                    .accessibilityLabel("Day \(day.dayNumber) of 100")
                    .accessibilityAddTraits(.isHeader)
                
                Spacer()
                
                // Week theme badge
                Text(getWeekTheme(for: Int(day.dayNumber)))
                    .font(.caption)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.blue.opacity(0.1))
                    .foregroundColor(.blue)
                    .cornerRadius(12)
                    .accessibilityLabel("Week theme: \(getWeekTheme(for: Int(day.dayNumber)))")
            }
            
            // Date
            if let date = day.date {
                Text(date, style: .date)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .accessibilityLabel("Date: \(date, style: .date)")
            }
            
            // Overall completion status
            if day.isCompleted {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .accessibilityHidden(true)
                    Text("Day Completed!")
                        .font(.headline)
                        .foregroundColor(.green)
                }
                .padding(.top, 8)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Day completed successfully")
            }
        }
        .padding()
        .background(Color.cardBackground)
        .cornerRadius(16)
        .shadow(color: Color.shadowColor, radius: 8, x: 0, y: 2)
        .accessibilityElement(children: .contain)
    }
    
    // MARK: - Progress Overview
    private func progressOverviewView(day: Day) -> some View {
        VStack(spacing: 16) {
            Text("Today's Progress")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityAddTraits(.isHeader)
            
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
                .accessibilityElement(children: .combine)
                .accessibilityLabel("DSA Problems: \(day.dsaCompletionStats.completed) of \(day.dsaCompletionStats.total) completed, \(Int(day.dsaProgress * 100))%")
                
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
                .accessibilityElement(children: .combine)
                .accessibilityLabel("System Design: \(day.systemDesignCompletionStats.completed) of \(day.systemDesignCompletionStats.total) completed, \(Int(day.systemDesignProgress * 100))%")
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
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Time spent: \(formatTimeAccessible(day.totalTimeSpent))")
                
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
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Bonus problems completed: \(day.bonusProblemsCount)")
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
                
                AccessibleProgressBar(
                    current: Int(day.overallProgress * 100),
                    total: 100,
                    color: day.isCompleted ? .adaptiveGreen : .adaptiveBlue
                )
            }
        }
        .padding()
        .background(Color.cardBackground)
        .cornerRadius(16)
        .shadow(color: Color.shadowColor, radius: 8, x: 0, y: 2)
        .accessibilityElement(children: .contain)
    }
    
    // MARK: - DSA Section View
    private func dsaSectionView(day: Day) -> some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "brain.head.profile")
                    .foregroundColor(.blue)
                    .font(.title2)
                    .accessibilityHidden(true)
                
                Text("DSA Problems")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .accessibilityAddTraits(.isHeader)
                
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
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(day.dsaCompletionStats.completed) of \(day.dsaCompletionStats.total) problems completed, plus \(day.bonusProblemsCount) bonus problems")
            }
            
            // Progress details
            if day.totalTimeSpent > 0 {
                HStack {
                    Image(systemName: "clock")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .accessibilityHidden(true)
                    
                    Text("Total time: \(formatTime(day.totalTimeSpent))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Total time spent: \(formatTimeAccessible(day.totalTimeSpent))")
            }
            
            LazyVStack(spacing: 12) {
                ForEach(day.dsaProblemsArray, id: \.objectID) { problem in
                    DSAProblemRowView(problem: problem) {
                        toggleProblemCompletion(problem)
                    }
                    .onAppear {
                        day.updateProgress()
                    }
                }
            }
            
            // Add bonus problem button
            AccessibleButton("Add Bonus Problem", icon: "plus.circle", accessibilityHint: "Add an additional problem to today's list") {
                showingAddBonusProblem = true
            }
            .padding()
            .background(Color.green.opacity(0.1))
            .cornerRadius(12)
        }
        .padding()
        .background(Color.cardBackground)
        .cornerRadius(16)
        .shadow(color: Color.shadowColor, radius: 8, x: 0, y: 2)
        .accessibilityElement(children: .contain)
    }
    
    // MARK: - System Design Section View
    private func systemDesignSectionView(day: Day) -> some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "network")
                    .foregroundColor(.orange)
                    .font(.title2)
                    .accessibilityHidden(true)
                
                Text("System Design")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .accessibilityAddTraits(.isHeader)
                
                Spacer()
                
                Text("\(day.systemDesignCompletionStats.completed)/\(day.systemDesignCompletionStats.total)")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.orange)
                    .accessibilityLabel("\(day.systemDesignCompletionStats.completed) of \(day.systemDesignCompletionStats.total) system design topics completed")
            }
            
            // Progress breakdown
            let partiallyCompleted = day.systemDesignTopicsArray.filter { !$0.isCompleted && ($0.videoWatched || $0.taskCompleted) }.count
            if partiallyCompleted > 0 {
                HStack {
                    Image(systemName: "clock")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .accessibilityHidden(true)
                    
                    Text("\(partiallyCompleted) partially completed")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(partiallyCompleted) topics partially completed")
            }
            
            LazyVStack(spacing: 12) {
                ForEach(day.systemDesignTopicsArray, id: \.objectID) { topic in
                    SystemDesignTopicRowView(topic: topic)
                        .onAppear {
                            day.updateProgress()
                        }
                }
            }
        }
        .padding()
        .background(Color.cardBackground)
        .cornerRadius(16)
        .shadow(color: Color.shadowColor, radius: 8, x: 0, y: 2)
        .accessibilityElement(children: .contain)
    }
    
    // MARK: - Reflection Section View
    private func reflectionSectionView(day: Day) -> some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "lightbulb")
                    .foregroundColor(.purple)
                    .font(.title2)
                    .accessibilityHidden(true)
                
                Text("Daily Reflection")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .accessibilityAddTraits(.isHeader)
                
                Spacer()
                
                AccessibleButton("Edit", accessibilityHint: "Edit daily reflection") {
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
                    .accessibilityLabel("Daily reflection: \(reflection)")
            } else {
                Text("Add your thoughts about today's learning...")
                    .font(.body)
                    .foregroundColor(.tertiary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color.gray.opacity(0.05))
                    .cornerRadius(12)
                    .accessibilityLabel("Tap to add daily reflection")
                    .accessibilityAddTraits(.isButton)
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
        .accessibilityElement(children: .contain)
    }
    
    // MARK: - Reflection Sheet View
    private var reflectionSheetView: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Daily Reflection")
                    .font(.headline)
                    .accessibilityAddTraits(.isHeader)
                
                TextEditor(text: $reflectionText)
                    .padding(8)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    .frame(minHeight: 200)
                    .accessibilityLabel("Daily reflection text editor")
                
                Spacer()
            }
            .padding()
            .navigationTitle("Reflection")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    AccessibleButton("Cancel", accessibilityHint: "Cancel editing reflection") {
                        showingReflectionSheet = false
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    AccessibleButton("Save", accessibilityHint: "Save reflection") {
                        saveReflection()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
    
    // MARK: - Error View
    private var errorView: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 50))
                .foregroundColor(.orange)
                .accessibilityHidden(true)
            
            Text("Unable to load today's data")
                .font(.headline)
                .foregroundColor(.primary)
                .accessibilityAddTraits(.isHeader)
            
            Text("Please try refreshing or check your data initialization.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            AccessibleButton("Retry", accessibilityHint: "Retry loading today's data") {
                loadTodayData()
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 100)
        .accessibilityElement(children: .contain)
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
    
    private func formatTimeAccessible(_ minutes: Int32) -> String {
        if minutes == 0 {
            return "0 minutes"
        } else if minutes < 60 {
            return minutes == 1 ? "1 minute" : "\(minutes) minutes"
        } else {
            let hours = minutes / 60
            let remainingMinutes = minutes % 60
            let hourText = hours == 1 ? "1 hour" : "\(hours) hours"
            if remainingMinutes > 0 {
                let minText = remainingMinutes == 1 ? "1 minute" : "\(remainingMinutes) minutes"
                return "\(hourText) and \(minText)"
            } else {
                return hourText
            }
        }
    }
    
    private func getWeekTheme(for dayNumber: Int) -> String {
        let weekNumber = (dayNumber - 1) / 7 + 1
        let themes = ["Arrays", "Strings", "Linked Lists", "Trees", "Graphs", "Dynamic Programming", "Sorting", "Searching", "Backtracking", "Greedy", "Math", "Stack & Queue", "Hash Maps", "Two Pointers", "Advanced Topics"]
        return themes[(weekNumber - 1) % themes.count]
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
                errorHandler.handle(error: .coreDataError(error), source: "TodayView.getCurrentDayNumber")
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
            errorHandler.handle(error: .coreDataError(error), source: "TodayView.fetchDay")
            return nil
        }
    }
    
    private func toggleProblemCompletion(_ problem: DSAProblem) {
        do {
            problem.isCompleted.toggle()
            if problem.isCompleted {
                problem.completedAt = Date()
            } else {
                problem.completedAt = nil
            }
            problem.updatedAt = Date()
            
            try viewContext.save()
            
            let message = problem.isCompleted ? 
                "\(problem.problemName ?? "Problem") completed" : 
                "\(problem.problemName ?? "Problem") marked incomplete"
            accessibilityManager.announceForVoiceOver(message)
            
            currentDay?.updateProgress()
            
        } catch {
            errorHandler.handle(error: .coreDataError(error), source: "TodayView.toggleProblemCompletion")
        }
    }
    
    private func saveReflection() {
        guard let day = currentDay else { return }
        
        do {
            day.dailyReflection = reflectionText.isEmpty ? nil : reflectionText
            day.updatedAt = Date()
            
            try viewContext.save()
            showingReflectionSheet = false
            
            accessibilityManager.announceForVoiceOver("Reflection saved")
            
        } catch {
            errorHandler.handle(error: .coreDataError(error), source: "TodayView.saveReflection")
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

// MARK: - Extensions for Day
extension Day {
    var dsaProblemsArray: [DSAProblem] {
        return dsaProblems?.allObjects as? [DSAProblem] ?? []
    }
    
    var systemDesignTopicsArray: [SystemDesignTopic] {
        return systemDesignTopics?.allObjects as? [SystemDesignTopic] ?? []
    }
    
    var dsaCompletionStats: (completed: Int, total: Int) {
        let problems = dsaProblemsArray
        return (problems.filter { $0.isCompleted }.count, problems.count)
    }
    
    var systemDesignCompletionStats: (completed: Int, total: Int) {
        let topics = systemDesignTopicsArray
        return (topics.filter { $0.isCompleted }.count, topics.count)
    }
    
    var totalTimeSpent: Int32 {
        return dsaProblemsArray.reduce(0) { $0 + $1.timeSpent }
    }
    
    var bonusProblemsCount: Int {
        return dsaProblemsArray.filter { $0.isBonusProblem }.count
    }
    
    var overallProgress: Float {
        let dsaStats = dsaCompletionStats
        let systemStats = systemDesignCompletionStats
        let totalCompleted = dsaStats.completed + systemStats.completed
        let totalTasks = dsaStats.total + systemStats.total
        
        return totalTasks > 0 ? Float(totalCompleted) / Float(totalTasks) : 0.0
    }
    
    func updateProgress() {
        let dsaStats = dsaCompletionStats
        let systemStats = systemDesignCompletionStats
        
        dsaProgress = dsaStats.total > 0 ? Float(dsaStats.completed) / Float(dsaStats.total) : 0.0
        systemDesignProgress = systemStats.total > 0 ? Float(systemStats.completed) / Float(systemStats.total) : 0.0
        
        isCompleted = dsaProgress >= 1.0 && systemDesignProgress >= 1.0
        updatedAt = Date()
    }
}

extension UserSettings {
    var currentDayNumber: Int {
        guard let startDate = startDate else { return 1 }
        let daysPassed = Calendar.current.dateComponents([.day], from: startDate, to: Date()).day ?? 0
        return min(daysPassed + 1, 100)
    }
}