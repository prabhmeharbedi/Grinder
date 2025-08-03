import SwiftUI

struct VoiceOverHelper {
    
    // MARK: - Problem Row Accessibility
    
    static func problemRowAccessibilityLabel(
        problemName: String,
        difficulty: String,
        isCompleted: Bool,
        timeSpent: Int32,
        hasNotes: Bool
    ) -> String {
        var components = [problemName]
        
        components.append("Difficulty: \(difficulty)")
        
        if isCompleted {
            components.append("Completed")
            if timeSpent > 0 {
                let hours = timeSpent / 60
                let minutes = timeSpent % 60
                if hours > 0 {
                    components.append("Time spent: \(hours) hours and \(minutes) minutes")
                } else {
                    components.append("Time spent: \(minutes) minutes")
                }
            }
        } else {
            components.append("Not completed")
        }
        
        if hasNotes {
            components.append("Has notes")
        }
        
        return components.joined(separator: ". ")
    }
    
    static func problemRowAccessibilityHint(isCompleted: Bool) -> String {
        return isCompleted ? "Double tap to mark as incomplete" : "Double tap to mark as complete"
    }
    
    // MARK: - Progress Accessibility
    
    static func progressAccessibilityLabel(current: Int, total: Int, percentage: Double) -> String {
        return "Progress: \(current) of \(total) completed, \(String(format: "%.0f", percentage))% complete"
    }
    
    static func streakAccessibilityLabel(current: Int, longest: Int) -> String {
        let currentText = current == 1 ? "1 day" : "\(current) days"
        let longestText = longest == 1 ? "1 day" : "\(longest) days"
        return "Current streak: \(currentText). Longest streak: \(longestText)"
    }
    
    // MARK: - Navigation Accessibility
    
    static func tabAccessibilityLabel(for tab: String, hasNotification: Bool = false) -> String {
        var label = "\(tab) tab"
        if hasNotification {
            label += ", has notification"
        }
        return label
    }
    
    // MARK: - Settings Accessibility
    
    static func settingRowAccessibilityLabel(title: String, value: String) -> String {
        return "\(title): \(value)"
    }
    
    static func settingRowAccessibilityHint(for setting: String) -> String {
        switch setting {
        case "notifications":
            return "Double tap to configure notification settings"
        case "backup":
            return "Double tap to create backup"
        case "export":
            return "Double tap to export progress"
        case "theme":
            return "Double tap to change app theme"
        default:
            return "Double tap to modify this setting"
        }
    }
    
    // MARK: - Error Accessibility
    
    static func errorAccessibilityAnnouncement(for error: AppError) -> String {
        switch error {
        case .dataCorruption:
            return "Data integrity issue detected. Recovery options available."
        case .backupFailed:
            return "Backup creation failed. Please try again."
        case .exportFailed:
            return "Export failed. Please check available storage."
        case .notificationPermissionDenied:
            return "Notification permission required for full app functionality."
        default:
            return "An error occurred. Please try again or contact support."
        }
    }
}