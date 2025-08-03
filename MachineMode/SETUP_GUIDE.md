# Setup Guide for Xcode

## 📁 Adding New Files to Xcode Project

When you open `MachineMode.xcodeproj` in Xcode, you'll need to add the new Core Data files to the project:

### Files to Add:
1. **CoreData+Extensions.swift** - Core Data entity extensions and validation
2. **DataValidator.swift** - Comprehensive data validation system  
3. **CoreDataValidator.swift** - iOS-compatible validation utility

### How to Add Files:
1. Right-click on the `MachineMode` folder in Xcode Navigator
2. Select "Add Files to 'MachineMode'"
3. Navigate to the MachineMode folder and select the three files above
4. Make sure "Add to target: MachineMode" is checked
5. Click "Add"

## 🚀 Running the App

1. **Select Target**: Choose "MachineMode" scheme and iOS Simulator
2. **Build**: Press Cmd+B to build the project
3. **Run**: Press Cmd+R to run the app
4. **Check Console**: Open Debug Area (Cmd+Shift+Y) to see validation messages

## 📋 Expected Console Output

When the app launches successfully, you should see:
```
🧪 Running Core Data validation tests...
✅ Core Data stack validation successful
✅ Entity creation validation successful
✅ Validation error handling works correctly
🎉 All Core Data validations passed!
🚀 Initializing complete 100-day curriculum...
📅 Initialized 10/100 days...
📅 Initialized 20/100 days...
...
✅ All 100 days initialized with complete curriculum data
🔍 Validating curriculum data...
📊 Curriculum validation complete:
   Total DSA Problems: [number]
   Total System Topics: [number]
   Status: ✅ Valid
✅ Curriculum data validation passed
```

## 🔧 Troubleshooting

### Build Errors:
- **Missing files**: Make sure all three new Swift files are added to the project target
- **Core Data model**: Verify `MachineMode.xcdatamodeld` is included in the bundle

### Runtime Errors:
- **Core Data stack**: Check that the data model name matches the container name
- **Permissions**: Ensure app has write access to Documents directory
- **Validation**: Check console for specific validation error messages

## ✅ Success Indicators

The implementation is working correctly when:
- App builds without errors
- All validation tests pass
- 100 days of curriculum data loads
- App displays curriculum statistics
- Data persists between app launches

## 📱 Next Steps

Once the Core Data implementation is verified, you can proceed to:
- Task 4: Build Today View with daily progress tracking
- Task 5: Implement progress visualization components
- Task 6: Add user interaction and data modification features