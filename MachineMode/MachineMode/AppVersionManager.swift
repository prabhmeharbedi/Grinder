import Foundation
import UIKit
import UserNotifications

class AppVersionManager: ObservableObject {
    static let shared = AppVersionManager()
    
    @Published var currentVersion: String = ""
    @Published var installDate: Date?
    @Published var daysUntilExpiration: Int = 7
    @Published var isExpiringSoon: Bool = false
    @Published var hasDetectedRebuild: Bool = false
    @Published var lastRebuildDate: Date?
    @Published var dataIntegrityStatus: DataIntegrityStatus = .unknown
    
    private let userDefaults = UserDefaults.standard
    private let calendar = Calendar.current
    private let expirationDays = 7 // Development certificate expires after 7 days
    private let warningThreshold = 2 // Show warnings when 2 days or less remain
    
    enum DataIntegrityStatus {
        case unknown
        case verified
        case issues(String)
        case corrupted(String)
        
        var description: String {
            switch self {
            case .unknown:
                return "Unknown"
            case .verified:
                return "Verified"
            case .issues(let details):
                return "Issues: \(details)"
            case .corrupted(let details):
                return "Corrupted: \(details)"
            }
        }
    }
    
    private init() {
        loadStoredData()
        checkForRebuild()
        updateExpirationStatus()
        setupExpirationTimer()
    }
    
    // MARK: - Public Interface
    
    /// Checks for app rebuild and handles necessary actions
    func checkForRebuild() {
        let currentVersion = getCurrentVersion()
        let storedVersion = userDefaults.string(forKey: "AppVersion")
        let currentBuildDate = getBuildDate()
        
        self.currentVersion = currentVersion
        
        // Check if this is a new installation or rebuild
        if storedVersion != currentVersion || isNewInstallation() {
            handleRebuildDetected(
                currentVersion: currentVersion,
                previousVersion: storedVersion,
                buildDate: currentBuildDate
            )
        }
        
        // Always update stored version
        userDefaults.set(currentVersion, forKey: "AppVersion")
        
        // Set install date if not already set
        if userDefaults.object(forKey: "InstallDate") == nil {
            let installDate = Date()
            userDefaults.set(installDate, forKey: "InstallDate")
            self.installDate = installDate
            print("📅 Install date set: \(installDate)")
        }
        
        // Verify data integrity after any rebuild
        verifyDataIntegrity()
    }
    
    /// Returns the number of days until the app expires
    func getDaysUntilExpiration() -> Int {
        guard let installDate = getInstallDate() else {
            return expirationDays
        }
        
        let daysSinceInstall = calendar.dateComponents([.day], from: installDate, to: Date()).day ?? 0
        let daysRemaining = expirationDays - daysSinceInstall
        
        return max(0, daysRemaining)
    }
    
    /// Returns the exact expiration date
    func getExpirationDate() -> Date? {
        guard let installDate = getInstallDate() else { return nil }
        return calendar.date(byAdding: .day, value: expirationDays, to: installDate)
    }
    
    /// Checks if the app is expiring soon (within warning threshold)
    func isAppExpiringSoon() -> Bool {
        return getDaysUntilExpiration() <= warningThreshold
    }
    
    /// Checks if the app has expired
    func hasAppExpired() -> Bool {
        return getDaysUntilExpiration() <= 0
    }
    
    /// Triggers manual backup creation before rebuild
    func createPreRebuildBackup(completion: @escaping (Bool, String?) -> Void) {
        print("🔄 Creating pre-rebuild backup...")
        
        BackupManager.shared.createManualBackup(format: .both) { success, error in
            if success {
                print("✅ Pre-rebuild backup created successfully")
                self.userDefaults.set(Date(), forKey: "LastPreRebuildBackup")
            } else {
                print("❌ Pre-rebuild backup failed: \(error ?? "Unknown error")")
            }
            completion(success, error)
        }
    }
    
    /// Schedules rebuild warning notifications
    func scheduleRebuildWarningNotifications() {
        let daysUntilExpiration = getDaysUntilExpiration()
        
        // Use NotificationManager for rebuild reminders
        if daysUntilExpiration <= 3 {
            NotificationManager.shared.scheduleRebuildReminder(daysUntilExpiration: daysUntilExpiration)
        }
        
        print("📅 Rebuild warning notifications scheduled via NotificationManager")
    }
    
    /// Schedules a success notification after rebuild
    func scheduleRebuildSuccessNotification() {
        // Use NotificationManager for rebuild success notification
        NotificationManager.shared.scheduleRebuildNotification()
        print("✅ Rebuild success notification scheduled via NotificationManager")
    }
    
    // MARK: - Private Implementation
    
    private func loadStoredData() {
        installDate = userDefaults.object(forKey: "InstallDate") as? Date
        lastRebuildDate = userDefaults.object(forKey: "LastRebuildDate") as? Date
        currentVersion = getCurrentVersion()
    }
    
    private func handleRebuildDetected(currentVersion: String, previousVersion: String?, buildDate: Date?) {
        print("🔄 App rebuild detected!")
        print("Previous version: \(previousVersion ?? "none")")
        print("Current version: \(currentVersion)")
        
        hasDetectedRebuild = true
        lastRebuildDate = Date()
        
        // Store rebuild information
        userDefaults.set(Date(), forKey: "LastRebuildDate")
        userDefaults.set(currentVersion, forKey: "AppVersion")
        
        // Create automatic backup
        createAutomaticRebuildBackup()
        
        // Verify data integrity
        verifyDataIntegrity()
        
        // Schedule success notification
        scheduleRebuildSuccessNotification()
        
        // Update expiration warnings
        scheduleRebuildWarningNotifications()
        
        // Log rebuild event for analytics
        logRebuildEvent(previousVersion: previousVersion, currentVersion: currentVersion)
    }
    
    private func createAutomaticRebuildBackup() {
        print("🔄 Creating automatic rebuild backup...")
        
        BackupManager.shared.createManualBackup(format: .both) { success, error in
            if success {
                print("✅ Automatic rebuild backup created")
                self.userDefaults.set(Date(), forKey: "LastRebuildBackup")
            } else {
                print("❌ Automatic rebuild backup failed: \(error ?? "Unknown error")")
            }
        }
    }
    
    private func verifyDataIntegrity() {
        print("🔍 Verifying data integrity after rebuild...")
        
        DispatchQueue.global(qos: .utility).async {
            let integrityResult = BackupRecoveryManager.shared.verifyAndRepairDataIntegrity()
            
            DispatchQueue.main.async {
                switch integrityResult.severity {
                case .healthy:
                    self.dataIntegrityStatus = .verified
                    print("✅ Data integrity verification passed")
                    
                case .minor:
                    self.dataIntegrityStatus = .issues("Minor issues found and repaired")
                    print("⚠️ Minor data integrity issues found and repaired")
                    
                case .major:
                    self.dataIntegrityStatus = .issues("Major issues found: \(integrityResult.issues.joined(separator: ", "))")
                    print("⚠️ Major data integrity issues found")
                    
                case .critical:
                    self.dataIntegrityStatus = .corrupted("Critical data corruption detected")
                    print("❌ Critical data integrity issues detected")
                    
                    // Attempt recovery for critical issues
                    self.attemptDataRecovery()
                }
                
                // Log integrity check results
                self.logIntegrityCheckResults(integrityResult)
            }
        }
    }
    
    private func attemptDataRecovery() {
        print("🚨 Attempting data recovery due to critical integrity issues...")
        
        DispatchQueue.global(qos: .utility).async {
            let recoveryResult = BackupRecoveryManager.shared.attemptRecovery()
            
            DispatchQueue.main.async {
                if recoveryResult.success {
                    self.dataIntegrityStatus = .verified
                    print("✅ Data recovery successful: \(recoveryResult.message)")
                    
                    // Schedule recovery success notification
                    self.scheduleDataRecoveryNotification(success: true, message: recoveryResult.message)
                } else {
                    self.dataIntegrityStatus = .corrupted("Recovery failed: \(recoveryResult.message)")
                    print("❌ Data recovery failed: \(recoveryResult.message)")
                    
                    // Schedule recovery failure notification
                    self.scheduleDataRecoveryNotification(success: false, message: recoveryResult.message)
                }
            }
        }
    }
    
    private func updateExpirationStatus() {
        daysUntilExpiration = getDaysUntilExpiration()
        isExpiringSoon = isAppExpiringSoon()
        
        if isExpiringSoon {
            print("⚠️ App is expiring soon: \(daysUntilExpiration) days remaining")
        }
        
        if hasAppExpired() {
            print("🚨 App has expired! Please rebuild to continue using.")
        }
    }
    
    private func setupExpirationTimer() {
        // Update expiration status every hour
        Timer.scheduledTimer(withTimeInterval: 3600, repeats: true) { _ in
            self.updateExpirationStatus()
        }
        
        // Also update when app becomes active
        NotificationCenter.default.addObserver(
            forName: UIApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { _ in
            self.updateExpirationStatus()
        }
    }
    

    
    private func scheduleDataRecoveryNotification(success: Bool, message: String) {
        let center = UNUserNotificationCenter.current()
        
        let content = UNMutableNotificationContent()
        content.title = success ? "Data Recovery Successful" : "Data Recovery Failed"
        content.body = message
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 2, repeats: false)
        let request = UNNotificationRequest(
            identifier: "data_recovery_\(success ? "success" : "failure")",
            content: content,
            trigger: trigger
        )
        
        center.add(request) { error in
            if let error = error {
                print("❌ Failed to schedule data recovery notification: \(error)")
            }
        }
    }
    
    // MARK: - Utility Methods
    
    private func getCurrentVersion() -> String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version).\(build)"
    }
    
    private func getBuildDate() -> Date? {
        guard let infoPath = Bundle.main.path(forResource: "Info", ofType: "plist"),
              let infoAttrs = try? FileManager.default.attributesOfItem(atPath: infoPath),
              let buildDate = infoAttrs[.modificationDate] as? Date else {
            return nil
        }
        return buildDate
    }
    
    private func getInstallDate() -> Date? {
        return userDefaults.object(forKey: "InstallDate") as? Date
    }
    
    private func isNewInstallation() -> Bool {
        return userDefaults.object(forKey: "InstallDate") == nil
    }
    
    private func logRebuildEvent(previousVersion: String?, currentVersion: String) {
        let rebuildInfo: [String: Any] = [
            "previousVersion": previousVersion ?? "none",
            "currentVersion": currentVersion,
            "rebuildDate": ISO8601DateFormatter().string(from: Date()),
            "daysUntilExpiration": getDaysUntilExpiration(),
            "installDate": getInstallDate() != nil ? ISO8601DateFormatter().string(from: getInstallDate()!) : "unknown"
        ]
        
        userDefaults.set(rebuildInfo, forKey: "LastRebuildInfo")
        print("📊 Rebuild event logged: \(rebuildInfo)")
    }
    
    private func logIntegrityCheckResults(_ result: IntegrityResult) {
        let integrityInfo: [String: Any] = [
            "severity": result.severity.description,
            "issues": result.issues,
            "repaired": result.repaired,
            "success": result.success,
            "checkDate": ISO8601DateFormatter().string(from: Date())
        ]
        
        userDefaults.set(integrityInfo, forKey: "LastIntegrityCheck")
        print("📊 Integrity check logged: \(integrityInfo)")
    }
    
    // MARK: - Public Utility Methods
    
    /// Returns formatted string showing days until expiration
    func getExpirationStatusText() -> String {
        let days = getDaysUntilExpiration()
        
        if hasAppExpired() {
            return "App has expired - Please rebuild"
        } else if days == 1 {
            return "Expires in 1 day"
        } else {
            return "Expires in \(days) days"
        }
    }
    
    /// Returns color for expiration status (for UI)
    func getExpirationStatusColor() -> String {
        let days = getDaysUntilExpiration()
        
        if hasAppExpired() {
            return "red"
        } else if days <= 1 {
            return "red"
        } else if days <= 2 {
            return "orange"
        } else {
            return "green"
        }
    }
    
    /// Returns detailed app status information
    func getAppStatusInfo() -> AppStatusInfo {
        return AppStatusInfo(
            currentVersion: currentVersion,
            installDate: installDate,
            lastRebuildDate: lastRebuildDate,
            daysUntilExpiration: getDaysUntilExpiration(),
            expirationDate: getExpirationDate(),
            isExpiringSoon: isAppExpiringSoon(),
            hasExpired: hasAppExpired(),
            dataIntegrityStatus: dataIntegrityStatus,
            hasDetectedRebuild: hasDetectedRebuild
        )
    }
}

// MARK: - Supporting Types

struct AppStatusInfo {
    let currentVersion: String
    let installDate: Date?
    let lastRebuildDate: Date?
    let daysUntilExpiration: Int
    let expirationDate: Date?
    let isExpiringSoon: Bool
    let hasExpired: Bool
    let dataIntegrityStatus: AppVersionManager.DataIntegrityStatus
    let hasDetectedRebuild: Bool
    
    var formattedInstallDate: String {
        guard let installDate = installDate else { return "Unknown" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: installDate)
    }
    
    var formattedExpirationDate: String {
        guard let expirationDate = expirationDate else { return "Unknown" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: expirationDate)
    }
    
    var formattedLastRebuildDate: String {
        guard let lastRebuildDate = lastRebuildDate else { return "Never" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: lastRebuildDate)
    }
}