import Foundation
import CoreData
import UIKit

class ExportManager: ObservableObject {
    static let shared = ExportManager()
    
    @Published var isExporting = false
    @Published var exportStatus: ExportStatus = .idle
    
    private let fileManager = FileManager.default
    private let exportQueue = DispatchQueue(label: "export.queue", qos: .utility)
    
    enum ExportStatus {
        case idle
        case exporting
        case success(String)
        case failed(String)
    }
    
    enum ExportFormat {
        case markdown
        case json
        case both
    }
    
    private init() {}
    
    // MARK: - Public Interface
    
    /// Creates a comprehensive progress report in markdown format
    func createMarkdownReport(completion: @escaping (Bool, URL?, String?) -> Void) {
        exportQueue.async {
            DispatchQueue.main.async {
                self.isExporting = true
                self.exportStatus = .exporting
            }
            
            do {
                let reportURL = try self.generateMarkdownReport()
                
                DispatchQueue.main.async {
                    self.exportStatus = .success("Markdown report created successfully")
                    completion(true, reportURL, nil)
                }
                
            } catch {
                DispatchQueue.main.async {
                    self.exportStatus = .failed("Markdown export failed: \(error.localizedDescription)")
                    completion(false, nil, error.localizedDescription)
                }
            }
            
            DispatchQueue.main.async {
                self.isExporting = false
            }
        }
    }
    
    /// Creates a comprehensive data export in JSON format
    func createJSONExport(completion: @escaping (Bool, URL?, String?) -> Void) {
        exportQueue.async {
            DispatchQueue.main.async {
                self.isExporting = true
                self.exportStatus = .exporting
            }
            
            do {
                let exportURL = try self.generateJSONExport()
                
                DispatchQueue.main.async {
                    self.exportStatus = .success("JSON export created successfully")
                    completion(true, exportURL, nil)
                }
                
            } catch {
                DispatchQueue.main.async {
                    self.exportStatus = .failed("JSON export failed: \(error.localizedDescription)")
                    completion(false, nil, error.localizedDescription)
                }
            }
            
            DispatchQueue.main.async {
                self.isExporting = false
            }
        }
    }
    
    /// Creates both markdown and JSON exports
    func createComprehensiveExport(completion: @escaping (Bool, [URL], String?) -> Void) {
        exportQueue.async {
            DispatchQueue.main.async {
                self.isExporting = true
                self.exportStatus = .exporting
            }
            
            var exportURLs: [URL] = []
            var errorMessage: String?
            
            do {
                // Create markdown report
                let markdownURL = try self.generateMarkdownReport()
                exportURLs.append(markdownURL)
                
                // Create JSON export
                let jsonURL = try self.generateJSONExport()
                exportURLs.append(jsonURL)
                
                DispatchQueue.main.async {
                    self.exportStatus = .success("Comprehensive export created successfully")
                    completion(true, exportURLs, nil)
                }
                
            } catch {
                errorMessage = error.localizedDescription
                DispatchQueue.main.async {
                    self.exportStatus = .failed("Comprehensive export failed: \(error.localizedDescription)")
                    completion(false, exportURLs, errorMessage)
                }
            }
            
            DispatchQueue.main.async {
                self.isExporting = false
            }
        }
    }
    
    /// Shares export files using iOS sharing system
    func shareExports(_ urls: [URL], from viewController: UIViewController? = nil) {
        guard !urls.isEmpty else { return }
        
        DispatchQueue.main.async {
            let activityViewController = UIActivityViewController(activityItems: urls, applicationActivities: nil)
            
            // Configure for iPad
            if let popover = activityViewController.popoverPresentationController {
                if let viewController = viewController {
                    popover.sourceView = viewController.view
                    popover.sourceRect = CGRect(x: viewController.view.bounds.midX, 
                                              y: viewController.view.bounds.midY, 
                                              width: 0, height: 0)
                } else {
                    // Fallback for when no view controller is provided
                    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                       let window = windowScene.windows.first {
                        popover.sourceView = window.rootViewController?.view
                        popover.sourceRect = CGRect(x: window.bounds.midX, y: window.bounds.midY, width: 0, height: 0)
                    }
                }
                popover.permittedArrowDirections = []
            }
            
            // Present the share sheet
            if let presentingViewController = viewController ?? UIApplication.shared.windows.first?.rootViewController {
                presentingViewController.present(activityViewController, animated: true)
            }
        }
    }
    
    // MARK: - Private Implementation
    
    private func generateMarkdownReport() throws -> URL {
        let context = PersistenceController.shared.container.viewContext
        let timestamp = generateTimestamp()
        let reportURL = exportsDirectory.appendingPathComponent("MachineMode_Progress_Report_\(timestamp).md")
        
        // Ensure exports directory exists
        try fileManager.createDirectory(at: exportsDirectory, withIntermediateDirectories: true)
        
        var markdown = ""
        
        try context.performAndWait {
            // Generate report content
            markdown = try generateMarkdownContent(context: context)
        }
        
        // Write markdown to file
        try markdown.write(to: reportURL, atomically: true, encoding: .utf8)
        
        print("✅ Markdown report created: \(reportURL.lastPathComponent)")
        return reportURL
    }
    
    private func generateMarkdownContent(context: NSManagedObjectContext) throws -> String {
        var markdown = ""
        
        // Header
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .full
        dateFormatter.timeStyle = .short
        
        markdown += "# Machine Mode - 100 Day Progress Report\n\n"
        markdown += "**Generated:** \(dateFormatter.string(from: Date()))\n\n"
        
        // Overall Statistics
        let stats = try calculateOverallStatistics(context: context)
        markdown += "## 📊 Overall Progress\n\n"
        markdown += "- **Total Days:** \(stats.totalDays)/100\n"
        markdown += "- **Completed Days:** \(stats.completedDays)\n"
        markdown += "- **Overall Progress:** \(String(format: "%.1f", stats.overallProgress * 100))%\n"
        markdown += "- **Current Streak:** \(stats.currentStreak) days\n"
        markdown += "- **Longest Streak:** \(stats.longestStreak) days\n\n"
        
        // DSA Progress
        markdown += "### 🧮 DSA Problems\n\n"
        markdown += "- **Total Problems:** \(stats.totalDSAProblems)\n"
        markdown += "- **Completed Problems:** \(stats.completedDSAProblems)\n"
        markdown += "- **DSA Progress:** \(String(format: "%.1f", stats.dsaProgress * 100))%\n"
        markdown += "- **Average Time per Problem:** \(stats.averageTimePerProblem) minutes\n\n"
        
        // System Design Progress
        markdown += "### 🏗️ System Design\n\n"
        markdown += "- **Total Topics:** \(stats.totalSystemTopics)\n"
        markdown += "- **Completed Topics:** \(stats.completedSystemTopics)\n"
        markdown += "- **System Design Progress:** \(String(format: "%.1f", stats.systemDesignProgress * 100))%\n\n"
        
        // Weekly Breakdown
        markdown += "## 📅 Weekly Progress\n\n"
        let weeklyStats = try calculateWeeklyStatistics(context: context)
        
        for week in weeklyStats {
            markdown += "### Week \(week.weekNumber): \(week.theme)\n\n"
            markdown += "- **Days Completed:** \(week.completedDays)/7\n"
            markdown += "- **Week Progress:** \(String(format: "%.1f", week.progress * 100))%\n"
            
            if !week.completedDays.isEmpty {
                markdown += "- **Completed Days:** \(week.completedDays.map(String.init).joined(separator: ", "))\n"
            }
            
            markdown += "\n"
        }
        
        // Daily Details
        markdown += "## 📋 Daily Progress Details\n\n"
        
        let daysRequest: NSFetchRequest<Day> = Day.fetchRequest()
        daysRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Day.dayNumber, ascending: true)]
        let days = try context.fetch(daysRequest)
        
        for day in days {
            let dayProgress = day.dsaProgress + day.systemDesignProgress
            let isCompleted = day.isCompleted
            let statusEmoji = isCompleted ? "✅" : (dayProgress > 0 ? "🔄" : "⭕")
            
            markdown += "### \(statusEmoji) Day \(day.dayNumber)\n\n"
            
            if let date = day.date {
                let dayFormatter = DateFormatter()
                dayFormatter.dateStyle = .medium
                markdown += "**Date:** \(dayFormatter.string(from: date))\n"
            }
            
            markdown += "**Progress:** \(String(format: "%.1f", (dayProgress / 2.0) * 100))%\n\n"
            
            // DSA Problems for this day
            if let dsaProblems = day.dsaProblems?.allObjects as? [DSAProblem], !dsaProblems.isEmpty {
                markdown += "#### 🧮 DSA Problems\n\n"
                
                let sortedProblems = dsaProblems.sorted { ($0.leetcodeNumber ?? "0") < ($1.leetcodeNumber ?? "0") }
                
                for problem in sortedProblems {
                    let problemStatus = problem.isCompleted ? "✅" : "⭕"
                    let bonusIndicator = problem.isBonusProblem ? " (Bonus)" : ""
                    
                    markdown += "- \(problemStatus) **\(problem.problemName ?? "Unknown")**\(bonusIndicator)\n"
                    
                    if let leetcodeNumber = problem.leetcodeNumber, !leetcodeNumber.isEmpty {
                        markdown += "  - LeetCode: #\(leetcodeNumber)\n"
                    }
                    
                    if let difficulty = problem.difficulty, !difficulty.isEmpty {
                        markdown += "  - Difficulty: \(difficulty)\n"
                    }
                    
                    if problem.timeSpent > 0 {
                        markdown += "  - Time Spent: \(problem.timeSpent) minutes\n"
                    }
                    
                    if let notes = problem.notes, !notes.isEmpty {
                        markdown += "  - Notes: \(notes)\n"
                    }
                    
                    if let completedAt = problem.completedAt {
                        let timeFormatter = DateFormatter()
                        timeFormatter.dateStyle = .none
                        timeFormatter.timeStyle = .short
                        markdown += "  - Completed: \(timeFormatter.string(from: completedAt))\n"
                    }
                    
                    markdown += "\n"
                }
            }
            
            // System Design Topics for this day
            if let systemTopics = day.systemDesignTopics?.allObjects as? [SystemDesignTopic], !systemTopics.isEmpty {
                markdown += "#### 🏗️ System Design Topics\n\n"
                
                for topic in systemTopics {
                    let topicStatus = topic.isCompleted ? "✅" : "⭕"
                    
                    markdown += "- \(topicStatus) **\(topic.topicName ?? "Unknown")**\n"
                    
                    if let description = topic.topicDescription, !description.isEmpty {
                        markdown += "  - Task: \(description)\n"
                    }
                    
                    if topic.videoWatched {
                        markdown += "  - 📺 Video Watched\n"
                    }
                    
                    if topic.taskCompleted {
                        markdown += "  - ✏️ Task Completed\n"
                    }
                    
                    if let notes = topic.notes, !notes.isEmpty {
                        markdown += "  - Notes: \(notes)\n"
                    }
                    
                    if let completedAt = topic.completedAt {
                        let timeFormatter = DateFormatter()
                        timeFormatter.dateStyle = .none
                        timeFormatter.timeStyle = .short
                        markdown += "  - Completed: \(timeFormatter.string(from: completedAt))\n"
                    }
                    
                    markdown += "\n"
                }
            }
            
            // Daily Reflection
            if let reflection = day.dailyReflection, !reflection.isEmpty {
                markdown += "#### 💭 Daily Reflection\n\n"
                markdown += "\(reflection)\n\n"
            }
            
            markdown += "---\n\n"
        }
        
        // Footer
        markdown += "## 📱 Export Information\n\n"
        markdown += "- **App Version:** \(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown")\n"
        markdown += "- **Export Date:** \(ISO8601DateFormatter().string(from: Date()))\n"
        markdown += "- **Total Export Size:** \(calculateDataSize()) MB\n\n"
        markdown += "*Generated by Machine Mode - 100 Day Interview Prep Tracker*\n"
        
        return markdown
    }
    
    private func generateJSONExport() throws -> URL {
        let context = PersistenceController.shared.container.viewContext
        let timestamp = generateTimestamp()
        let exportURL = exportsDirectory.appendingPathComponent("MachineMode_Data_Export_\(timestamp).json")
        
        // Ensure exports directory exists
        try fileManager.createDirectory(at: exportsDirectory, withIntermediateDirectories: true)
        
        var exportData: [String: Any] = [:]
        
        try context.performAndWait {
            // Export metadata
            exportData["exportInfo"] = [
                "timestamp": ISO8601DateFormatter().string(from: Date()),
                "appVersion": Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown",
                "exportFormat": "comprehensive_data_export",
                "dataVersion": "1.0"
            ]
            
            // Export overall statistics
            let stats = try calculateOverallStatistics(context: context)
            exportData["overallStatistics"] = [
                "totalDays": stats.totalDays,
                "completedDays": stats.completedDays,
                "overallProgress": stats.overallProgress,
                "currentStreak": stats.currentStreak,
                "longestStreak": stats.longestStreak,
                "totalDSAProblems": stats.totalDSAProblems,
                "completedDSAProblems": stats.completedDSAProblems,
                "dsaProgress": stats.dsaProgress,
                "totalSystemTopics": stats.totalSystemTopics,
                "completedSystemTopics": stats.completedSystemTopics,
                "systemDesignProgress": stats.systemDesignProgress,
                "averageTimePerProblem": stats.averageTimePerProblem,
                "totalTimeSpent": stats.totalTimeSpent
            ]
            
            // Export weekly statistics
            let weeklyStats = try calculateWeeklyStatistics(context: context)
            exportData["weeklyStatistics"] = weeklyStats.map { week in
                [
                    "weekNumber": week.weekNumber,
                    "theme": week.theme,
                    "progress": week.progress,
                    "completedDays": week.completedDays,
                    "totalDays": week.totalDays
                ]
            }
            
            // Export detailed daily data
            let daysRequest: NSFetchRequest<Day> = Day.fetchRequest()
            daysRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Day.dayNumber, ascending: true)]
            let days = try context.fetch(daysRequest)
            
            exportData["dailyProgress"] = days.map { day in
                var dayData: [String: Any] = [
                    "dayNumber": day.dayNumber,
                    "date": day.date != nil ? ISO8601DateFormatter().string(from: day.date!) : nil,
                    "dsaProgress": day.dsaProgress,
                    "systemDesignProgress": day.systemDesignProgress,
                    "isCompleted": day.isCompleted,
                    "dailyReflection": day.dailyReflection ?? "",
                    "createdAt": day.createdAt != nil ? ISO8601DateFormatter().string(from: day.createdAt!) : nil,
                    "updatedAt": day.updatedAt != nil ? ISO8601DateFormatter().string(from: day.updatedAt!) : nil
                ]
                
                // Export DSA Problems with full details
                if let dsaProblems = day.dsaProblems?.allObjects as? [DSAProblem] {
                    dayData["dsaProblems"] = dsaProblems.map { problem in
                        [
                            "problemName": problem.problemName ?? "",
                            "leetcodeNumber": problem.leetcodeNumber ?? "",
                            "isCompleted": problem.isCompleted,
                            "timeSpent": problem.timeSpent,
                            "notes": problem.notes ?? "",
                            "difficulty": problem.difficulty ?? "",
                            "isBonusProblem": problem.isBonusProblem,
                            "completedAt": problem.completedAt != nil ? ISO8601DateFormatter().string(from: problem.completedAt!) : nil,
                            "createdAt": problem.createdAt != nil ? ISO8601DateFormatter().string(from: problem.createdAt!) : nil,
                            "updatedAt": problem.updatedAt != nil ? ISO8601DateFormatter().string(from: problem.updatedAt!) : nil
                        ]
                    }
                }
                
                // Export System Design Topics with full details
                if let systemTopics = day.systemDesignTopics?.allObjects as? [SystemDesignTopic] {
                    dayData["systemDesignTopics"] = systemTopics.map { topic in
                        [
                            "topicName": topic.topicName ?? "",
                            "topicDescription": topic.topicDescription ?? "",
                            "isCompleted": topic.isCompleted,
                            "videoWatched": topic.videoWatched,
                            "taskCompleted": topic.taskCompleted,
                            "notes": topic.notes ?? "",
                            "completedAt": topic.completedAt != nil ? ISO8601DateFormatter().string(from: topic.completedAt!) : nil,
                            "createdAt": topic.createdAt != nil ? ISO8601DateFormatter().string(from: topic.createdAt!) : nil,
                            "updatedAt": topic.updatedAt != nil ? ISO8601DateFormatter().string(from: topic.updatedAt!) : nil
                        ]
                    }
                }
                
                return dayData
            }
            
            // Export User Settings
            let settingsRequest: NSFetchRequest<UserSettings> = UserSettings.fetchRequest()
            if let settings = try context.fetch(settingsRequest).first {
                exportData["userSettings"] = [
                    "morningNotificationTime": settings.morningNotificationTime != nil ? ISO8601DateFormatter().string(from: settings.morningNotificationTime!) : nil,
                    "eveningNotificationTime": settings.eveningNotificationTime != nil ? ISO8601DateFormatter().string(from: settings.eveningNotificationTime!) : nil,
                    "isNotificationsEnabled": settings.isNotificationsEnabled,
                    "currentStreak": settings.currentStreak,
                    "longestStreak": settings.longestStreak,
                    "startDate": settings.startDate != nil ? ISO8601DateFormatter().string(from: settings.startDate!) : nil,
                    "lastBackupDate": settings.lastBackupDate != nil ? ISO8601DateFormatter().string(from: settings.lastBackupDate!) : nil,
                    "appVersion": settings.appVersion ?? ""
                ]
            }
        }
        
        // Write JSON to file
        let jsonData = try JSONSerialization.data(withJSONObject: exportData, options: .prettyPrinted)
        try jsonData.write(to: exportURL)
        
        print("✅ JSON export created: \(exportURL.lastPathComponent)")
        return exportURL
    }
    
    // MARK: - Statistics Calculation
    
    private func calculateOverallStatistics(context: NSManagedObjectContext) throws -> OverallStatistics {
        let daysRequest: NSFetchRequest<Day> = Day.fetchRequest()
        let days = try context.fetch(daysRequest)
        
        let totalDays = days.count
        let completedDays = days.filter { $0.isCompleted }.count
        let overallProgress = totalDays > 0 ? Float(completedDays) / Float(totalDays) : 0.0
        
        // Calculate streaks
        let sortedDays = days.sorted { $0.dayNumber < $1.dayNumber }
        let (currentStreak, longestStreak) = calculateStreaks(from: sortedDays)
        
        // DSA Statistics
        let allDSAProblems = days.flatMap { day in
            (day.dsaProblems?.allObjects as? [DSAProblem]) ?? []
        }
        let totalDSAProblems = allDSAProblems.count
        let completedDSAProblems = allDSAProblems.filter { $0.isCompleted }.count
        let dsaProgress = totalDSAProblems > 0 ? Float(completedDSAProblems) / Float(totalDSAProblems) : 0.0
        let totalTimeSpent = allDSAProblems.reduce(0) { $0 + Int($1.timeSpent) }
        let averageTimePerProblem = completedDSAProblems > 0 ? totalTimeSpent / completedDSAProblems : 0
        
        // System Design Statistics
        let allSystemTopics = days.flatMap { day in
            (day.systemDesignTopics?.allObjects as? [SystemDesignTopic]) ?? []
        }
        let totalSystemTopics = allSystemTopics.count
        let completedSystemTopics = allSystemTopics.filter { $0.isCompleted }.count
        let systemDesignProgress = totalSystemTopics > 0 ? Float(completedSystemTopics) / Float(totalSystemTopics) : 0.0
        
        return OverallStatistics(
            totalDays: totalDays,
            completedDays: completedDays,
            overallProgress: overallProgress,
            currentStreak: currentStreak,
            longestStreak: longestStreak,
            totalDSAProblems: totalDSAProblems,
            completedDSAProblems: completedDSAProblems,
            dsaProgress: dsaProgress,
            totalSystemTopics: totalSystemTopics,
            completedSystemTopics: completedSystemTopics,
            systemDesignProgress: systemDesignProgress,
            averageTimePerProblem: averageTimePerProblem,
            totalTimeSpent: totalTimeSpent
        )
    }
    
    private func calculateWeeklyStatistics(context: NSManagedObjectContext) throws -> [WeeklyStatistics] {
        let daysRequest: NSFetchRequest<Day> = Day.fetchRequest()
        daysRequest.sortDescriptors = [NSSortDescriptor(keyPath: \Day.dayNumber, ascending: true)]
        let days = try context.fetch(daysRequest)
        
        var weeklyStats: [WeeklyStatistics] = []
        
        // Group days by weeks (7 days each)
        for weekNumber in 1...15 { // 100 days = ~14.3 weeks, so 15 to be safe
            let startDay = (weekNumber - 1) * 7 + 1
            let endDay = min(weekNumber * 7, 100)
            
            let weekDays = days.filter { Int($0.dayNumber) >= startDay && Int($0.dayNumber) <= endDay }
            
            if !weekDays.isEmpty {
                let completedDaysInWeek = weekDays.filter { $0.isCompleted }.map { Int($0.dayNumber) }
                let progress = Float(completedDaysInWeek.count) / Float(weekDays.count)
                let theme = getWeekTheme(for: weekNumber)
                
                weeklyStats.append(WeeklyStatistics(
                    weekNumber: weekNumber,
                    theme: theme,
                    progress: progress,
                    completedDays: completedDaysInWeek,
                    totalDays: weekDays.count
                ))
            }
        }
        
        return weeklyStats
    }
    
    private func calculateStreaks(from days: [Day]) -> (current: Int, longest: Int) {
        guard !days.isEmpty else { return (0, 0) }
        
        var currentStreak = 0
        var longestStreak = 0
        var tempStreak = 0
        
        // Calculate from the end (most recent days)
        let reversedDays = days.reversed()
        var foundIncomplete = false
        
        for day in reversedDays {
            if day.isCompleted {
                tempStreak += 1
                if !foundIncomplete {
                    currentStreak += 1
                }
            } else {
                foundIncomplete = true
                longestStreak = max(longestStreak, tempStreak)
                tempStreak = 0
            }
        }
        
        longestStreak = max(longestStreak, tempStreak)
        longestStreak = max(longestStreak, currentStreak)
        
        return (currentStreak, longestStreak)
    }
    
    private func getWeekTheme(for weekNumber: Int) -> String {
        let themes = [
            1: "FOUNDATIONS",
            2: "SLIDING WINDOWS & HASH MAPS",
            3: "STACKS, LINKED LISTS & RATE LIMITING",
            4: "BINARY SEARCH & RECURSION",
            5: "BACKTRACKING & TREES",
            6: "TREES ADVANCED & WHATSAPP",
            7: "GRAPHS I & YOUTUBE",
            8: "GRAPHS II & UBER",
            9: "DYNAMIC PROGRAMMING I & TWITTER",
            10: "DYNAMIC PROGRAMMING II & NOTIFICATIONS",
            11: "GREEDY & SYSTEM DESIGN REVISION",
            12: "MIXED REVISION & MOCK PREP",
            13: "MOCK WEEK 1 - PRESSURE TESTING",
            14: "MOCK WEEK 2 - FINAL PREPARATION",
            15: "FINAL PREPARATION"
        ]
        
        return themes[weekNumber] ?? "ADDITIONAL PREPARATION"
    }
    
    private func calculateDataSize() -> String {
        do {
            let exportFiles = try fileManager.contentsOfDirectory(at: exportsDirectory, 
                                                                includingPropertiesForKeys: [.fileSizeKey])
            let totalSize = exportFiles.reduce(0) { total, url in
                do {
                    let resourceValues = try url.resourceValues(forKeys: [.fileSizeKey])
                    return total + (resourceValues.fileSize ?? 0)
                } catch {
                    return total
                }
            }
            
            let sizeInMB = Double(totalSize) / (1024 * 1024)
            return String(format: "%.2f", sizeInMB)
        } catch {
            return "Unknown"
        }
    }
    
    // MARK: - Utility Methods
    
    private func generateTimestamp() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        return formatter.string(from: Date())
    }
    
    private var documentsDirectory: URL {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
    }
    
    private var exportsDirectory: URL {
        documentsDirectory.appendingPathComponent("Exports")
    }
}

// MARK: - Supporting Types

struct OverallStatistics {
    let totalDays: Int
    let completedDays: Int
    let overallProgress: Float
    let currentStreak: Int
    let longestStreak: Int
    let totalDSAProblems: Int
    let completedDSAProblems: Int
    let dsaProgress: Float
    let totalSystemTopics: Int
    let completedSystemTopics: Int
    let systemDesignProgress: Float
    let averageTimePerProblem: Int
    let totalTimeSpent: Int
}

struct WeeklyStatistics {
    let weekNumber: Int
    let theme: String
    let progress: Float
    let completedDays: [Int]
    let totalDays: Int
}

enum ExportError: LocalizedError {
    case exportDirectoryCreationFailed
    case markdownGenerationFailed
    case jsonGenerationFailed
    case fileWriteFailed
    
    var errorDescription: String? {
        switch self {
        case .exportDirectoryCreationFailed:
            return "Failed to create export directory"
        case .markdownGenerationFailed:
            return "Failed to generate markdown report"
        case .jsonGenerationFailed:
            return "Failed to generate JSON export"
        case .fileWriteFailed:
            return "Failed to write export file"
        }
    }
}