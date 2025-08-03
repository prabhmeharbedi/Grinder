import Foundation

struct IntegrityResult {
    let severity: Severity
    let issues: [String]
    let repaired: [String]
    let success: Bool
    
    var hasIssues: Bool {
        return !issues.isEmpty || severity != .healthy
    }
    
    enum Severity {
        case healthy
        case minor
        case major
        case critical
        
        var description: String {
            switch self {
            case .healthy: return "Healthy"
            case .minor: return "Minor Issues"
            case .major: return "Major Issues"
            case .critical: return "Critical Issues"
            }
        }
    }
    
    static func healthy() -> IntegrityResult {
        return IntegrityResult(severity: .healthy, issues: [], repaired: [], success: true)
    }
    
    static func withIssues(_ issues: [String], severity: Severity) -> IntegrityResult {
        return IntegrityResult(severity: severity, issues: issues, repaired: [], success: false)
    }
}

struct RecoveryResult {
    let success: Bool
    let method: RecoveryMethod
    let message: String
    let backupUsed: String?
    
    enum RecoveryMethod {
        case sqliteBackup
        case jsonBackup
        case curriculumReinit
        case dataRepair
        case none
    }
    
    static func success(method: RecoveryMethod, message: String, backupUsed: String? = nil) -> RecoveryResult {
        return RecoveryResult(success: true, method: method, message: message, backupUsed: backupUsed)
    }
    
    static func failure(message: String) -> RecoveryResult {
        return RecoveryResult(success: false, method: .none, message: message, backupUsed: nil)
    }
}

enum DataIntegrityStatus {
    case verified
    case issues(String)
    case corrupted(String)
    case unknown
    
    var description: String {
        switch self {
        case .verified: return "Verified"
        case .issues(let message): return "Issues: \(message)"
        case .corrupted(let message): return "Corrupted: \(message)"
        case .unknown: return "Unknown"
        }
    }
    
    var isHealthy: Bool {
        switch self {
        case .verified: return true
        default: return false
        }
    }
}