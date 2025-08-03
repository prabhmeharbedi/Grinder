import SwiftUI
import CoreData

// MARK: - Error Types
enum AppError: LocalizedError, Identifiable {
    case dataCorruption(String)
    case backupFailed(String)
    case exportFailed(String)
    case notificationPermissionDenied
    case coreDataError(Error)
    case fileSystemError(Error)
    case networkError(Error)
    
    var id: String {
        switch self {
        case .dataCorruption: return "dataCorruption"
        case .backupFailed: return "backupFailed"
        case .exportFailed: return "exportFailed"
        case .notificationPermissionDenied: return "notificationPermissionDenied"
        case .coreDataError: return "coreDataError"
        case .fileSystemError: return "fileSystemError"
        case .networkError: return "networkError"
        }
    }
    
    var errorDescription: String? {
        switch self {
        case .dataCorruption(let message):
            return "Data integrity issue: \(message)"
        case .backupFailed(let reason):
            return "Backup failed: \(reason)"
        case .exportFailed(let reason):
            return "Export failed: \(reason)"
        case .notificationPermissionDenied:
            return "Notification permission is required for reminders"
        case .coreDataError(let error):
            return "Database error: \(error.localizedDescription)"
        case .fileSystemError(let error):
            return "File system error: \(error.localizedDescription)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .dataCorruption:
            return "Try restoring from a recent backup or contact support."
        case .backupFailed:
            return "Check available storage space and try again."
        case .exportFailed:
            return "Ensure you have sufficient storage space and try again."
        case .notificationPermissionDenied:
            return "Go to Settings > Notifications to enable permissions."
        case .coreDataError:
            return "Restart the app. If the problem persists, try restoring from backup."
        case .fileSystemError:
            return "Check available storage space and app permissions."
        case .networkError:
            return "Check your internet connection and try again."
        }
    }
}

// MARK: - Error Handler
class ErrorHandler: ObservableObject {
    static let shared = ErrorHandler()
    
    @Published var currentError: AppError?
    @Published var isShowingError = false
    @Published var errorHistory: [ErrorLogEntry] = []
    
    private let maxErrorHistoryCount = 50
    
    private init() {
        loadErrorHistory()
    }
    
    func handle(error: AppError, source: String = "") {
        print("❌ Error handled from \(source): \(error.errorDescription ?? "Unknown error")")
        
        // Log the error
        logError(error, source: source)
        
        // Announce error for accessibility
        AccessibilityManager.shared.announceForVoiceOver(
            VoiceOverHelper.errorAccessibilityAnnouncement(for: error)
        )
        
        // Attempt automatic recovery
        attemptAutomaticRecovery(for: error)
        
        // Show error to user if manual intervention is needed
        DispatchQueue.main.async {
            self.currentError = error
            self.isShowingError = true
        }
    }
    
    private func logError(_ error: AppError, source: String) {
        let entry = ErrorLogEntry(
            error: error,
            source: source,
            timestamp: Date()
        )
        
        errorHistory.insert(entry, at: 0)
        
        // Limit history size
        if errorHistory.count > maxErrorHistoryCount {
            errorHistory = Array(errorHistory.prefix(maxErrorHistoryCount))
        }
        
        // Persist error history
        saveErrorHistory()
    }
    
    private func attemptAutomaticRecovery(for error: AppError) {
        switch error {
        case .dataCorruption:
            RecoveryManager.shared.attemptDataRecovery()
            
        case .backupFailed:
            // Try alternative backup method
            BackupManager.shared.createBackup(format: .sqlite) { success, _ in
                if success {
                    print("✅ Backup recovery successful using SQLite format")
                }
            }
            
        case .coreDataError:
            // Attempt Core Data recovery
            RecoveryManager.shared.recoverCoreDataContext()
            
        case .notificationPermissionDenied:
            // Show guidance for enabling notifications
            break
            
        default:
            break
        }
    }
    
    private func loadErrorHistory() {
        if let data = UserDefaults.standard.data(forKey: "ErrorHistory"),
           let decoded = try? JSONDecoder().decode([ErrorLogEntry].self, from: data) {
            errorHistory = decoded
        }
    }
    
    private func saveErrorHistory() {
        if let encoded = try? JSONEncoder().encode(errorHistory) {
            UserDefaults.standard.set(encoded, forKey: "ErrorHistory")
        }
    }
    
    func clearError() {
        currentError = nil
        isShowingError = false
    }
    
    func retryLastOperation() {
        // Implement retry logic based on error type
        clearError()
    }
}

// MARK: - Error Log Entry
struct ErrorLogEntry: Codable, Identifiable {
    let id = UUID()
    let errorType: String
    let errorDescription: String
    let source: String
    let timestamp: Date
    
    init(error: AppError, source: String, timestamp: Date) {
        self.errorType = error.id
        self.errorDescription = error.errorDescription ?? "Unknown error"
        self.source = source
        self.timestamp = timestamp
    }
}