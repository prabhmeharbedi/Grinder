import SwiftUI

struct AppStatusView: View {
    @StateObject private var appVersionManager = AppVersionManager.shared
    @StateObject private var exportManager = ExportManager.shared
    @State private var showingBackupAlert = false
    @State private var backupInProgress = false
    @State private var backupResult: (success: Bool, message: String?) = (false, nil)
    @State private var showingExportAlert = false
    @State private var exportResult: (success: Bool, message: String?) = (false, nil)
    @State private var exportedFiles: [URL] = []
    
    var body: some View {
        NavigationView {
            List {
                // App Version Section
                Section("App Information") {
                    HStack {
                        Image(systemName: "app.badge")
                            .foregroundColor(.blue)
                        VStack(alignment: .leading) {
                            Text("Version")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(appVersionManager.currentVersion)
                                .font(.body)
                                .fontWeight(.medium)
                        }
                        Spacer()
                    }
                    
                    if let installDate = appVersionManager.installDate {
                        HStack {
                            Image(systemName: "calendar")
                                .foregroundColor(.green)
                            VStack(alignment: .leading) {
                                Text("Install Date")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(formatDate(installDate))
                                    .font(.body)
                                    .fontWeight(.medium)
                            }
                            Spacer()
                        }
                    }
                    
                    if let lastRebuildDate = appVersionManager.lastRebuildDate {
                        HStack {
                            Image(systemName: "arrow.clockwise")
                                .foregroundColor(.orange)
                            VStack(alignment: .leading) {
                                Text("Last Rebuild")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(formatDate(lastRebuildDate))
                                    .font(.body)
                                    .fontWeight(.medium)
                            }
                            Spacer()
                        }
                    }
                }
                
                // Expiration Status Section
                Section("App Expiration") {
                    HStack {
                        Image(systemName: appVersionManager.hasAppExpired() ? "exclamationmark.triangle.fill" : "clock")
                            .foregroundColor(getExpirationColor())
                        VStack(alignment: .leading) {
                            Text("Status")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(appVersionManager.getExpirationStatusText())
                                .font(.body)
                                .fontWeight(.medium)
                                .foregroundColor(getExpirationColor())
                        }
                        Spacer()
                    }
                    
                    if let expirationDate = appVersionManager.getExpirationDate() {
                        HStack {
                            Image(systemName: "calendar.badge.exclamationmark")
                                .foregroundColor(.red)
                            VStack(alignment: .leading) {
                                Text("Expires On")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(formatDate(expirationDate))
                                    .font(.body)
                                    .fontWeight(.medium)
                            }
                            Spacer()
                        }
                    }
                    
                    if appVersionManager.isExpiringSoon {
                        HStack {
                            Image(systemName: "info.circle.fill")
                                .foregroundColor(.orange)
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Rebuild Reminder")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text("Your app will expire soon. Create a backup and rebuild to continue using Machine Mode.")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            Spacer()
                        }
                        .padding(.vertical, 4)
                    }
                }
                
                // Data Integrity Section
                Section("Data Status") {
                    HStack {
                        Image(systemName: getDataIntegrityIcon())
                            .foregroundColor(getDataIntegrityColor())
                        VStack(alignment: .leading) {
                            Text("Data Integrity")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(appVersionManager.dataIntegrityStatus.description)
                                .font(.body)
                                .fontWeight(.medium)
                                .foregroundColor(getDataIntegrityColor())
                        }
                        Spacer()
                    }
                    
                    if appVersionManager.hasDetectedRebuild {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            VStack(alignment: .leading) {
                                Text("Rebuild Detected")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text("App rebuild was successfully detected and data integrity verified.")
                                    .font(.caption)
                                    .foregroundColor(.green)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            Spacer()
                        }
                        .padding(.vertical, 4)
                    }
                }
                
                // Actions Section
                Section("Actions") {
                    Button(action: {
                        createBackup()
                    }) {
                        HStack {
                            Image(systemName: "externaldrive.badge.plus")
                                .foregroundColor(.blue)
                            Text("Create Backup")
                                .foregroundColor(.primary)
                            Spacer()
                            if backupInProgress {
                                ProgressView()
                                    .scaleEffect(0.8)
                            }
                        }
                    }
                    .disabled(backupInProgress)
                    
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
                    
                    if appVersionManager.isExpiringSoon || appVersionManager.hasAppExpired() {
                        Button(action: {
                            showRebuildInstructions()
                        }) {
                            HStack {
                                Image(systemName: "arrow.clockwise.circle")
                                    .foregroundColor(.orange)
                                Text("Rebuild Instructions")
                                    .foregroundColor(.primary)
                                Spacer()
                            }
                        }
                    }
                }
                
                // Export Section
                Section("Export & Sharing") {
                    Button(action: {
                        exportMarkdownReport()
                    }) {
                        HStack {
                            Image(systemName: "doc.text")
                                .foregroundColor(.purple)
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
                        exportJSONData()
                    }) {
                        HStack {
                            Image(systemName: "doc.badge.gearshape")
                                .foregroundColor(.orange)
                            Text("Export Data (JSON)")
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
                        exportComprehensive()
                    }) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                                .foregroundColor(.blue)
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
                    
                    // Export Status
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
                
                // Debug Information (only in debug builds)
                #if DEBUG
                Section("Debug Information") {
                    Button("Simulate Rebuild") {
                        simulateRebuild()
                    }
                    
                    Button("Reset Test State") {
                        AppVersionManagerTests.resetTestState()
                    }
                    
                    Button("Run Integration Tests") {
                        AppVersionManagerTests.runIntegrationTests()
                    }
                }
                #endif
            }
            .navigationTitle("App Status")
            .refreshable {
                refreshAppStatus()
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
        }
    }
    
    // MARK: - Helper Methods
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
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
    
    // MARK: - Actions
    
    private func createBackup() {
        backupInProgress = true
        
        appVersionManager.createPreRebuildBackup { success, error in
            DispatchQueue.main.async {
                self.backupInProgress = false
                self.backupResult = (success, error)
                self.showingBackupAlert = true
            }
        }
    }
    
    private func verifyDataIntegrity() {
        // Trigger data integrity verification
        appVersionManager.checkForRebuild()
    }
    
    private func refreshAppStatus() {
        // Refresh app status information
        appVersionManager.checkForRebuild()
    }
    
    private func showRebuildInstructions() {
        // This could open a detailed view with rebuild instructions
        // For now, we'll just trigger a backup creation
        createBackup()
    }
    
    // MARK: - Export Actions
    
    private func exportMarkdownReport() {
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
    
    private func exportJSONData() {
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
    
    private func exportComprehensive() {
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
        
        // Find the current view controller to present the share sheet
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootViewController = window.rootViewController {
            exportManager.shareExports(exportedFiles, from: rootViewController)
        }
    }
    
    #if DEBUG
    private func simulateRebuild() {
        AppVersionManagerTests.simulateRebuild()
    }
    #endif
}

// MARK: - Preview

struct AppStatusView_Previews: PreviewProvider {
    static var previews: some View {
        AppStatusView()
    }
}