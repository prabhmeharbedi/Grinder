import SwiftUI
import CoreData

struct ProgressView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Day.dayNumber, ascending: true)],
        animation: .default
    )
    private var days: FetchedResults<Day>
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \UserSettings.startDate, ascending: true)],
        animation: .default
    )
    private var userSettings: FetchedResults<UserSettings>
    
    @State private var selectedTimeframe: TimeFrame = .all
    @State private var showingDetailSheet = false
    @State private var selectedWeek: Int?
    
    enum TimeFrame: String, CaseIterable {
        case week = "Week"
        case month = "Month"
        case all = "All"
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Overall Progress Section
                    overallProgressSection
                    
                    // DSA vs System Design Split
                    dsaSystemSplitSection
                    
                    // Weekly Heat Map
                    weeklyHeatMapSection
                    
                    // Problem Difficulty Distribution
                    difficultyDistributionSection
                    
                    // Current Streak and Achievements
                    streakAchievementsSection
                    
                    // Weekly Progress Breakdown
                    weeklyBreakdownSection
                }
                .padding()
            }
            .navigationTitle("Progress")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        ForEach(TimeFrame.allCases, id: \.self) { timeframe in
                            Button(timeframe.rawValue) {
                                selectedTimeframe = timeframe
                            }
                        }
                    } label: {
                        Image(systemName: "slider.horizontal.3")
                    }
                }
            }
            .sheet(isPresented: $showingDetailSheet) {
                if let week = selectedWeek {
                    WeekDetailView(weekNumber: week)
                }
            }
        }
    }
    
    // MARK: - Overall Progress Section
    private var overallProgressSection: some View {
        VStack(spacing: 16) {
            Text("Overall Progress")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            let overallStats = calculateOverallStats()
            
            // Main progress circle
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 12)
                    .frame(width: 150, height: 150)
                
                Circle()
                    .trim(from: 0, to: CGFloat(overallStats.completionPercentage))
                    .stroke(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )
                    .frame(width: 150, height: 150)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 1.0), value: overallStats.completionPercentage)
                
                VStack(spacing: 4) {
                    Text("\(Int(overallStats.completionPercentage * 100))%")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Complete")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Progress details
            HStack(spacing: 30) {
                VStack(spacing: 4) {
                    Text("\(overallStats.completedDays)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                    Text("Days Done")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                VStack(spacing: 4) {
                    Text("\(100 - overallStats.completedDays)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.orange)
                    Text("Days Left")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                VStack(spacing: 4) {
                    Text("\(overallStats.currentDay)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                    Text("Current Day")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
    
    // MARK: - DSA vs System Design Split
    private var dsaSystemSplitSection: some View {
        VStack(spacing: 16) {
            Text("DSA vs System Design")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            let splitStats = calculateSplitStats()
            
            HStack(spacing: 20) {
                // DSA Progress
                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .stroke(Color.blue.opacity(0.2), lineWidth: 10)
                            .frame(width: 100, height: 100)
                        
                        Circle()
                            .trim(from: 0, to: CGFloat(splitStats.dsaPercentage))
                            .stroke(Color.blue, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                            .frame(width: 100, height: 100)
                            .rotationEffect(.degrees(-90))
                            .animation(.easeInOut(duration: 0.8), value: splitStats.dsaPercentage)
                        
                        VStack(spacing: 2) {
                            Text("\(Int(splitStats.dsaPercentage * 100))%")
                                .font(.headline)
                                .fontWeight(.bold)
                            Text("DSA")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                    }
                    
                    VStack(spacing: 4) {
                        Text("\(splitStats.dsaCompleted)/\(splitStats.dsaTotal)")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Text("Problems")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // System Design Progress
                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .stroke(Color.orange.opacity(0.2), lineWidth: 10)
                            .frame(width: 100, height: 100)
                        
                        Circle()
                            .trim(from: 0, to: CGFloat(splitStats.systemPercentage))
                            .stroke(Color.orange, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                            .frame(width: 100, height: 100)
                            .rotationEffect(.degrees(-90))
                            .animation(.easeInOut(duration: 0.8), value: splitStats.systemPercentage)
                        
                        VStack(spacing: 2) {
                            Text("\(Int(splitStats.systemPercentage * 100))%")
                                .font(.headline)
                                .fontWeight(.bold)
                            Text("System")
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                    }
                    
                    VStack(spacing: 4) {
                        Text("\(splitStats.systemCompleted)/\(splitStats.systemTotal)")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Text("Topics")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            // Combined progress bar
            VStack(spacing: 8) {
                HStack {
                    Text("Combined Progress")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    Text("\(Int((splitStats.dsaPercentage + splitStats.systemPercentage) / 2 * 100))%")
                        .font(.subheadline)
                        .fontWeight(.bold)
                }
                
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 8)
                            .cornerRadius(4)
                        
                        HStack(spacing: 0) {
                            Rectangle()
                                .fill(Color.blue)
                                .frame(width: geometry.size.width * CGFloat(splitStats.dsaPercentage) / 2, height: 8)
                            
                            Rectangle()
                                .fill(Color.orange)
                                .frame(width: geometry.size.width * CGFloat(splitStats.systemPercentage) / 2, height: 8)
                        }
                        .cornerRadius(4)
                        .animation(.easeInOut(duration: 0.8), value: splitStats.dsaPercentage)
                        .animation(.easeInOut(duration: 0.8), value: splitStats.systemPercentage)
                    }
                }
                .frame(height: 8)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
    
    // MARK: - Weekly Heat Map
    private var weeklyHeatMapSection: some View {
        VStack(spacing: 16) {
            Text("Weekly Consistency")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            let heatMapData = generateHeatMapData()
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 7), spacing: 4) {
                // Day labels
                ForEach(["S", "M", "T", "W", "T", "F", "S"], id: \.self) { day in
                    Text(day)
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                        .frame(width: 30, height: 20)
                }
                
                // Heat map cells
                ForEach(heatMapData, id: \.day) { data in
                    Rectangle()
                        .fill(heatMapColor(for: data.completionLevel))
                        .frame(width: 30, height: 30)
                        .cornerRadius(6)
                        .overlay(
                            Text("\(data.day)")
                                .font(.caption2)
                                .fontWeight(.medium)
                                .foregroundColor(data.completionLevel > 0.5 ? .white : .primary)
                        )
                        .onTapGesture {
                            // Show day detail
                        }
                }
            }
            
            // Legend
            HStack {
                Text("Less")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack(spacing: 2) {
                    ForEach(0..<5) { level in
                        Rectangle()
                            .fill(heatMapColor(for: Double(level) / 4.0))
                            .frame(width: 12, height: 12)
                            .cornerRadius(2)
                    }
                }
                
                Text("More")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
    
    // MARK: - Problem Difficulty Distribution
    private var difficultyDistributionSection: some View {
        VStack(spacing: 16) {
            Text("Problem Difficulty Distribution")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            let difficultyStats = calculateDifficultyStats()
            
            // Chart placeholder - will be implemented with actual chart
            VStack(spacing: 12) {
                ForEach(difficultyStats, id: \.difficulty) { stat in
                    HStack {
                        Circle()
                            .fill(difficultyColor(for: stat.difficulty))
                            .frame(width: 12, height: 12)
                        
                        Text(stat.difficulty)
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Spacer()
                        
                        Text("\(stat.completed)/\(stat.total)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Text("(\(Int(stat.percentage * 100))%)")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(difficultyColor(for: stat.difficulty))
                    }
                    
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            Rectangle()
                                .fill(Color.gray.opacity(0.2))
                                .frame(height: 6)
                                .cornerRadius(3)
                            
                            Rectangle()
                                .fill(difficultyColor(for: stat.difficulty))
                                .frame(width: geometry.size.width * CGFloat(stat.percentage), height: 6)
                                .cornerRadius(3)
                                .animation(.easeInOut(duration: 0.8), value: stat.percentage)
                        }
                    }
                    .frame(height: 6)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
    
    // MARK: - Streak and Achievements
    private var streakAchievementsSection: some View {
        VStack(spacing: 16) {
            Text("Streaks & Achievements")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            let streakData = getStreakData()
            
            HStack(spacing: 20) {
                // Current Streak
                VStack(spacing: 8) {
                    Image(systemName: "flame.fill")
                        .font(.title)
                        .foregroundColor(.orange)
                    
                    Text("\(streakData.currentStreak)")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.orange)
                    
                    Text("Current Streak")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color.orange.opacity(0.1))
                .cornerRadius(12)
                
                Spacer()
                
                // Longest Streak
                VStack(spacing: 8) {
                    Image(systemName: "trophy.fill")
                        .font(.title)
                        .foregroundColor(.yellow)
                    
                    Text("\(streakData.longestStreak)")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.yellow)
                    
                    Text("Best Streak")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color.yellow.opacity(0.1))
                .cornerRadius(12)
            }
            
            // Achievement Badges
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 12) {
                ForEach(getAchievements(), id: \.title) { achievement in
                    VStack(spacing: 6) {
                        Image(systemName: achievement.icon)
                            .font(.title2)
                            .foregroundColor(achievement.isUnlocked ? achievement.color : .gray)
                        
                        Text(achievement.title)
                            .font(.caption)
                            .fontWeight(.medium)
                            .multilineTextAlignment(.center)
                            .foregroundColor(achievement.isUnlocked ? .primary : .secondary)
                    }
                    .padding(8)
                    .background(achievement.isUnlocked ? achievement.color.opacity(0.1) : Color.gray.opacity(0.1))
                    .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
    
    // MARK: - Weekly Breakdown
    private var weeklyBreakdownSection: some View {
        VStack(spacing: 16) {
            Text("Weekly Progress")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            let weeklyData = generateWeeklyData()
            
            LazyVStack(spacing: 12) {
                ForEach(weeklyData, id: \.weekNumber) { week in
                    WeekProgressRow(week: week) {
                        selectedWeek = week.weekNumber
                        showingDetailSheet = true
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}
// 
MARK: - Helper Methods and Data Structures

extension ProgressView {
    
    // MARK: - Data Structures
    struct OverallStats {
        let completionPercentage: Double
        let completedDays: Int
        let currentDay: Int
        let totalProblems: Int
        let completedProblems: Int
        let totalTopics: Int
        let completedTopics: Int
    }
    
    struct SplitStats {
        let dsaPercentage: Double
        let systemPercentage: Double
        let dsaCompleted: Int
        let dsaTotal: Int
        let systemCompleted: Int
        let systemTotal: Int
    }
    
    struct HeatMapData {
        let day: Int
        let completionLevel: Double // 0.0 to 1.0
        let date: Date
    }
    
    struct DifficultyStats {
        let difficulty: String
        let completed: Int
        let total: Int
        let percentage: Double
    }
    
    struct StreakData {
        let currentStreak: Int
        let longestStreak: Int
    }
    
    struct Achievement {
        let title: String
        let icon: String
        let color: Color
        let isUnlocked: Bool
        let description: String
    }
    
    struct WeekData {
        let weekNumber: Int
        let theme: String
        let completionPercentage: Double
        let completedDays: Int
        let totalDays: Int
        let dsaProgress: Double
        let systemProgress: Double
    }
    
    // MARK: - Calculation Methods
    
    private func calculateOverallStats() -> OverallStats {
        let completedDays = days.filter { $0.isCompleted }.count
        let currentDay = getCurrentDayNumber()
        
        let totalProblems = days.reduce(0) { total, day in
            total + day.dsaProblemsArray.count
        }
        
        let completedProblems = days.reduce(0) { total, day in
            total + day.dsaProblemsArray.filter { $0.isCompleted }.count
        }
        
        let totalTopics = days.reduce(0) { total, day in
            total + day.systemDesignTopicsArray.count
        }
        
        let completedTopics = days.reduce(0) { total, day in
            total + day.systemDesignTopicsArray.filter { $0.isCompleted }.count
        }
        
        let completionPercentage = Double(completedDays) / 100.0
        
        return OverallStats(
            completionPercentage: completionPercentage,
            completedDays: completedDays,
            currentDay: currentDay,
            totalProblems: totalProblems,
            completedProblems: completedProblems,
            totalTopics: totalTopics,
            completedTopics: completedTopics
        )
    }
    
    private func calculateSplitStats() -> SplitStats {
        let dsaTotal = days.reduce(0) { total, day in
            total + day.dsaProblemsArray.count
        }
        
        let dsaCompleted = days.reduce(0) { total, day in
            total + day.dsaProblemsArray.filter { $0.isCompleted }.count
        }
        
        let systemTotal = days.reduce(0) { total, day in
            total + day.systemDesignTopicsArray.count
        }
        
        let systemCompleted = days.reduce(0) { total, day in
            total + day.systemDesignTopicsArray.filter { $0.isCompleted }.count
        }
        
        let dsaPercentage = dsaTotal > 0 ? Double(dsaCompleted) / Double(dsaTotal) : 0.0
        let systemPercentage = systemTotal > 0 ? Double(systemCompleted) / Double(systemTotal) : 0.0
        
        return SplitStats(
            dsaPercentage: dsaPercentage,
            systemPercentage: systemPercentage,
            dsaCompleted: dsaCompleted,
            dsaTotal: dsaTotal,
            systemCompleted: systemCompleted,
            systemTotal: systemTotal
        )
    }
    
    private func generateHeatMapData() -> [HeatMapData] {
        let calendar = Calendar.current
        let today = Date()
        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: today)?.start ?? today
        
        var heatMapData: [HeatMapData] = []
        
        // Generate data for the last 8 weeks (56 days)
        for weekOffset in 0..<8 {
            for dayOffset in 0..<7 {
                let date = calendar.date(byAdding: .day, value: -(56 - (weekOffset * 7 + dayOffset)), to: today) ?? today
                let dayNumber = getDayNumberForDate(date)
                
                let completionLevel: Double
                if let day = days.first(where: { $0.dayNumber == dayNumber }) {
                    completionLevel = Double(day.overallProgress)
                } else {
                    completionLevel = 0.0
                }
                
                heatMapData.append(HeatMapData(
                    day: calendar.component(.day, from: date),
                    completionLevel: completionLevel,
                    date: date
                ))
            }
        }
        
        return heatMapData
    }
    
    private func calculateDifficultyStats() -> [DifficultyStats] {
        var easyTotal = 0, easyCompleted = 0
        var mediumTotal = 0, mediumCompleted = 0
        var hardTotal = 0, hardCompleted = 0
        
        for day in days {
            for problem in day.dsaProblemsArray {
                switch problem.difficulty {
                case "Easy":
                    easyTotal += 1
                    if problem.isCompleted { easyCompleted += 1 }
                case "Medium":
                    mediumTotal += 1
                    if problem.isCompleted { mediumCompleted += 1 }
                case "Hard":
                    hardTotal += 1
                    if problem.isCompleted { hardCompleted += 1 }
                default:
                    break
                }
            }
        }
        
        return [
            DifficultyStats(
                difficulty: "Easy",
                completed: easyCompleted,
                total: easyTotal,
                percentage: easyTotal > 0 ? Double(easyCompleted) / Double(easyTotal) : 0.0
            ),
            DifficultyStats(
                difficulty: "Medium",
                completed: mediumCompleted,
                total: mediumTotal,
                percentage: mediumTotal > 0 ? Double(mediumCompleted) / Double(mediumTotal) : 0.0
            ),
            DifficultyStats(
                difficulty: "Hard",
                completed: hardCompleted,
                total: hardTotal,
                percentage: hardTotal > 0 ? Double(hardCompleted) / Double(hardTotal) : 0.0
            )
        ]
    }
    
    private func getStreakData() -> StreakData {
        if let settings = userSettings.first {
            return StreakData(
                currentStreak: Int(settings.currentStreak),
                longestStreak: Int(settings.longestStreak)
            )
        }
        return StreakData(currentStreak: 0, longestStreak: 0)
    }
    
    private func getAchievements() -> [Achievement] {
        let stats = calculateOverallStats()
        let streakData = getStreakData()
        
        return [
            Achievement(
                title: "First Steps",
                icon: "star.fill",
                color: .blue,
                isUnlocked: stats.completedDays >= 1,
                description: "Complete your first day"
            ),
            Achievement(
                title: "Week Warrior",
                icon: "calendar.badge.checkmark",
                color: .green,
                isUnlocked: stats.completedDays >= 7,
                description: "Complete 7 days"
            ),
            Achievement(
                title: "Month Master",
                icon: "crown.fill",
                color: .yellow,
                isUnlocked: stats.completedDays >= 30,
                description: "Complete 30 days"
            ),
            Achievement(
                title: "Streak Starter",
                icon: "flame.fill",
                color: .orange,
                isUnlocked: streakData.currentStreak >= 3,
                description: "3-day streak"
            ),
            Achievement(
                title: "Consistency King",
                icon: "bolt.fill",
                color: .purple,
                isUnlocked: streakData.longestStreak >= 10,
                description: "10-day streak"
            ),
            Achievement(
                title: "Problem Solver",
                icon: "brain.head.profile",
                color: .indigo,
                isUnlocked: stats.completedProblems >= 100,
                description: "Solve 100 problems"
            )
        ]
    }
    
    private func generateWeeklyData() -> [WeekData] {
        var weeklyData: [WeekData] = []
        
        for weekNumber in 1...14 {
            let startDay = (weekNumber - 1) * 7 + 1
            let endDay = min(weekNumber * 7, 100)
            
            let weekDays = days.filter { day in
                let dayNum = Int(day.dayNumber)
                return dayNum >= startDay && dayNum <= endDay
            }
            
            let completedDays = weekDays.filter { $0.isCompleted }.count
            let totalDays = weekDays.count
            
            let dsaProgress = weekDays.isEmpty ? 0.0 : weekDays.reduce(0.0) { $0 + Double($1.dsaProgress) } / Double(weekDays.count)
            let systemProgress = weekDays.isEmpty ? 0.0 : weekDays.reduce(0.0) { $0 + Double($1.systemDesignProgress) } / Double(weekDays.count)
            
            let completionPercentage = totalDays > 0 ? Double(completedDays) / Double(totalDays) : 0.0
            
            weeklyData.append(WeekData(
                weekNumber: weekNumber,
                theme: CurriculumDataProvider.weeklyThemes[weekNumber] ?? "UNKNOWN",
                completionPercentage: completionPercentage,
                completedDays: completedDays,
                totalDays: totalDays,
                dsaProgress: dsaProgress,
                systemProgress: systemProgress
            ))
        }
        
        return weeklyData
    }
    
    // MARK: - Helper Functions
    
    private func getCurrentDayNumber() -> Int {
        if let settings = userSettings.first {
            return settings.currentDayNumber
        }
        return 1
    }
    
    private func getDayNumberForDate(_ date: Date) -> Int32 {
        guard let settings = userSettings.first,
              let startDate = settings.startDate else {
            return 1
        }
        
        let daysSinceStart = Calendar.current.dateComponents([.day], from: startDate, to: date).day ?? 0
        return Int32(max(1, min(100, daysSinceStart + 1)))
    }
    
    private func heatMapColor(for completionLevel: Double) -> Color {
        switch completionLevel {
        case 0.0:
            return Color.gray.opacity(0.1)
        case 0.01..<0.25:
            return Color.green.opacity(0.3)
        case 0.25..<0.5:
            return Color.green.opacity(0.5)
        case 0.5..<0.75:
            return Color.green.opacity(0.7)
        case 0.75..<1.0:
            return Color.green.opacity(0.9)
        default:
            return Color.green
        }
    }
    
    private func difficultyColor(for difficulty: String) -> Color {
        switch difficulty {
        case "Easy":
            return .green
        case "Medium":
            return .orange
        case "Hard":
            return .red
        default:
            return .gray
        }
    }
}

// MARK: - Week Progress Row Component

struct WeekProgressRow: View {
    let week: ProgressView.WeekData
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Week number and theme
                VStack(alignment: .leading, spacing: 4) {
                    Text("Week \(week.weekNumber)")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text(week.theme)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                // Progress indicators
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(week.completedDays)/\(week.totalDays) days")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    HStack(spacing: 8) {
                        // DSA progress
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 8, height: 8)
                            .opacity(week.dsaProgress)
                        
                        // System progress
                        Circle()
                            .fill(Color.orange)
                            .frame(width: 8, height: 8)
                            .opacity(week.systemProgress)
                        
                        Text("\(Int(week.completionPercentage * 100))%")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                    }
                }
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Week Detail View

struct WeekDetailView: View {
    let weekNumber: Int
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest
    private var days: FetchedResults<Day>
    
    init(weekNumber: Int) {
        self.weekNumber = weekNumber
        let startDay = (weekNumber - 1) * 7 + 1
        let endDay = min(weekNumber * 7, 100)
        
        self._days = FetchRequest(
            sortDescriptors: [NSSortDescriptor(keyPath: \Day.dayNumber, ascending: true)],
            predicate: NSPredicate(format: "dayNumber >= %d AND dayNumber <= %d", startDay, endDay),
            animation: .default
        )
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Week overview
                    weekOverviewSection
                    
                    // Daily breakdown
                    dailyBreakdownSection
                }
                .padding()
            }
            .navigationTitle("Week \(weekNumber)")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var weekOverviewSection: some View {
        VStack(spacing: 16) {
            Text(CurriculumDataProvider.weeklyThemes[weekNumber] ?? "UNKNOWN WEEK")
                .font(.headline)
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            let completedDays = days.filter { $0.isCompleted }.count
            let totalDays = days.count
            
            HStack(spacing: 30) {
                VStack(spacing: 4) {
                    Text("\(completedDays)")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                    Text("Completed")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                VStack(spacing: 4) {
                    Text("\(totalDays - completedDays)")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.orange)
                    Text("Remaining")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                VStack(spacing: 4) {
                    Text("\(totalDays > 0 ? Int(Double(completedDays) / Double(totalDays) * 100) : 0)%")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                    Text("Progress")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
    
    private var dailyBreakdownSection: some View {
        VStack(spacing: 16) {
            Text("Daily Progress")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            LazyVStack(spacing: 12) {
                ForEach(days, id: \.objectID) { day in
                    DayProgressRow(day: day)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

// MARK: - Day Progress Row Component

struct DayProgressRow: View {
    let day: Day
    
    var body: some View {
        HStack(spacing: 16) {
            // Day number
            Text("Day \(day.dayNumber)")
                .font(.subheadline)
                .fontWeight(.medium)
                .frame(width: 60, alignment: .leading)
            
            // Progress bars
            VStack(spacing: 4) {
                HStack {
                    Text("DSA")
                        .font(.caption)
                        .foregroundColor(.blue)
                        .frame(width: 30, alignment: .leading)
                    
                    ProgressView(value: day.dsaProgress)
                        .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                        .scaleEffect(x: 1, y: 0.5)
                    
                    Text("\(Int(day.dsaProgress * 100))%")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(width: 35, alignment: .trailing)
                }
                
                HStack {
                    Text("SYS")
                        .font(.caption)
                        .foregroundColor(.orange)
                        .frame(width: 30, alignment: .leading)
                    
                    ProgressView(value: day.systemDesignProgress)
                        .progressViewStyle(LinearProgressViewStyle(tint: .orange))
                        .scaleEffect(x: 1, y: 0.5)
                    
                    Text("\(Int(day.systemDesignProgress * 100))%")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(width: 35, alignment: .trailing)
                }
            }
            
            // Completion status
            Image(systemName: day.isCompleted ? "checkmark.circle.fill" : "circle")
                .foregroundColor(day.isCompleted ? .green : .gray)
                .font(.title3)
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Preview

struct ProgressView_Previews: PreviewProvider {
    static var previews: some View {
        ProgressView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}