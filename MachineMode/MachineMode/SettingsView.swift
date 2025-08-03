import SwiftUI
import CoreData

struct SettingsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \UserSettings.startDate, ascending: true)],
        animation: .default
    )
    private var userSettings: FetchedResults<UserSettings>
    
    @StateObject private var appVersionManager = AppVersionManager.shared
    @StateObject private var backupManager = BackupManager.shared
    @StateObject private var exportManager = ExportManager.shared
    @StateObject private var notificationManager = NotificationManager.shared
    
    @State private var showingNotificationTimePicker = false
    @State private var showingBackupAlert = false
    @State private var showingExportAlert = false
    @State private var showingDataRecoveryAlert = false
    @State private var showingRebuildInstructions = false
    
    @State private var tempMorningTime = Date()
    @State private var tempEveningTime = Date()
    @State private var notificationsEnabled = true
    
    @State private var backupResult: (success: Bool, message: String?) = (false, nil)
    @State private var exportResult: (success: Bool, message: String?) = (false, nil)
    @State private var exportedFiles: [URL] = []
    
    private var currentSettings: UserSettings? {
        userSettings.first
    }
    
    var body: some View {
        NavigationView {
            List {
                // Notification Settings Section
                Section("🔔 Notifications") {
                    Toggle("Enable Notifications", isOn: $notificationsEnabled)
                        .onChange(of: notificationsEnabled) { enabled in
                            updateNotificationSettings(enabled: enabled)
                        }
                    
                    if notificationsEnabled {
                        Button(action: {
                            loadCurrentNotificationTimes()
                            showingNotificationTimePicker = true
                        }) {
                            HStack {
                                Image(systemName: "clock")
                                    .foregroundColor(.blue)
                                VStack(alignment: .leading) {
                                    Text("Notification Times")
                                        .foregroundColor(.primary)
                                    Text(getNotificationTimesText())
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.secondary)
                                    .font(.caption)
                            }
                        }
                        
                        Button(action: {
                            testNotifications()
                        }) {
                            HStack {
                                Image(systemName: "bell.badge")
                                    .foregroundColor(.orange)
                                Text("Test Notifications")
                                    .foregroundColor(.primary)
                                Spacer()
                            }
                        }
                    }
                }
                
                // Backup Management Section
                Section("💾 Backup Management") {
                    HStack {
                        Image(systemName: "externaldrive")
                            .foregroundColor(.green)
                        VStack(alignment: .leading) {
                            Text("Last Backup")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(getLastBackupText())
                                .font(.body)
                                .fontWeight(.medium)
                        }
                        Spacer()
                    }
                    
                    Button(action: {
                        createManualBackup()
                    }) {
                        HStack {
                            Image(systemName: "plus.circle")
                                .foregroundColor(.blue)
                            Text("Create Manual Backup")
                                .foregroundColor(.primary)
                            Spacer()
                            if backupManager.isBackingUp {
                                ProgressView()
                                    .scaleEffect(0.8)
                            }
                        }
                    }
                    .disabled(backupManager.isBackingUp)
                    
                    NavigationLink(destination: BackupListView()) {
                        HStack {
                            Image(systemName: "list.bullet")
                                .foregroundColor(.purple)
                            Text("View All Backups")
                                .foregroundColor(.primary)
                            Spacer()
                        }
                    }
                    
                    Button(action: {
                        showDataRecoveryOptions()
                    }) {
                        HStack {
                            Image(systemName: "arrow.clockwise.circle")
                                .foregroundColor(.orange)
                            Text("Data Recovery Options")
                                .foregroundColor(.primary)
                            Spacer()
                        }
                    }
                }
                
                // Export & Sharing Section
                Section("📤 Export & Sharing") {
                    Button(action: {
                        exportProgressReport()
                    }) {
                        HStack {
                            Image(systemName: "doc.text")
                                .foregroundColor(.blue)
                            Text("Export Progress Report")
                                .foregroundColor(.primary)
                            Spacer()
                            if exportManager.isExporting {
                                ProgressView()
                                    .scaleEffect(0.8)
                            }
                        }
                    }
                    .disabled(exportManager.isExporting)
                    
                    Button(action: {
                        exportDataBackup()
                    }) {
                        HStack {
                            Image(systemName: "doc.badge.gearshape")
                                .foregroundColor(.green)
                            Text("Export Data Backup")
                                .foregroundColor(.primary)
                            Spacer()
                            if exportManager.isExporting {
                                ProgressView()
                                    .scaleEffect(0.8)
                            }
                        }
                    }
                    .disabled(exportManager.isExporting)
                    
                    Button(action: {
                        exportAndShareAll()
                    }) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                                .foregroundColor(.purple)
                            Text("Export & Share All")
                                .foregroundColor(.primary)
                            Spacer()
                            if exportManager.isExporting {
                                ProgressView()
                                    .scaleEffect(0.8)
                            }
                        }
                    }
                    .disabled(exportManager.isExporting)
                    
                    // Export Status Display
                    if case .success(let message) = exportManager.exportStatus {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            VStack(alignment: .leading) {
                                Text("Export Status")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(message)
                                    .font(.caption)
                                    .foregroundColor(.green)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            Spacer()
                        }
                        .padding(.vertical, 4)
                    } else if case .failed(let message) = exportManager.exportStatus {
                        HStack {
                            Image(systemName: "exclamationmark.circle.fill")
                                .foregroundColor(.red)
                            VStack(alignment: .leading) {
                                Text("Export Status")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(message)
                                    .font(.caption)
                                    .foregroundColor(.red)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            Spacer()
                        }
                        .padding(.vertical, 4)
                    }
                }
                
                // App Status Section
                Section("📱 App Status") {
                    HStack {
                        Image(systemName: "app.badge")
                            .foregroundColor(.blue)
                        VStack(alignment: .leading) {
                            Text("App Version")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(appVersionManager.currentVersion)
                                .font(.body)
                                .fontWeight(.medium)
                        }
                        Spacer()
                    }
                    
                    HStack {
                        Image(systemName: getExpirationIcon())
                            .foregroundColor(getExpirationColor())
                        VStack(alignment: .leading) {
                            Text("Expiration Status")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(appVersionManager.getExpirationStatusText())
                                .font(.body)
                                .fontWeight(.medium)
                                .foregroundColor(getExpirationColor())
                        }
                        Spacer()
                    }
                    
                    if appVersionManager.isExpiringSoon || appVersionManager.hasAppExpired() {
                        Button(action: {
                            showingRebuildInstructions = true
                        }) {
                            HStack {
                                Image(systemName: "info.circle")
                                    .foregroundColor(.orange)
                                Text("Rebuild Instructions")
                                    .foregroundColor(.primary)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.secondary)
                                    .font(.caption)
                            }
                        }
                    }
                }
                
                // Data Integrity Section
                Section("🔍 Data Integrity") {
                    HStack {
                        Image(systemName: getDataIntegrityIcon())
                            .foregroundColor(getDataIntegrityColor())
                        VStack(alignment: .leading) {
                            Text("Data Status")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(appVersionManager.dataIntegrityStatus.description)
                                .font(.body)
                                .fontWeight(.medium)
                                .foregroundColor(getDataIntegrityColor())
                        }
                        Spacer()
                    }
                    
                    Button(action: {
                        verifyDataIntegrity()
                    }) {
                        HStack {
                            Image(systemName: "checkmark.shield")
                                .foregroundColor(.green)
                            Text("Verify Data Integrity")
                                .foregroundColor(.primary)
                            Spacer()
                        }
                    }
                    
                    if case .issues(_) = appVersionManager.dataIntegrityStatus,
                       case .corrupted(_) = appVersionManager.dataIntegrityStatus {
                        Button(action: {
                            attemptDataRecovery()
                        }) {
                            HStack {
                                Image(systemName: "arrow.clockwise.circle.fill")
                                    .foregroundColor(.red)
                                Text("Attempt Data Recovery")
                                    .foregroundColor(.primary)
                                Spacer()
                            }
                        }
                    }
                }
                
                // Advanced Settings Section
                Section("⚙️ Advanced") {
                    NavigationLink(destination: AppStatusView()) {
                        HStack {
                            Image(systemName: "info.circle")
                                .foregroundColor(.blue)
                            Text("Detailed App Status")
                                .foregroundColor(.primary)
                            Spacer()
                        }
                    }
                    
                    Button(action: {
                        clearAllNotifications()
                    }) {
                        HStack {
                            Image(systemName: "bell.slash")
                                .foregroundColor(.red)
                            Text("Clear All Notifications")
                                .foregroundColor(.primary)
                            Spacer()
                        }
                    }
                    
                    #if DEBUG
                    Button(action: {
                        runDiagnostics()
                    }) {
                        HStack {
                            Image(systemName: "stethoscope")
                                .foregroundColor(.purple)
                            Text("Run Diagnostics")
                                .foregroundColor(.primary)
                            Spacer()
                        }
                    }
                    #endif
                }
            }
            .navigationTitle("Settings")
            .refreshable {
                refreshSettings()
            }
            .onAppear {
                loadSettings()
            }
        }
        .sheet(isPresented: $showingNotificationTimePicker) {
            NotificationTimePickerView(
                morningTime: $tempMorningTime,
                eveningTime: $tempEveningTime,
                onSave: { morning, evening in
                    saveNotificationTimes(morning: morning, evening: evening)
                }
            )
        }
        .sheet(isPresented: $showingRebuildInstructions) {
            RebuildInstructionsView()
        }
        .alert("Backup Result", isPresented: $showingBackupAlert) {
            Button("OK") { }
        } message: {
            if let message = backupResult.message {
                Text(message)
            } else {
                Text(backupResult.success ? "Backup created successfully!" : "Backup failed. Please try again.")
            }
        }
        .alert("Export Result", isPresented: $showingExportAlert) {
            if !exportedFiles.isEmpty {
                Button("Share") {
                    shareExportedFiles()
                }
                Button("OK") { }
            } else {
                Button("OK") { }
            }
        } message: {
            if let message = exportResult.message {
                Text(message)
            } else {
                Text(exportResult.success ? "Export completed successfully!" : "Export failed. Please try again.")
            }
        }
        .alert("Data Recovery", isPresented: $showingDataRecoveryAlert) {
            Button("Proceed") {
                performDataRecovery()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will attempt to recover your data from the most recent backup. Your current data will be backed up first. Continue?")
        }
    }
    
    // MARK: - Helper Methods
    
    private func loadSettings() {
        if let settings = currentSettings {
            notificationsEnabled = settings.isNotificationsEnabled
            tempMorningTime = settings.morningNotificationTime ?? Date()
            tempEveningTime = settings.eveningNotificationTime ?? Date()
        }
    }
    
    private func refreshSettings() {
        appVersionManager.checkForRebuild()
        loadSettings()
    }
    
    private func getNotificationTimesText() -> String {
        guard let settings = currentSettings else {
            return "Morning: 8:00 AM, Evening: 8:00 PM"
        }
        
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        
        let morningText = formatter.string(from: settings.morningNotificationTime ?? Date())
        let eveningText = formatter.string(from: settings.eveningNotificationTime ?? Date())
        
        return "Morning: \(morningText), Evening: \(eveningText)"
    }
    
    private func getLastBackupText() -> String {
        if let lastBackup = backupManager.lastBackupDate {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
            return formatter.string(from: lastBackup)
        } else {
            return "Never"
        }
    }
    
    private func getExpirationIcon() -> String {
        if appVersionManager.hasAppExpired() {
            return "exclamationmark.triangle.fill"
        } else if appVersionManager.isExpiringSoon {
            return "clock.badge.exclamationmark"
        } else {
            return "clock"
        }
    }
    
    private func getExpirationColor() -> Color {
        if appVersionManager.hasAppExpired() {
            return .red
        } else if appVersionManager.isExpiringSoon {
            return .orange
        } else {
            return .green
        }
    }
    
    private func getDataIntegrityIcon() -> String {
        switch appVersionManager.dataIntegrityStatus {
        case .verified:
            return "checkmark.shield.fill"
        case .unknown:
            return "questionmark.circle"
        case .issues:
            return "exclamationmark.triangle"
        case .corrupted:
            return "xmark.shield.fill"
        }
    }
    
    private func getDataIntegrityColor() -> Color {
        switch appVersionManager.dataIntegrityStatus {
        case .verified:
            return .green
        case .unknown:
            return .gray
        case .issues:
            return .orange
        case .corrupted:
            return .red
        }
    }
    
    // MARK: - Action Methods
    
    private func loadCurrentNotificationTimes() {
        if let settings = currentSettings {
            tempMorningTime = settings.morningNotificationTime ?? Date()
            tempEveningTime = settings.eveningNotificationTime ?? Date()
        }
    }
    
    private func updateNotificationSettings(enabled: Bool) {
        guard let settings = currentSettings else { return }
        
        settings.isNotificationsEnabled = enabled
        
        do {
            try viewContext.save()
            notificationManager.enableNotifications(enabled)
            print("✅ Notification settings updated: \(enabled)")
        } catch {
            print("❌ Failed to update notification settings: \(error)")
        }
    }
    
    private func saveNotificationTimes(morning: Date, evening: Date) {
        guard let settings = currentSettings else { return }
        
        settings.morningNotificationTime = morning
        settings.eveningNotificationTime = evening
        
        do {
            try viewContext.save()
            notificationManager.updateNotificationTimes(morningTime: morning, eveningTime: evening)
            print("✅ Notification times updated")
        } catch {
            print("❌ Failed to save notification times: \(error)")
        }
    }
    
    private func testNotifications() {
        notificationManager.testNotification()
    }
    
    private func createManualBackup() {
        backupManager.createManualBackup { success, error in
            DispatchQueue.main.async {
                self.backupResult = (success, error)
                self.showingBackupAlert = true
            }
        }
    }
    
    private func showDataRecoveryOptions() {
        showingDataRecoveryAlert = true
    }
    
    private func exportProgressReport() {
        exportManager.createMarkdownReport { success, url, error in
            DispatchQueue.main.async {
                self.exportResult = (success, error)
                if success, let url = url {
                    self.exportedFiles = [url]
                } else {
                    self.exportedFiles = []
                }
                self.showingExportAlert = true
            }
        }
    }
    
    private func exportDataBackup() {
        exportManager.createJSONExport { success, url, error in
            DispatchQueue.main.async {
                self.exportResult = (success, error)
                if success, let url = url {
                    self.exportedFiles = [url]
                } else {
                    self.exportedFiles = []
                }
                self.showingExportAlert = true
            }
        }
    }
    
    private func exportAndShareAll() {
        exportManager.createComprehensiveExport { success, urls, error in
            DispatchQueue.main.async {
                self.exportResult = (success, error)
                if success {
                    self.exportedFiles = urls
                } else {
                    self.exportedFiles = []
                }
                self.showingExportAlert = true
            }
        }
    }
    
    private func shareExportedFiles() {
        guard !exportedFiles.isEmpty else { return }
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootViewController = window.rootViewController {
            exportManager.shareExports(exportedFiles, from: rootViewController)
        }
    }
    
    private func verifyDataIntegrity() {
        appVersionManager.checkForRebuild()
    }
    
    private func attemptDataRecovery() {
        showingDataRecoveryAlert = true
    }
    
    private func performDataRecovery() {
        // This would trigger the backup recovery manager
        let success = backupManager.attemptAutomaticRecovery()
        
        DispatchQueue.main.async {
            self.backupResult = (success, success ? "Data recovery completed successfully" : "Data recovery failed")
            self.showingBackupAlert = true
        }
        
        // Refresh app status after recovery attempt
        appVersionManager.checkForRebuild()
    }
    
    private func clearAllNotifications() {
        notificationManager.cancelAllNotifications()
    }
    
    #if DEBUG
    private func runDiagnostics() {
        // Run various diagnostic tests
        print("🔍 Running diagnostics...")
        
        // Test Core Data
        let coreDataValid = CoreDataValidator.runAllValidations()
        print("Core Data Valid: \(coreDataValid)")
        
        // Test backup system
        BackupSystemTests.runBasicTests()
        
        // Test notification system
        NotificationManagerIntegrationTests.runBasicTests()
        
        // Test app version manager
        AppVersionManagerTests.runBasicTests()
        
        print("✅ Diagnostics completed")
    }
    #endif
}

// MARK: - Supporting Views

struct NotificationTimePickerView: View {
    @Binding var morningTime: Date
    @Binding var eveningTime: Date
    let onSave: (Date, Date) -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section("Morning Notification") {
                    DatePicker("Time", selection: $morningTime, displayedComponents: .hourAndMinute)
                        .datePickerStyle(.wheel)
                }
                
                Section("Evening Notification") {
                    DatePicker("Time", selection: $eveningTime, displayedComponents: .hourAndMinute)
                        .datePickerStyle(.wheel)
                }
            }
            .navigationTitle("Notification Times")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        onSave(morningTime, eveningTime)
                        dismiss()
                    }
                }
            }
        }
    }
}

struct BackupListView: View {
    @StateObject private var backupManager = BackupManager.shared
    @State private var backups: [BackupInfo] = []
    @State private var showingRestoreAlert = false
    @State private var selectedBackup: BackupInfo?
    
    var body: some View {
        List {
            ForEach(backups, id: \.url) { backup in
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Image(systemName: backup.format == .sqlite ? "externaldrive" : "doc.badge.gearshape")
                            .foregroundColor(backup.format == .sqlite ? .blue : .green)
                        
                        Text(backup.url.lastPathComponent)
                            .font(.headline)
                        
                        Spacer()
                        
                        Text(backup.formattedSize)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Text(backup.formattedDate)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    selectedBackup = backup
                    showingRestoreAlert = true
                }
            }
        }
        .navigationTitle("Backups")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadBackups()
        }
        .refreshable {
            loadBackups()
        }
        .alert("Restore Backup", isPresented: $showingRestoreAlert) {
            Button("Restore") {
                if let backup = selectedBackup {
                    restoreBackup(backup)
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            if let backup = selectedBackup {
                Text("Restore from backup created on \(backup.formattedDate)? This will replace your current data.")
            }
        }
    }
    
    private func loadBackups() {
        backups = backupManager.listBackups()
    }
    
    private func restoreBackup(_ backup: BackupInfo) {
        backupManager.restoreFromBackup(backup) { success, error in
            DispatchQueue.main.async {
                if success {
                    print("✅ Backup restored successfully")
                } else {
                    print("❌ Backup restore failed: \(error ?? "Unknown error")")
                }
            }
        }
    }
}

struct RebuildInstructionsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var appVersionManager = AppVersionManager.shared
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                                .font(.title2)
                            Text("App Rebuild Required")
                                .font(.title2)
                                .fontWeight(.bold)
                        }
                        
                        Text("Your development certificate is expiring soon. Follow these steps to rebuild the app and preserve your data.")
                            .foregroundColor(.secondary)
                    }
                    
                    // Status Information
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Current Status")
                            .font(.headline)
                        
                        HStack {
                            Image(systemName: "clock")
                                .foregroundColor(.blue)
                            Text("Days until expiration: \(appVersionManager.daysUntilExpiration)")
                        }
                        
                        HStack {
                            Image(systemName: "externaldrive")
                                .foregroundColor(.green)
                            Text("Last backup: \(getLastBackupText())")
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    
                    // Instructions
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Rebuild Instructions")
                            .font(.headline)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            InstructionStep(
                                number: 1,
                                title: "Create Backup",
                                description: "Tap 'Create Backup Now' below to ensure your progress is saved."
                            )
                            
                            InstructionStep(
                                number: 2,
                                title: "Close Xcode",
                                description: "Quit Xcode completely before proceeding."
                            )
                            
                            InstructionStep(
                                number: 3,
                                title: "Clean Build Folder",
                                description: "In Xcode, go to Product → Clean Build Folder (⇧⌘K)"
                            )
                            
                            InstructionStep(
                                number: 4,
                                title: "Rebuild Project",
                                description: "Build and run the project again (⌘R). Your data will be automatically restored."
                            )
                            
                            InstructionStep(
                                number: 5,
                                title: "Verify Data",
                                description: "Check that your progress has been preserved after the rebuild."
                            )
                        }
                    }
                    
                    // Action Buttons
                    VStack(spacing: 12) {
                        Button(action: {
                            createPreRebuildBackup()
                        }) {
                            HStack {
                                Image(systemName: "externaldrive.badge.plus")
                                Text("Create Backup Now")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                        }
                        
                        Button(action: {
                            exportDataForSafety()
                        }) {
                            HStack {
                                Image(systemName: "square.and.arrow.up")
                                Text("Export Progress Report")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                        }
                    }
                    
                    // Warning
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "exclamationmark.triangle")
                                .foregroundColor(.red)
                            Text("Important")
                                .font(.headline)
                                .foregroundColor(.red)
                        }
                        
                        Text("Do not delete the app or clear app data. Your progress is stored in the Documents directory and will survive the rebuild process.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(8)
                }
                .padding()
            }
            .navigationTitle("Rebuild Guide")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func getLastBackupText() -> String {
        if let lastBackup = BackupManager.shared.lastBackupDate {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
            return formatter.string(from: lastBackup)
        } else {
            return "Never"
        }
    }
    
    private func createPreRebuildBackup() {
        appVersionManager.createPreRebuildBackup { success, error in
            // Handle backup result
        }
    }
    
    private func exportDataForSafety() {
        ExportManager.shared.createComprehensiveExport { success, urls, error in
            if success && !urls.isEmpty {
                // Share the exported files
                DispatchQueue.main.async {
                    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                       let window = windowScene.windows.first,
                       let rootViewController = window.rootViewController {
                        ExportManager.shared.shareExports(urls, from: rootViewController)
                    }
                }
            }
        }
    }
}

struct InstructionStep: View {
    let number: Int
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(number)")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .frame(width: 24, height: 24)
                .background(Color.blue)
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
    }
}

// MARK: - Preview

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}