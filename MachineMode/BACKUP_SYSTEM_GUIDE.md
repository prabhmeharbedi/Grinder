# Backup and Recovery System Guide

## Overview

The Machine Mode Tracker app includes a comprehensive backup and recovery system designed to ensure data persistence across app rebuilds (required every 7 days due to development certificate limitations). The system provides automatic daily backups, manual backup creation, and robust recovery mechanisms.

## Components

### 1. BackupManager

The `BackupManager` is the main interface for backup operations:

- **Automatic Daily Backups**: Creates backups automatically once per day
- **Manual Backups**: Allows users to create backups on demand
- **Multiple Formats**: Supports both SQLite and JSON backup formats
- **Background Backups**: Creates backups when app goes to background
- **Storage Management**: Automatically cleans up old backups (keeps 7 days)

#### Key Features:
- Singleton pattern for global access
- Observable object for SwiftUI integration
- Queue-based operations for performance
- Comprehensive error handling

### 2. BackupRecoveryManager

The `BackupRecoveryManager` handles data integrity verification and recovery:

- **Data Integrity Checks**: Validates database consistency
- **Automatic Recovery**: Attempts recovery from corruption
- **Multiple Recovery Methods**: SQLite backup → JSON backup → Curriculum reinit
- **Emergency Backups**: Creates backups before risky operations

#### Recovery Hierarchy:
1. **SQLite Backup Restore**: Fastest, preserves all data
2. **JSON Backup Restore**: Slower, but more portable
3. **Curriculum Reinitialization**: Last resort, loses user progress

### 3. Integration with Core Data

The backup system is tightly integrated with the Core Data stack:

- **Automatic Save Triggers**: Backups are created after data saves
- **Store Load Error Handling**: Automatic recovery on database corruption
- **Data Validation**: Ensures data integrity after operations

## Backup Formats

### SQLite Format
- **File**: `MachineMode_Backup_YYYY-MM-DD.sqlite`
- **Includes**: Complete database with all relationships
- **Advantages**: Fast restore, preserves all data
- **Use Case**: Primary backup format

### JSON Format
- **File**: `MachineMode_Backup_YYYY-MM-DD.json`
- **Includes**: Structured data export with metadata
- **Advantages**: Human-readable, portable
- **Use Case**: Secondary backup, data export

## Storage Location

All backups are stored in the app's Documents directory:
```
Documents/
├── MachineMode.sqlite (main database)
└── Backups/
    ├── MachineMode_Backup_2024-01-15.sqlite
    ├── MachineMode_Backup_2024-01-15.json
    ├── MachineMode_Backup_2024-01-14.sqlite
    └── ...
```

This location ensures persistence across app rebuilds.

## Automatic Backup Schedule

### Daily Backups
- **Trigger**: Once per day, first app launch after midnight
- **Format**: Both SQLite and JSON
- **Retention**: 7 days (older backups automatically deleted)

### Background Backups
- **Trigger**: When app enters background
- **Format**: SQLite only (for speed)
- **Purpose**: Capture recent changes before app termination

### App Launch Backups
- **Trigger**: On app rebuild detection
- **Format**: Both SQLite and JSON
- **Purpose**: Preserve data before potential issues

## Manual Backup Usage

### Creating Manual Backups
```swift
BackupManager.shared.createManualBackup(format: .both) { success, error in
    if success {
        print("Backup created successfully")
    } else {
        print("Backup failed: \(error ?? "Unknown error")")
    }
}
```

### Listing Available Backups
```swift
let backups = BackupManager.shared.listBackups()
for backup in backups {
    print("Backup: \(backup.url.lastPathComponent)")
    print("Date: \(backup.formattedDate)")
    print("Size: \(backup.formattedSize)")
    print("Format: \(backup.format)")
}
```

### Restoring from Backup
```swift
let backups = BackupManager.shared.listBackups()
if let latestBackup = backups.first {
    BackupManager.shared.restoreFromBackup(latestBackup) { success, error in
        if success {
            print("Restore completed successfully")
        } else {
            print("Restore failed: \(error ?? "Unknown error")")
        }
    }
}
```

## Data Integrity Verification

### Running Integrity Checks
```swift
let result = BackupRecoveryManager.shared.verifyAndRepairDataIntegrity()

switch result.severity {
case .healthy:
    print("Data is healthy")
case .minor:
    print("Minor issues found and repaired")
case .major:
    print("Major issues found: \(result.issues)")
case .critical:
    print("Critical issues require manual intervention")
}
```

### Automatic Recovery
```swift
let recoveryResult = BackupRecoveryManager.shared.attemptRecovery()

if recoveryResult.success {
    print("Recovery successful using: \(recoveryResult.method)")
    if let backupUsed = recoveryResult.backupUsed {
        print("Backup used: \(backupUsed)")
    }
} else {
    print("Recovery failed: \(recoveryResult.message)")
}
```

## Error Handling

### Common Error Scenarios

1. **Backup Creation Failure**
   - Insufficient storage space
   - File system permissions
   - Core Data save errors

2. **Backup Corruption**
   - Incomplete backup files
   - File system corruption
   - Interrupted backup process

3. **Restore Failures**
   - Corrupted backup files
   - Version incompatibility
   - Core Data migration issues

### Error Recovery Strategies

1. **Graceful Degradation**: Continue operation with reduced functionality
2. **Automatic Retry**: Retry failed operations with exponential backoff
3. **User Notification**: Inform users of critical issues
4. **Fallback Options**: Provide alternative recovery methods

## Performance Considerations

### Backup Performance
- **SQLite Backups**: ~100ms for typical database size
- **JSON Backups**: ~500ms for full data export
- **Background Queue**: Operations don't block UI

### Storage Management
- **Automatic Cleanup**: Removes backups older than 7 days
- **Size Monitoring**: Tracks backup directory size
- **Compression**: JSON backups use pretty-printing for readability

## Testing

### Basic Tests
```swift
BackupSystemTests.runBasicTests()
```

### Manual Testing
```swift
BackupSystemTests.testManualBackupCreation()
```

### Integration Testing
- App rebuild scenarios
- Data corruption recovery
- Large dataset backups

## Troubleshooting

### Common Issues

1. **No Backups Created**
   - Check Documents directory permissions
   - Verify Core Data is saving properly
   - Check available storage space

2. **Restore Failures**
   - Verify backup file integrity
   - Check Core Data model compatibility
   - Try alternative backup format

3. **Performance Issues**
   - Monitor backup file sizes
   - Check for excessive backup frequency
   - Verify background queue operation

### Debug Information

Enable detailed logging by setting:
```swift
// In development builds
UserDefaults.standard.set(true, forKey: "BackupSystemDebugLogging")
```

## Future Enhancements

### Planned Features
- Cloud backup integration (iCloud)
- Incremental backup support
- Backup encryption
- Backup verification checksums
- User-configurable retention policies

### Monitoring
- Backup success/failure metrics
- Storage usage tracking
- Recovery operation analytics
- Performance monitoring

## Security Considerations

### Data Protection
- Backups stored in app sandbox
- No sensitive data in JSON exports
- File system permissions respected

### Privacy
- No data transmitted outside device
- User control over backup creation
- Transparent backup operations

## Conclusion

The backup and recovery system provides robust data protection for the Machine Mode Tracker app, ensuring user progress is never lost despite the 7-day rebuild requirement. The system balances automatic operation with user control, providing multiple recovery options and comprehensive error handling.