import CoreData
import Foundation

// MARK: - Day Entity Extensions
extension Day {
    
    // MARK: - Validation
    override public func validateForInsert() throws {
        try super.validateForInsert()
        try validateDayData()
    }
    
    override public func validateForUpdate() throws {
        try super.validateForUpdate()
        try validateDayData()
    }
    
    private func validateDayData() throws {
        // Validate day number is within valid range
        if dayNumber < 1 || dayNumber > 100 {
            throw ValidationError.invalidDayNumber(dayNumber)
        }
        
        // Validate progress values are within 0.0-1.0 range
        if dsaProgress < 0.0 || dsaProgress > 1.0 {
            throw ValidationError.invalidProgressValue("DSA", dsaProgress)
        }
        
        if systemDesignProgress < 0.0 || systemDesignProgress > 1.0 {
            throw ValidationError.invalidProgressValue("System Design", systemDesignProgress)
        }
        
        // Ensure dates are set
        if createdAt == nil {
            createdAt = Date()
        }
        
        updatedAt = Date()
    }
    
    // MARK: - Computed Properties
    var overallProgress: Float {
        return (dsaProgress + systemDesignProgress) / 2.0
    }
    
    var dsaProblemsArray: [DSAProblem] {
        let set = dsaProblems as? Set<DSAProblem> ?? []
        return set.sorted { ($0.problemName ?? "") < ($1.problemName ?? "") }
    }
    
    var systemDesignTopicsArray: [SystemDesignTopic] {
        let set = systemDesignTopics as? Set<SystemDesignTopic> ?? []
        return set.sorted { ($0.topicName ?? "") < ($1.topicName ?? "") }
    }
    
    // MARK: - Progress Calculation
    func updateProgress() {
        let dsaProblems = dsaProblemsArray
        let systemTopics = systemDesignTopicsArray
        
        // Calculate DSA progress
        if !dsaProblems.isEmpty {
            let completedDSA = dsaProblems.filter { $0.isCompleted }.count
            dsaProgress = Float(completedDSA) / Float(dsaProblems.count)
        } else {
            dsaProgress = 0.0
        }
        
        // Calculate System Design progress
        if !systemTopics.isEmpty {
            let completedTopics = systemTopics.filter { $0.isCompleted }.count
            systemDesignProgress = Float(completedTopics) / Float(systemTopics.count)
        } else {
            systemDesignProgress = 0.0
        }
        
        // Update completion status - only complete if both sections are 100%
        isCompleted = dsaProgress >= 1.0 && systemDesignProgress >= 1.0
        
        updatedAt = Date()
    }
    
    // MARK: - Detailed Progress Metrics
    var dsaCompletionStats: (completed: Int, total: Int, percentage: Float) {
        let problems = dsaProblemsArray
        let completed = problems.filter { $0.isCompleted }.count
        let total = problems.count
        let percentage = total > 0 ? Float(completed) / Float(total) : 0.0
        return (completed, total, percentage)
    }
    
    var systemDesignCompletionStats: (completed: Int, total: Int, percentage: Float) {
        let topics = systemDesignTopicsArray
        let completed = topics.filter { $0.isCompleted }.count
        let total = topics.count
        let percentage = total > 0 ? Float(completed) / Float(total) : 0.0
        return (completed, total, percentage)
    }
    
    var totalTimeSpent: Int32 {
        let dsaTime = dsaProblemsArray.reduce(0) { $0 + $1.timeSpent }
        return dsaTime
    }
    
    var bonusProblemsCount: Int {
        return dsaProblemsArray.filter { $0.isBonusProblem }.count
    }
    
    var curriculumProblemsCount: Int {
        return dsaProblemsArray.filter { !$0.isBonusProblem }.count
    }
    
    // MARK: - Bonus Problem Management
    func addBonusProblem(name: String, leetcodeNumber: String?, difficulty: String) -> DSAProblem? {
        guard let context = managedObjectContext else { return nil }
        
        let bonusProblem = DSAProblem(context: context)
        bonusProblem.problemName = name
        bonusProblem.leetcodeNumber = leetcodeNumber
        bonusProblem.difficulty = difficulty
        bonusProblem.isCompleted = false
        bonusProblem.isBonusProblem = true
        bonusProblem.timeSpent = 0
        bonusProblem.createdAt = Date()
        bonusProblem.updatedAt = Date()
        bonusProblem.day = self
        
        // Update progress after adding bonus problem
        updateProgress()
        
        return bonusProblem
    }
    
    func removeBonusProblem(_ problem: DSAProblem) {
        guard problem.isBonusProblem, let context = managedObjectContext else { return }
        
        context.delete(problem)
        updateProgress()
    }
}

// MARK: - DSAProblem Entity Extensions
extension DSAProblem {
    
    // MARK: - Validation
    override public func validateForInsert() throws {
        try super.validateForInsert()
        try validateProblemData()
    }
    
    override public func validateForUpdate() throws {
        try super.validateForUpdate()
        try validateProblemData()
    }
    
    private func validateProblemData() throws {
        // Validate problem name is not empty
        guard let name = problemName, !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ValidationError.emptyRequiredField("Problem Name")
        }
        
        // Validate difficulty is valid
        if let diff = difficulty {
            let validDifficulties = ["Easy", "Medium", "Hard"]
            if !validDifficulties.contains(diff) {
                throw ValidationError.invalidDifficulty(diff)
            }
        }
        
        // Validate time spent is non-negative
        if timeSpent < 0 {
            throw ValidationError.invalidTimeSpent(timeSpent)
        }
        
        // Ensure dates are set
        if createdAt == nil {
            createdAt = Date()
        }
        
        updatedAt = Date()
        
        // Set completion timestamp when marked complete
        if isCompleted && completedAt == nil {
            completedAt = Date()
        } else if !isCompleted {
            completedAt = nil
        }
    }
    
    // MARK: - Computed Properties
    var difficultyColor: String {
        switch difficulty {
        case "Easy": return "green"
        case "Medium": return "orange"
        case "Hard": return "red"
        default: return "gray"
        }
    }
    
    var leetcodeURL: URL? {
        guard let number = leetcodeNumber else { return nil }
        return URL(string: "https://leetcode.com/problems/\(number)/")
    }
    
    var hasNotes: Bool {
        return notes != nil && !notes!.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var hasTimeTracked: Bool {
        return timeSpent > 0
    }
    
    var formattedTimeSpent: String {
        if timeSpent == 0 {
            return "No time tracked"
        } else if timeSpent < 60 {
            return "\(timeSpent)m"
        } else {
            let hours = timeSpent / 60
            let minutes = timeSpent % 60
            return minutes > 0 ? "\(hours)h \(minutes)m" : "\(hours)h"
        }
    }
    
    // MARK: - Time Tracking Methods
    func addTime(minutes: Int32) {
        guard minutes > 0 else { return }
        timeSpent += minutes
        updatedAt = Date()
    }
    
    func setTime(minutes: Int32) {
        guard minutes >= 0 else { return }
        timeSpent = minutes
        updatedAt = Date()
    }
    
    // MARK: - Notes Management
    func updateNotes(_ newNotes: String?) {
        let trimmedNotes = newNotes?.trimmingCharacters(in: .whitespacesAndNewlines)
        notes = trimmedNotes?.isEmpty == true ? nil : trimmedNotes
        updatedAt = Date()
    }
}

// MARK: - SystemDesignTopic Entity Extensions
extension SystemDesignTopic {
    
    // MARK: - Validation
    override public func validateForInsert() throws {
        try super.validateForInsert()
        try validateTopicData()
    }
    
    override public func validateForUpdate() throws {
        try super.validateForUpdate()
        try validateTopicData()
    }
    
    private func validateTopicData() throws {
        // Validate topic name is not empty
        guard let name = topicName, !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ValidationError.emptyRequiredField("Topic Name")
        }
        
        // Ensure dates are set
        if createdAt == nil {
            createdAt = Date()
        }
        
        updatedAt = Date()
        
        // Set completion timestamp when marked complete
        if isCompleted && completedAt == nil {
            completedAt = Date()
        } else if !isCompleted {
            completedAt = nil
        }
    }
    
    // MARK: - Computed Properties
    var overallCompletion: Bool {
        return videoWatched && taskCompleted
    }
    
    var hasNotes: Bool {
        return notes != nil && !notes!.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var completionPercentage: Float {
        var completed: Float = 0
        if videoWatched { completed += 0.5 }
        if taskCompleted { completed += 0.5 }
        return completed
    }
    
    func updateCompletionStatus() {
        let wasCompleted = isCompleted
        isCompleted = overallCompletion
        
        if isCompleted && !wasCompleted {
            completedAt = Date()
        } else if !isCompleted && wasCompleted {
            completedAt = nil
        }
        
        updatedAt = Date()
        
        // Update the day's progress when topic completion changes
        day?.updateProgress()
    }
    
    // MARK: - Notes Management
    func updateNotes(_ newNotes: String?) {
        let trimmedNotes = newNotes?.trimmingCharacters(in: .whitespacesAndNewlines)
        notes = trimmedNotes?.isEmpty == true ? nil : trimmedNotes
        updatedAt = Date()
    }
    
    // MARK: - Task Management
    func toggleVideoWatched() {
        videoWatched.toggle()
        updateCompletionStatus()
    }
    
    func toggleTaskCompleted() {
        taskCompleted.toggle()
        updateCompletionStatus()
    }
}

// MARK: - UserSettings Entity Extensions
extension UserSettings {
    
    // MARK: - Validation
    override public func validateForInsert() throws {
        try super.validateForInsert()
        try validateSettingsData()
    }
    
    override public func validateForUpdate() throws {
        try super.validateForUpdate()
        try validateSettingsData()
    }
    
    private func validateSettingsData() throws {
        // Validate streak values are non-negative
        if currentStreak < 0 {
            throw ValidationError.invalidStreakValue("current", currentStreak)
        }
        
        if longestStreak < 0 {
            throw ValidationError.invalidStreakValue("longest", longestStreak)
        }
        
        // Ensure longest streak is at least as long as current streak
        if longestStreak < currentStreak {
            longestStreak = currentStreak
        }
        
        // Set default notification times if not set
        if morningNotificationTime == nil {
            let calendar = Calendar.current
            morningNotificationTime = calendar.date(bySettingHour: 8, minute: 0, second: 0, of: Date())
        }
        
        if eveningNotificationTime == nil {
            let calendar = Calendar.current
            eveningNotificationTime = calendar.date(bySettingHour: 20, minute: 0, second: 0, of: Date())
        }
        
        // Set start date if not set
        if startDate == nil {
            startDate = Date()
        }
    }
    
    // MARK: - Computed Properties
    var daysSinceStart: Int {
        guard let start = startDate else { return 0 }
        return Calendar.current.dateComponents([.day], from: start, to: Date()).day ?? 0
    }
    
    var currentDayNumber: Int {
        return min(daysSinceStart + 1, 100)
    }
}

// MARK: - Validation Errors
enum ValidationError: LocalizedError {
    case invalidDayNumber(Int32)
    case invalidProgressValue(String, Float)
    case emptyRequiredField(String)
    case invalidDifficulty(String)
    case invalidTimeSpent(Int32)
    case invalidStreakValue(String, Int32)
    
    var errorDescription: String? {
        switch self {
        case .invalidDayNumber(let number):
            return "Day number \(number) is invalid. Must be between 1 and 100."
        case .invalidProgressValue(let type, let value):
            return "\(type) progress value \(value) is invalid. Must be between 0.0 and 1.0."
        case .emptyRequiredField(let field):
            return "\(field) cannot be empty."
        case .invalidDifficulty(let difficulty):
            return "Difficulty '\(difficulty)' is invalid. Must be Easy, Medium, or Hard."
        case .invalidTimeSpent(let time):
            return "Time spent \(time) is invalid. Must be non-negative."
        case .invalidStreakValue(let type, let value):
            return "\(type.capitalized) streak value \(value) is invalid. Must be non-negative."
        }
    }
}