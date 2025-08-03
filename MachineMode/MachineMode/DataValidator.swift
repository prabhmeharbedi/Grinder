import CoreData
import Foundation

/// Utility class for performing comprehensive data validation and integrity checks
class DataValidator {
    static let shared = DataValidator()
    
    private init() {}
    
    // MARK: - Comprehensive Validation
    
    /// Performs a complete validation of all data in the Core Data store
    func validateAllData(context: NSManagedObjectContext) throws -> ValidationReport {
        var report = ValidationReport()
        
        try context.performAndWait {
            // Validate Days
            try validateDays(context: context, report: &report)
            
            // Validate DSA Problems
            try validateDSAProblems(context: context, report: &report)
            
            // Validate System Design Topics
            try validateSystemDesignTopics(context: context, report: &report)
            
            // Validate User Settings
            try validateUserSettings(context: context, report: &report)
            
            // Check relationships integrity
            try validateRelationships(context: context, report: &report)
            
            // Check for duplicate data
            try checkForDuplicates(context: context, report: &report)
        }
        
        return report
    }
    
    // MARK: - Entity-Specific Validation
    
    private func validateDays(context: NSManagedObjectContext, report: inout ValidationReport) throws {
        let request: NSFetchRequest<Day> = Day.fetchRequest()
        let days = try context.fetch(request)
        
        report.totalDays = days.count
        
        for day in days {
            // Check day number range
            if day.dayNumber < 1 || day.dayNumber > 100 {
                report.errors.append("Day \(day.dayNumber) has invalid day number")
                report.invalidDays += 1
            }
            
            // Check progress values
            if day.dsaProgress < 0.0 || day.dsaProgress > 1.0 {
                report.errors.append("Day \(day.dayNumber) has invalid DSA progress: \(day.dsaProgress)")
                report.invalidProgressValues += 1
            }
            
            if day.systemDesignProgress < 0.0 || day.systemDesignProgress > 1.0 {
                report.errors.append("Day \(day.dayNumber) has invalid System Design progress: \(day.systemDesignProgress)")
                report.invalidProgressValues += 1
            }
            
            // Check required dates
            if day.createdAt == nil {
                report.warnings.append("Day \(day.dayNumber) missing creation date")
                report.missingDates += 1
            }
            
            if day.updatedAt == nil {
                report.warnings.append("Day \(day.dayNumber) missing update date")
                report.missingDates += 1
            }
            
            // Validate progress calculation
            let calculatedDSAProgress = calculateDSAProgress(for: day)
            let calculatedSystemProgress = calculateSystemDesignProgress(for: day)
            
            if abs(day.dsaProgress - calculatedDSAProgress) > 0.01 {
                report.warnings.append("Day \(day.dayNumber) DSA progress mismatch: stored=\(day.dsaProgress), calculated=\(calculatedDSAProgress)")
                report.progressMismatches += 1
            }
            
            if abs(day.systemDesignProgress - calculatedSystemProgress) > 0.01 {
                report.warnings.append("Day \(day.dayNumber) System Design progress mismatch: stored=\(day.systemDesignProgress), calculated=\(calculatedSystemProgress)")
                report.progressMismatches += 1
            }
        }
        
        // Check for missing days (should have 100 days)
        let dayNumbers = Set(days.map { Int($0.dayNumber) })
        let expectedDays = Set(1...100)
        let missingDays = expectedDays.subtracting(dayNumbers)
        
        if !missingDays.isEmpty {
            report.errors.append("Missing days: \(missingDays.sorted())")
            report.missingDays = missingDays.count
        }
        
        // Check for duplicate days
        let duplicateDays = days.map { Int($0.dayNumber) }
            .reduce(into: [:]) { counts, day in counts[day, default: 0] += 1 }
            .filter { $0.value > 1 }
            .keys
        
        if !duplicateDays.isEmpty {
            report.errors.append("Duplicate days found: \(Array(duplicateDays).sorted())")
            report.duplicateDays = duplicateDays.count
        }
    }
    
    private func validateDSAProblems(context: NSManagedObjectContext, report: inout ValidationReport) throws {
        let request: NSFetchRequest<DSAProblem> = DSAProblem.fetchRequest()
        let problems = try context.fetch(request)
        
        report.totalDSAProblems = problems.count
        
        for problem in problems {
            // Check required fields
            if problem.problemName?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true {
                report.errors.append("DSA Problem has empty name")
                report.emptyRequiredFields += 1
            }
            
            // Check difficulty values
            if let difficulty = problem.difficulty {
                let validDifficulties = ["Easy", "Medium", "Hard"]
                if !validDifficulties.contains(difficulty) {
                    report.errors.append("DSA Problem '\(problem.problemName ?? "Unknown")' has invalid difficulty: \(difficulty)")
                    report.invalidDifficulties += 1
                }
            }
            
            // Check time spent
            if problem.timeSpent < 0 {
                report.errors.append("DSA Problem '\(problem.problemName ?? "Unknown")' has negative time spent: \(problem.timeSpent)")
                report.negativeTimeValues += 1
            }
            
            // Check completion consistency
            if problem.isCompleted && problem.completedAt == nil {
                report.warnings.append("DSA Problem '\(problem.problemName ?? "Unknown")' marked complete but missing completion date")
                report.missingCompletionDates += 1
            }
            
            if !problem.isCompleted && problem.completedAt != nil {
                report.warnings.append("DSA Problem '\(problem.problemName ?? "Unknown")' not complete but has completion date")
                report.inconsistentCompletionStatus += 1
            }
        }
    }
    
    private func validateSystemDesignTopics(context: NSManagedObjectContext, report: inout ValidationReport) throws {
        let request: NSFetchRequest<SystemDesignTopic> = SystemDesignTopic.fetchRequest()
        let topics = try context.fetch(request)
        
        report.totalSystemDesignTopics = topics.count
        
        for topic in topics {
            // Check required fields
            if topic.topicName?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true {
                report.errors.append("System Design Topic has empty name")
                report.emptyRequiredFields += 1
            }
            
            // Check completion consistency
            if topic.isCompleted && topic.completedAt == nil {
                report.warnings.append("System Design Topic '\(topic.topicName ?? "Unknown")' marked complete but missing completion date")
                report.missingCompletionDates += 1
            }
            
            if !topic.isCompleted && topic.completedAt != nil {
                report.warnings.append("System Design Topic '\(topic.topicName ?? "Unknown")' not complete but has completion date")
                report.inconsistentCompletionStatus += 1
            }
            
            // Check sub-completion consistency
            let overallCompletion = topic.videoWatched && topic.taskCompleted
            if topic.isCompleted != overallCompletion {
                report.warnings.append("System Design Topic '\(topic.topicName ?? "Unknown")' completion status inconsistent with sub-tasks")
                report.inconsistentCompletionStatus += 1
            }
        }
    }
    
    private func validateUserSettings(context: NSManagedObjectContext, report: inout ValidationReport) throws {
        let request: NSFetchRequest<UserSettings> = UserSettings.fetchRequest()
        let settings = try context.fetch(request)
        
        report.totalUserSettings = settings.count
        
        // Should have exactly one UserSettings record
        if settings.count == 0 {
            report.errors.append("No UserSettings record found")
        } else if settings.count > 1 {
            report.errors.append("Multiple UserSettings records found: \(settings.count)")
            report.multipleUserSettings = settings.count - 1
        }
        
        for setting in settings {
            // Check streak values
            if setting.currentStreak < 0 {
                report.errors.append("Current streak is negative: \(setting.currentStreak)")
                report.negativeStreakValues += 1
            }
            
            if setting.longestStreak < 0 {
                report.errors.append("Longest streak is negative: \(setting.longestStreak)")
                report.negativeStreakValues += 1
            }
            
            if setting.longestStreak < setting.currentStreak {
                report.warnings.append("Longest streak (\(setting.longestStreak)) is less than current streak (\(setting.currentStreak))")
                report.inconsistentStreakValues += 1
            }
            
            // Check notification times
            if setting.morningNotificationTime == nil {
                report.warnings.append("Morning notification time not set")
                report.missingNotificationTimes += 1
            }
            
            if setting.eveningNotificationTime == nil {
                report.warnings.append("Evening notification time not set")
                report.missingNotificationTimes += 1
            }
        }
    }
    
    private func validateRelationships(context: NSManagedObjectContext, report: inout ValidationReport) throws {
        // Check for orphaned DSA problems
        let orphanedProblemsRequest: NSFetchRequest<DSAProblem> = DSAProblem.fetchRequest()
        orphanedProblemsRequest.predicate = NSPredicate(format: "day == nil")
        let orphanedProblems = try context.fetch(orphanedProblemsRequest)
        
        if !orphanedProblems.isEmpty {
            report.errors.append("Found \(orphanedProblems.count) orphaned DSA problems")
            report.orphanedRecords += orphanedProblems.count
        }
        
        // Check for orphaned system design topics
        let orphanedTopicsRequest: NSFetchRequest<SystemDesignTopic> = SystemDesignTopic.fetchRequest()
        orphanedTopicsRequest.predicate = NSPredicate(format: "day == nil")
        let orphanedTopics = try context.fetch(orphanedTopicsRequest)
        
        if !orphanedTopics.isEmpty {
            report.errors.append("Found \(orphanedTopics.count) orphaned system design topics")
            report.orphanedRecords += orphanedTopics.count
        }
    }
    
    private func checkForDuplicates(context: NSManagedObjectContext, report: inout ValidationReport) throws {
        // Check for duplicate DSA problems within the same day
        let problemsRequest: NSFetchRequest<DSAProblem> = DSAProblem.fetchRequest()
        let problems = try context.fetch(problemsRequest)
        
        let problemsByDay = Dictionary(grouping: problems) { $0.day?.dayNumber ?? -1 }
        
        for (dayNumber, dayProblems) in problemsByDay {
            let problemNames = dayProblems.map { $0.problemName ?? "" }
            let duplicateNames = problemNames.reduce(into: [:]) { counts, name in
                counts[name, default: 0] += 1
            }.filter { $0.value > 1 }.keys
            
            if !duplicateNames.isEmpty {
                report.warnings.append("Day \(dayNumber) has duplicate DSA problems: \(Array(duplicateNames))")
                report.duplicateProblems += duplicateNames.count
            }
        }
        
        // Check for duplicate system design topics within the same day
        let topicsRequest: NSFetchRequest<SystemDesignTopic> = SystemDesignTopic.fetchRequest()
        let topics = try context.fetch(topicsRequest)
        
        let topicsByDay = Dictionary(grouping: topics) { $0.day?.dayNumber ?? -1 }
        
        for (dayNumber, dayTopics) in topicsByDay {
            let topicNames = dayTopics.map { $0.topicName ?? "" }
            let duplicateNames = topicNames.reduce(into: [:]) { counts, name in
                counts[name, default: 0] += 1
            }.filter { $0.value > 1 }.keys
            
            if !duplicateNames.isEmpty {
                report.warnings.append("Day \(dayNumber) has duplicate system design topics: \(Array(duplicateNames))")
                report.duplicateTopics += duplicateNames.count
            }
        }
    }
    
    // MARK: - Progress Calculation Helpers
    
    private func calculateDSAProgress(for day: Day) -> Float {
        let problems = day.dsaProblemsArray
        guard !problems.isEmpty else { return 0.0 }
        
        let completedCount = problems.filter { $0.isCompleted }.count
        return Float(completedCount) / Float(problems.count)
    }
    
    private func calculateSystemDesignProgress(for day: Day) -> Float {
        let topics = day.systemDesignTopicsArray
        guard !topics.isEmpty else { return 0.0 }
        
        let completedCount = topics.filter { $0.isCompleted }.count
        return Float(completedCount) / Float(topics.count)
    }
    
    // MARK: - Auto-Fix Methods
    
    /// Attempts to automatically fix common data issues
    func autoFixIssues(context: NSManagedObjectContext, report: ValidationReport) throws -> Int {
        var fixedIssues = 0
        
        try context.performAndWait {
            // Fix missing dates
            fixedIssues += try fixMissingDates(context: context)
            
            // Fix progress mismatches
            fixedIssues += try fixProgressMismatches(context: context)
            
            // Fix completion date inconsistencies
            fixedIssues += try fixCompletionDateInconsistencies(context: context)
            
            // Fix streak inconsistencies
            fixedIssues += try fixStreakInconsistencies(context: context)
            
            // Remove orphaned records
            fixedIssues += try removeOrphanedRecords(context: context)
            
            if context.hasChanges {
                try context.save()
            }
        }
        
        return fixedIssues
    }
    
    private func fixMissingDates(context: NSManagedObjectContext) throws -> Int {
        var fixedCount = 0
        let now = Date()
        
        // Fix missing dates in Days
        let daysRequest: NSFetchRequest<Day> = Day.fetchRequest()
        let days = try context.fetch(daysRequest)
        
        for day in days {
            if day.createdAt == nil {
                day.createdAt = now
                fixedCount += 1
            }
            if day.updatedAt == nil {
                day.updatedAt = now
                fixedCount += 1
            }
        }
        
        // Fix missing dates in DSA Problems
        let problemsRequest: NSFetchRequest<DSAProblem> = DSAProblem.fetchRequest()
        let problems = try context.fetch(problemsRequest)
        
        for problem in problems {
            if problem.createdAt == nil {
                problem.createdAt = now
                fixedCount += 1
            }
            if problem.updatedAt == nil {
                problem.updatedAt = now
                fixedCount += 1
            }
        }
        
        // Fix missing dates in System Design Topics
        let topicsRequest: NSFetchRequest<SystemDesignTopic> = SystemDesignTopic.fetchRequest()
        let topics = try context.fetch(topicsRequest)
        
        for topic in topics {
            if topic.createdAt == nil {
                topic.createdAt = now
                fixedCount += 1
            }
            if topic.updatedAt == nil {
                topic.updatedAt = now
                fixedCount += 1
            }
        }
        
        return fixedCount
    }
    
    private func fixProgressMismatches(context: NSManagedObjectContext) throws -> Int {
        let daysRequest: NSFetchRequest<Day> = Day.fetchRequest()
        let days = try context.fetch(daysRequest)
        
        var fixedCount = 0
        
        for day in days {
            let oldDSAProgress = day.dsaProgress
            let oldSystemProgress = day.systemDesignProgress
            
            day.updateProgress()
            
            if abs(oldDSAProgress - day.dsaProgress) > 0.01 {
                fixedCount += 1
            }
            if abs(oldSystemProgress - day.systemDesignProgress) > 0.01 {
                fixedCount += 1
            }
        }
        
        return fixedCount
    }
    
    private func fixCompletionDateInconsistencies(context: NSManagedObjectContext) throws -> Int {
        var fixedCount = 0
        let now = Date()
        
        // Fix DSA Problems
        let problemsRequest: NSFetchRequest<DSAProblem> = DSAProblem.fetchRequest()
        let problems = try context.fetch(problemsRequest)
        
        for problem in problems {
            if problem.isCompleted && problem.completedAt == nil {
                problem.completedAt = now
                fixedCount += 1
            } else if !problem.isCompleted && problem.completedAt != nil {
                problem.completedAt = nil
                fixedCount += 1
            }
        }
        
        // Fix System Design Topics
        let topicsRequest: NSFetchRequest<SystemDesignTopic> = SystemDesignTopic.fetchRequest()
        let topics = try context.fetch(topicsRequest)
        
        for topic in topics {
            if topic.isCompleted && topic.completedAt == nil {
                topic.completedAt = now
                fixedCount += 1
            } else if !topic.isCompleted && topic.completedAt != nil {
                topic.completedAt = nil
                fixedCount += 1
            }
        }
        
        return fixedCount
    }
    
    private func fixStreakInconsistencies(context: NSManagedObjectContext) throws -> Int {
        let settingsRequest: NSFetchRequest<UserSettings> = UserSettings.fetchRequest()
        let settings = try context.fetch(settingsRequest)
        
        var fixedCount = 0
        
        for setting in settings {
            if setting.longestStreak < setting.currentStreak {
                setting.longestStreak = setting.currentStreak
                fixedCount += 1
            }
        }
        
        return fixedCount
    }
    
    private func removeOrphanedRecords(context: NSManagedObjectContext) throws -> Int {
        var removedCount = 0
        
        // Remove orphaned DSA problems
        let orphanedProblemsRequest: NSFetchRequest<DSAProblem> = DSAProblem.fetchRequest()
        orphanedProblemsRequest.predicate = NSPredicate(format: "day == nil")
        let orphanedProblems = try context.fetch(orphanedProblemsRequest)
        
        for problem in orphanedProblems {
            context.delete(problem)
            removedCount += 1
        }
        
        // Remove orphaned system design topics
        let orphanedTopicsRequest: NSFetchRequest<SystemDesignTopic> = SystemDesignTopic.fetchRequest()
        orphanedTopicsRequest.predicate = NSPredicate(format: "day == nil")
        let orphanedTopics = try context.fetch(orphanedTopicsRequest)
        
        for topic in orphanedTopics {
            context.delete(topic)
            removedCount += 1
        }
        
        return removedCount
    }
}

// MARK: - Validation Report

struct ValidationReport {
    var errors: [String] = []
    var warnings: [String] = []
    
    // Counts
    var totalDays: Int = 0
    var totalDSAProblems: Int = 0
    var totalSystemDesignTopics: Int = 0
    var totalUserSettings: Int = 0
    
    // Error counts
    var invalidDays: Int = 0
    var invalidProgressValues: Int = 0
    var missingDays: Int = 0
    var duplicateDays: Int = 0
    var emptyRequiredFields: Int = 0
    var invalidDifficulties: Int = 0
    var negativeTimeValues: Int = 0
    var negativeStreakValues: Int = 0
    var orphanedRecords: Int = 0
    var multipleUserSettings: Int = 0
    
    // Warning counts
    var missingDates: Int = 0
    var progressMismatches: Int = 0
    var missingCompletionDates: Int = 0
    var inconsistentCompletionStatus: Int = 0
    var inconsistentStreakValues: Int = 0
    var missingNotificationTimes: Int = 0
    var duplicateProblems: Int = 0
    var duplicateTopics: Int = 0
    
    var isValid: Bool {
        return errors.isEmpty
    }
    
    var hasWarnings: Bool {
        return !warnings.isEmpty
    }
    
    var summary: String {
        var summary = "Validation Report:\n"
        summary += "- Total Days: \(totalDays)\n"
        summary += "- Total DSA Problems: \(totalDSAProblems)\n"
        summary += "- Total System Design Topics: \(totalSystemDesignTopics)\n"
        summary += "- Total User Settings: \(totalUserSettings)\n"
        summary += "- Errors: \(errors.count)\n"
        summary += "- Warnings: \(warnings.count)\n"
        
        if !isValid {
            summary += "\nErrors found:\n"
            for error in errors {
                summary += "  • \(error)\n"
            }
        }
        
        if hasWarnings {
            summary += "\nWarnings:\n"
            for warning in warnings {
                summary += "  • \(warning)\n"
            }
        }
        
        return summary
    }
}