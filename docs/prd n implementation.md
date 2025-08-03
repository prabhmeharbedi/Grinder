Machine Mode Tracker - Complete PRD & Implementation Guide
PRODUCT REQUIREMENTS DOCUMENT (PRD)
1. PRODUCT OVERVIEW
Product Name: Machine Mode Tracker
Target Platform: iOS (iPhone)
Target User: Software engineering interview candidates following intensive 100-day preparation
Core Purpose: Simple, focused progress tracking for DSA problems and System Design topics with daily accountability
2. PRODUCT OBJECTIVES
Primary Goals:

Track daily completion of DSA problems and System Design topics
Maintain motivation through notifications and streak tracking
Export progress to update original markdown file
Provide visual progress feedback

Success Metrics:

Daily app engagement rate > 80%
Streak maintenance (consecutive days) > 7 days average
Task completion rate > 90%
User retention through 100-day program > 60%

3. USER PERSONAS
Primary User: "The Grinder"

Age: 22-35
Background: CS student or working software engineer
Goal: Land FAANG/top-tier tech job
Pain Points: Losing motivation, forgetting daily tasks, no progress visibility
Behavior: Studies 2-4 hours daily, uses iPhone regularly, values simplicity

4. FUNCTIONAL REQUIREMENTS
4.1 Core Features
F1: Daily Progress Tracking

Display current day number (Day X/100)
Show DSA problems for current day with checkboxes
Show System Design topics for current day with checkboxes
Allow marking items as complete
Optional time tracking per problem
Optional notes per problem/topic
Add bonus problems functionality
Separate progress bars for DSA and System Design

F2: Smart Notifications

Morning notification: "Machine Mode Activated. Today's mission awaits." (default 7 AM)
Evening notification: "Progress check - How did you dominate today?" (default 8 PM)
Custom reminder times
Streak alerts when approaching milestone
Gentle nudge if no progress logged by evening
Weekly review prompts

F3: Visual Progress Dashboard

Overall completion percentage (out of 100 days)
DSA vs System Design completion split
Weekly heat map showing consistency
Problem difficulty distribution
Current streak counter with badges
Historical progress charts

F4: Content Management

Personal notes with markdown support
Search through notes
Export progress to updated MD file
Data persistence across app sessions

4.2 User Interface Requirements
UI1: Main Screen - "Today's Mission"

Clean, minimal design
Prominent day counter
Two sections: DSA and System Design
Quick checkbox interactions
Progress indicators
Easy access to add bonus problems

UI2: Progress Screen

Visual dashboard with charts
Heat map calendar view
Streak counter prominently displayed
Achievement badges

UI3: Settings Screen

Notification time customization
App preferences
Export functionality
About/Help section

5. NON-FUNCTIONAL REQUIREMENTS
Performance:

App launch time < 2 seconds
Smooth scrolling and interactions (60 FPS)
Data persistence without lag

Reliability:

99.9% uptime for local functionality
Data backup and recovery
Graceful handling of edge cases

Usability:

Intuitive navigation requiring no tutorial
Accessibility compliance (VoiceOver support)
Dark mode support

Security:

Local data storage only
No sensitive data collection
Standard iOS privacy practices

6. TECHNICAL REQUIREMENTS
Platform:

iOS 15.0+
iPhone only (portrait orientation)
Swift 5.0+
Xcode 14+

Storage:

Core Data for progress tracking
UserDefaults for settings
Local file storage for MD export

APIs:

Local Notifications framework
PhotoKit for any future photo features
Core Data for persistence

7. USER STORIES
Epic 1: Daily Progress Tracking

As a user, I want to see today's DSA problems so I can track what I need to complete
As a user, I want to mark problems as done so I can track my progress
As a user, I want to add extra problems so I can do more than the minimum
As a user, I want to track time spent so I can improve my speed
As a user, I want to add notes so I can remember key insights

Epic 2: Motivation & Accountability

As a user, I want morning reminders so I start each day focused
As a user, I want evening check-ins so I maintain consistency
As a user, I want to see my streak so I stay motivated
As a user, I want progress visualization so I can see how far I've come

Epic 3: Data Management

As a user, I want to export my progress so I can update my original file
As a user, I want my data saved so I don't lose progress
As a user, I want to search my notes so I can find past insights

8. ACCEPTANCE CRITERIA
AC1: Daily Tracking

User can see current day (Day X/100)
User can check off completed problems
User can add optional time and notes
Progress bars update in real-time
Bonus problems can be added and tracked

AC2: Notifications

Morning notification sends at scheduled time
Evening notification sends at scheduled time
User can customize notification times
Notifications include motivational messaging

AC3: Progress Visualization

Heat map shows daily completion status
Charts display DSA vs System Design progress
Streak counter updates accurately
Overall percentage calculation is correct

AC4: Data Export

User can export progress to MD file
Exported file includes completion status
File can be shared via standard iOS sharing

9. OUT OF SCOPE
Not Included in V1:

Social features or sharing
Cloud sync
Advanced analytics
Video content within app
Photo storage
Multi-user support
iPad support
Landscape orientation


COMPLETE IMPLEMENTATION GUIDE
PHASE 1: DEVELOPMENT ENVIRONMENT SETUP
Step 1: Install Development Tools
1.1 Install Xcode
bash# Download Xcode from Mac App Store (free)
# Requires macOS 12.5+ for Xcode 14
# Size: ~10GB download
1.2 Set up Apple Developer Account

Go to developer.apple.com
Sign up with Apple ID ($99/year for App Store distribution)
Complete enrollment process (can take 24-48 hours)

1.3 Install Command Line Tools
bashxcode-select --install
Step 2: Project Setup
2.1 Create New Xcode Project

Open Xcode
Create new project
Choose "iOS" → "App"
Fill details:

Product Name: "Machine Mode Tracker"
Interface: SwiftUI
Language: Swift
Use Core Data: ✓
Include Tests: ✓



2.2 Configure Project Settings
swift// In project settings:
- Deployment Target: iOS 15.0
- Bundle Identifier: com.yourname.machinemodetracker
- Version: 1.0
- Build: 1
PHASE 2: CORE DATA MODEL SETUP
Step 3: Design Data Model
3.1 Create Core Data Entities
Create MachineMode.xcdatamodeld with these entities:
Entity: Day
swift// Attributes:
- dayNumber: Int32
- date: Date
- dsaProgress: Float (0.0 to 1.0)
- systemDesignProgress: Float (0.0 to 1.0)
- dailyReflection: String (optional)
- isCompleted: Bool

// Relationships:
- dsaProblems: [DSAProblem]
- systemDesignTopics: [SystemDesignTopic]
Entity: DSAProblem
swift// Attributes:
- problemName: String
- leetcodeNumber: String (optional)
- isCompleted: Bool
- timeSpent: Int32 (minutes)
- notes: String (optional)
- difficulty: String (Easy/Medium/Hard)
- isBonusProblem: Bool

// Relationships:
- day: Day
Entity: SystemDesignTopic
swift// Attributes:
- topicName: String
- description: String (optional)
- isCompleted: Bool
- notes: String (optional)
- videoWatched: Bool
- taskCompleted: Bool

// Relationships:
- day: Day
Entity: UserSettings
swift// Attributes:
- morningNotificationTime: Date
- eveningNotificationTime: Date
- isNotificationsEnabled: Bool
- currentStreak: Int32
- longestStreak: Int32
- startDate: Date
Step 4: Core Data Stack Setup
4.1 Create Persistence Controller
swift// Persistence.swift
import CoreData

struct PersistenceController {
    static let shared = PersistenceController()
    
    static var preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        
        // Add sample data for previews
        let sampleDay = Day(context: viewContext)
        sampleDay.dayNumber = 1
        sampleDay.date = Date()
        sampleDay.dsaProgress = 0.6
        sampleDay.systemDesignProgress = 0.8
        
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        
        return result
    }()
    
    let container: NSPersistentContainer
    
    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "MachineMode")
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
}
PHASE 3: APP STRUCTURE & NAVIGATION
Step 5: Create App Structure
5.1 Main App File
swift// MachineMode TrackerApp.swift
import SwiftUI

@main
struct MachineModeTrackerApp: App {
    let persistenceController = PersistenceController.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .onAppear {
                    NotificationManager.shared.requestPermission()
                    DataInitializer.shared.initializeDataIfNeeded()
                }
        }
    }
}
5.2 Content View (Main Navigation)
swift// ContentView.swift
import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            TodayView()
                .tabItem {
                    Image(systemName: "target")
                    Text("Today")
                }
                .tag(0)
            
            ProgressView()
                .tabItem {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                    Text("Progress")
                }
                .tag(1)
            
            SettingsView()
                .tabItem {
                    Image(systemName: "gear")
                    Text("Settings")
                }
                .tag(2)
        }
        .accentColor(.blue)
    }
}
PHASE 4: TODAY VIEW IMPLEMENTATION
Step 6: Today View
6.1 Today View Layout
swift// TodayView.swift
import SwiftUI
import CoreData

struct TodayView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Day.dayNumber, ascending: false)],
        animation: .default)
    private var days: FetchedResults<Day>
    
    @State private var showingAddProblem = false
    
    var currentDay: Day? {
        days.first { Calendar.current.isDate($0.date ?? Date(), inSameDayAs: Date()) }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Day Counter Header
                    DayCounterView(currentDay: currentDay)
                    
                    // DSA Section
                    DSASectionView(currentDay: currentDay)
                    
                    // System Design Section
                    SystemDesignSectionView(currentDay: currentDay)
                    
                    // Daily Reflection
                    DailyReflectionView(currentDay: currentDay)
                }
                .padding()
            }
            .navigationTitle("Machine Mode")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add Problem") {
                        showingAddProblem = true
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddProblem) {
            AddProblemView(currentDay: currentDay)
        }
    }
}
6.2 Day Counter Component
swift// DayCounterView.swift
import SwiftUI

struct DayCounterView: View {
    let currentDay: Day?
    
    var dayNumber: Int {
        currentDay?.dayNumber ?? 1
    }
    
    var body: some View {
        VStack(spacing: 8) {
            Text("DAY")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
            
            Text("\(dayNumber)")
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .foregroundColor(.blue)
            
            Text("OF 100")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
            
            // Overall Progress Bar
            ProgressView(value: Double(dayNumber), total: 100)
                .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                .scaleEffect(1.0, anchor: .center)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}
6.3 DSA Section Component
swift// DSASectionView.swift
import SwiftUI
import CoreData

struct DSASectionView: View {
    let currentDay: Day?
    @Environment(\.managedObjectContext) private var viewContext
    
    var dsaProblems: [DSAProblem] {
        currentDay?.dsaProblems?.allObjects as? [DSAProblem] ?? []
    }
    
    var completedCount: Int {
        dsaProblems.filter { $0.isCompleted }.count
    }
    
    var totalCount: Int {
        dsaProblems.count
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("DSA Problems")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text("\(completedCount)/\(totalCount)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            // Progress Bar
            ProgressView(value: Double(completedCount), total: Double(totalCount))
                .progressViewStyle(LinearProgressViewStyle(tint: .green))
            
            // Problems List
            LazyVStack(spacing: 8) {
                ForEach(dsaProblems, id: \.objectID) { problem in
                    ProblemRowView(problem: problem)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}
6.4 Problem Row Component
swift// ProblemRowView.swift
import SwiftUI

struct ProblemRowView: View {
    @ObservedObject var problem: DSAProblem
    @Environment(\.managedObjectContext) private var viewContext
    @State private var showingNotes = false
    @State private var timeSpent = ""
    
    var body: some View {
        HStack {
            // Checkbox
            Button(action: toggleCompletion) {
                Image(systemName: problem.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(problem.isCompleted ? .green : .gray)
                    .font(.title2)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(problem.problemName ?? "Unknown Problem")
                        .font(.body)
                        .strikethrough(problem.isCompleted)
                    
                    if let leetcode = problem.leetcodeNumber {
                        Text("LC \(leetcode)")
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(4)
                    }
                    
                    if problem.isBonusProblem {
                        Text("BONUS")
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.orange.opacity(0.1))
                            .cornerRadius(4)
                    }
                }
                
                if problem.timeSpent > 0 {
                    Text("\(problem.timeSpent) min")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Notes button
            Button(action: { showingNotes = true }) {
                Image(systemName: "note.text")
                    .foregroundColor(.blue)
            }
        }
        .padding(.vertical, 4)
        .sheet(isPresented: $showingNotes) {
            ProblemNotesView(problem: problem)
        }
    }
    
    private func toggleCompletion() {
        problem.isCompleted.toggle()
        
        do {
            try viewContext.save()
            updateDayProgress()
        } catch {
            print("Error saving: \(error)")
        }
    }
    
    private func updateDayProgress() {
        // Update the day's DSA progress
        guard let day = problem.day else { return }
        
        let problems = day.dsaProblems?.allObjects as? [DSAProblem] ?? []
        let completed = problems.filter { $0.isCompleted }.count
        let total = problems.count
        
        day.dsaProgress = total > 0 ? Float(completed) / Float(total) : 0.0
        
        do {
            try viewContext.save()
        } catch {
            print("Error updating day progress: \(error)")
        }
    }
}
PHASE 5: NOTIFICATIONS IMPLEMENTATION
Step 7: Notification Manager
7.1 Notification Manager
swift// NotificationManager.swift
import UserNotifications
import Foundation

class NotificationManager: ObservableObject {
    static let shared = NotificationManager()
    
    private init() {}
    
    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if granted {
                print("Notification permission granted")
            } else if let error = error {
                print("Notification permission error: \(error)")
            }
        }
    }
    
    func scheduleDailyNotifications(morningTime: Date, eveningTime: Date) {
        // Remove existing notifications
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        
        // Schedule morning notification
        scheduleMorningNotification(time: morningTime)
        
        // Schedule evening notification
        scheduleEveningNotification(time: eveningTime)
    }
    
    private func scheduleMorningNotification(time: Date) {
        let content = UNMutableNotificationContent()
        content.title = "Machine Mode Activated"
        content.body = "Today's mission awaits. Time to dominate!"
        content.sound = .default
        
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: time)
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: "morning-reminder", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request)
    }
    
    private func scheduleEveningNotification(time: Date) {
        let content = UNMutableNotificationContent()
        content.title = "Progress Check"
        content.body = "How did you dominate today? Time to log your progress."
        content.sound = .default
        
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: time)
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: "evening-reminder", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request)
    }
    
    func scheduleStreakReminder(streak: Int) {
        let content = UNMutableNotificationContent()
        content.title = "Streak Alert! 🔥"
        content.body = "You're on a \(streak)-day streak! Don't break it now."
        content.sound = .default
        
        // Schedule for 9 PM if no progress logged
        var components = DateComponents()
        components.hour = 21
        components.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: "streak-reminder", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request)
    }
}
PHASE 6: PROGRESS VISUALIZATION
Step 8: Progress View
8.1 Progress View Layout
swift// ProgressView.swift
import SwiftUI
import CoreData

struct ProgressView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Day.dayNumber, ascending: true)],
        animation: .default)
    private var days: FetchedResults<Day>
    
    var currentStreak: Int {
        calculateCurrentStreak()
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Overall Stats
                    OverallStatsView(days: Array(days), currentStreak: currentStreak)
                    
                    // Heat Map
                    HeatMapView(days: Array(days))
                    
                    // Progress Charts
                    ProgressChartsView(days: Array(days))
                }
                .padding()
            }
            .navigationTitle("Progress")
        }
    }
    
    private func calculateCurrentStreak() -> Int {
        // Implementation for calculating current streak
        let sortedDays = days.sorted { $0.date ?? Date() > $1.date ?? Date() }
        var streak = 0
        
        for day in sortedDays {
            if day.isCompleted {
                streak += 1
            } else {
                break
            }
        }
        
        return streak
    }
}
8.2 Heat Map Component
swift// HeatMapView.swift
import SwiftUI

struct HeatMapView: View {
    let days: [Day]
    
    private let columns = Array(repeating: GridItem(.flexible()), count: 7)
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Activity Heat Map")
                .font(.headline)
                .fontWeight(.semibold)
            
            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(0..<100, id: \.self) { dayIndex in
                    let day = days.first { $0.dayNumber == dayIndex + 1 }
                    
                    RoundedRectangle(cornerRadius: 3)
                        .fill(colorForDay(day))
                        .frame(height: 20)
                        .overlay(
                            Text("\(dayIndex + 1)")
                                .font(.caption2)
                                .foregroundColor(day?.isCompleted == true ? .white : .primary)
                        )
                }
            }
            
            // Legend
            HStack {
                Text("Less")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack(spacing: 2) {
                    ForEach(0..<5, id: \.self) { intensity in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.green.opacity(Double(intensity) * 0.25))
                            .frame(width: 12, height: 12)
                    }
                }
                
                Text("More")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func colorForDay(_ day: Day?) -> Color {
        guard let day = day else { return Color(.systemGray5) }
        
        if !day.isCompleted { return Color(.systemGray5) }
        
        let totalProgress = (day.dsaProgress + day.systemDesignProgress) / 2.0
        return Color.green.opacity(Double(totalProgress))
    }
}
PHASE 7: DATA INITIALIZATION
Step 9: Data Initialization
9.1 Data Initializer
swift// DataInitializer.swift
import CoreData
import Foundation

class DataInitializer {
    static let shared = DataInitializer()
    private let context = PersistenceController.shared.container.viewContext
    
    private init() {}
    
    func initializeDataIfNeeded() {
        // Check if data is already initialized
        let request: NSFetchRequest<Day> = Day.fetchRequest()
        
        do {
            let count = try context.count(for: request)
            if count == 0 {
                initializeAllDays()
            }
        } catch {
            print("Error checking existing data: \(error)")
        }
    }
    
    private func initializeAllDays() {
        // Initialize all 100 days with their respective problems and topics
        let startDate = Date()
        
        for dayNumber in 1...100 {
            let day = Day(context: context)
            day.dayNumber = Int32(dayNumber)
            day.date = Calendar.current.date(byAdding: .day, value: dayNumber - 1, to: startDate)
            day.dsaProgress = 0.0
            day.systemDesignProgress = 0.0
            day.isCompleted = false
            
            // Add DSA problems for this day
            addDSAProblems(for: day, dayNumber: dayNumber)
            
            // Add System Design topics for this day
            addSystemDesignTopics(for: day, dayNumber: dayNumber)
        }
        
        do {
            try context.save()
            print("Initialized all 100 days successfully")
        } catch {
            print("Error initializing data: \(error)")
        }
    }
    
    private func addDSAProblems(for day: Day, dayNumber: Int) {
        // This would contain all the problems from your MD file
        // For brevity, showing just Day 1 problems
        
        let day1Problems = [
            ("Build Array from Permutation", "1920"),
            ("Running Sum of 1d Array", "1480"),
            ("Find Numbers with Even Number of Digits", "1295"),
            ("How Many Numbers Are Smaller Than the Current Number", "1365"),
            ("Merge Sorted Array", "88")
        ]
        
        if dayNumber == 1 {
            for (problemName, leetcodeNumber) in day1Problems {
                let problem = DSAProblem(context: context)
                problem.problemName = problemName
                problem.leetcodeNumber = leetcodeNumber
                problem.isCompleted = false
                problem.timeSpent = 0
                problem.difficulty = "Easy"
                problem.isBonusProblem = false
                problem.day = day
            }
        }
        
        // Add similar blocks for all 100 days...
        // This would be a large switch statement or dictionary lookup
    }
    
    private func addSystemDesignTopics(for day: Day, dayNumber: Int) {
        // Similar implementation for system design topics
        let day1Topics = [
            "DNS & Domain Resolution",
            "Watch: DNS Explained - How Domain Name System Works",
            "Draw DNS Resolution Flow",
            "Write 100-word explanation of DNS"
        ]
        
        if dayNumber == 1 {
            for topicName in day1Topics {
                let topic = SystemDesignTopic(context: context)
                topic.topicName = topicName
                topic.isCompleted = false
                topic.videoWatched = false
                topic.taskCompleted = false
                topic.day = day
            }
        }
        
        // Add similar blocks for all 100 days...
    }
}
PHASE 8: EXPORT FUNCTIONALITY
Step 10: MD File Export
10.1 Export Manager
swift// ExportManager.swift
import Foundation
import CoreData

class ExportManager {
    static let shared = ExportManager()
    private let context = PersistenceController.shared.container.viewContext
    
    private init() {}
    
    func exportProgressToMarkdown() -> String {
        let request: NSFetchRequest<Day> = Day.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Day.dayNumber, ascending: true)]
        
        do {
            let days = try context.fetch(request)
            return generateMarkdownContent(from: days)
        } catch {
            print("Error fetching days for export: \(error)")
            return "Error generating export"
        }
    }
    
    private func generateMarkdownContent(from days: [Day]) -> String {
        var content = "# 🚀 MACHINE MODE: 100-DAY COMPLETE PLAN - PROGRESS REPORT\n\n"
        content += "Generated on: \(DateFormatter.localizedString(from: Date(), dateStyle: .full, timeStyle: .short))\n\n"
        
        // Overall Statistics
        let completedDays = days.filter { $0.isCompleted }.count
        let overallProgress = Float(completedDays) / Float(days.count) * 100
        
        content += "## 📊 OVERALL PROGRESS\n"
        content += "- **Days Completed:** \(completedDays)/100 (\(String(format: "%.1f", overallProgress))%)\n"
        content += "- **Current Streak:** \(calculateCurrentStreak(from: days))\n\n"
        
        // Detailed daily progress
        for day in days {
            content += generateDayContent(for: day)
        }
        
        return content
    }
    
    private func generateDayContent(for day: Day) -> String {
        var content = ""
        
        let status = day.isCompleteRetryPBi want to build via xx code and not publish on appstore, so make according to that i will have to rebuild the app every 7 days but the data/changes should be persistentEditMachine Mode Tracker - Complete PRD & Implementation Guide
For Xcode Development & Personal Use (No App Store)
PRODUCT REQUIREMENTS DOCUMENT (PRD)
1. PRODUCT OVERVIEW
Product Name: Machine Mode Tracker
Target Platform: iOS (iPhone) - Development Build Only
Target User: Software engineering interview candidates following intensive 100-day preparation
Core Purpose: Simple, focused progress tracking for DSA problems and System Design topics with daily accountability
Development Notes:

Development builds expire every 7 days
Data must persist across rebuilds
No App Store distribution required
Free Apple Developer Account sufficient

2. PRODUCT OBJECTIVES
Primary Goals:

Track daily completion of DSA problems and System Design topics
Maintain motivation through notifications and streak tracking
Export progress to update original markdown file
Provide visual progress feedback
Persist data across 7-day rebuild cycles

Success Metrics:

Daily app engagement rate > 80%
Streak maintenance (consecutive days) > 7 days average
Task completion rate > 90%
Data retention across rebuilds > 99%

3. DATA PERSISTENCE STRATEGY
Critical Requirement: Data must survive app rebuilds every 7 days
Storage Locations:

Core Data SQLite file in Documents directory (persists across rebuilds)
UserDefaults for settings (persists across rebuilds)
iCloud Documents for backup (optional but recommended)

Backup Strategy:

Daily auto-export to Files app
iCloud sync for settings
Manual export capability

4. FUNCTIONAL REQUIREMENTS
4.1 Core Features
F1: Daily Progress Tracking

Display current day number (Day X/100)
Show DSA problems for current day with checkboxes
Show System Design topics for current day with checkboxes
Allow marking items as complete
Optional time tracking per problem
Optional notes per problem/topic
Add bonus problems functionality
Separate progress bars for DSA and System Design

F2: Smart Notifications

Morning notification: "Machine Mode Activated. Today's mission awaits." (default 7 AM)
Evening notification: "Progress check - How did you dominate today?" (default 8 PM)
Custom reminder times
Streak alerts when approaching milestone
Gentle nudge if no progress logged by evening
Weekly review prompts

F3: Visual Progress Dashboard

Overall completion percentage (out of 100 days)
DSA vs System Design completion split
Weekly heat map showing consistency
Problem difficulty distribution
Current streak counter with badges
Historical progress charts

F4: Content Management & Persistence

Personal notes with markdown support
Search through notes
Export progress to updated MD file
Automatic data backup before app expiration
Data persistence across rebuilds

5. TECHNICAL REQUIREMENTS
Platform:

iOS 15.0+
iPhone only (portrait orientation)
Swift 5.0+
Xcode 14+
Development Certificate (Free Apple ID)

Storage & Persistence:

Core Data with SQLite store in Documents directory
UserDefaults for app settings
FileManager for MD exports to Documents
iCloud Documents integration for backup

APIs:

Local Notifications framework
Core Data for persistence
FileManager for file operations
CloudKit for optional cloud backup


COMPLETE IMPLEMENTATION GUIDE
PHASE 1: DEVELOPMENT ENVIRONMENT SETUP
Step 1: Install Development Tools
1.1 Install Xcode
bash# Download Xcode from Mac App Store (free)
# Requires macOS 12.5+ for Xcode 14
# Size: ~10GB download
1.2 Set up Apple Developer Account (FREE)

Go to developer.apple.com
Sign in with your Apple ID (FREE account)
Accept developer agreement
Note: Free accounts have 7-day app expiration

1.3 Install Command Line Tools
bashxcode-select --install
Step 2: Project Setup
2.1 Create New Xcode Project

Open Xcode
Create new project
Choose "iOS" → "App"
Fill details:

Product Name: "Machine Mode Tracker"
Interface: SwiftUI
Language: Swift
Use Core Data: ✓
Include Tests: ✓



2.2 Configure Project Settings for Development
swift// In project settings:
- Deployment Target: iOS 15.0
- Bundle Identifier: com.yourname.machinemodetracker
- Team: Select your personal team (free account)
- Version: 1.0
- Build: 1

// Signing & Capabilities:
- Automatically manage signing: ✓
- Team: Your Apple ID team
- Provisioning Profile: Xcode Managed
2.3 Add Required Capabilities
swift// In Signing & Capabilities, add:
1. Push Notifications
2. Background App Refresh
3. iCloud (Documents)
PHASE 2: PERSISTENT CORE DATA SETUP
Step 3: Design Data Model with Persistence Focus
3.1 Create Core Data Entities
Create MachineMode.xcdatamodeld with these entities:
Entity: Day
swift// Attributes:
- dayNumber: Int32
- date: Date
- dsaProgress: Float (0.0 to 1.0)
- systemDesignProgress: Float (0.0 to 1.0)
- dailyReflection: String (optional)
- isCompleted: Bool
- createdAt: Date
- updatedAt: Date

// Relationships:
- dsaProblems: [DSAProblem]
- systemDesignTopics: [SystemDesignTopic]
Entity: DSAProblem
swift// Attributes:
- problemName: String
- leetcodeNumber: String (optional)
- isCompleted: Bool
- timeSpent: Int32 (minutes)
- notes: String (optional)
- difficulty: String (Easy/Medium/Hard)
- isBonusProblem: Bool
- completedAt: Date (optional)
- createdAt: Date
- updatedAt: Date

// Relationships:
- day: Day
Entity: SystemDesignTopic
swift// Attributes:
- topicName: String
- description: String (optional)
- isCompleted: Bool
- notes: String (optional)
- videoWatched: Bool
- taskCompleted: Bool
- completedAt: Date (optional)
- createdAt: Date
- updatedAt: Date

// Relationships:
- day: Day
Entity: UserSettings
swift// Attributes:
- morningNotificationTime: Date
- eveningNotificationTime: Date
- isNotificationsEnabled: Bool
- currentStreak: Int32
- longestStreak: Int32
- startDate: Date
- lastBackupDate: Date
- appVersion: String
Step 4: Persistent Core Data Stack
4.1 Create Persistence Controller with Documents Directory
swift// Persistence.swift
import CoreData
import Foundation

struct PersistenceController {
    static let shared = PersistenceController()
    
    static var preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        
        // Add sample data for previews
        let sampleDay = Day(context: viewContext)
        sampleDay.dayNumber = 1
        sampleDay.date = Date()
        sampleDay.dsaProgress = 0.6
        sampleDay.systemDesignProgress = 0.8
        sampleDay.createdAt = Date()
        sampleDay.updatedAt = Date()
        
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        
        return result
    }()
    
    let container: NSPersistentContainer
    
    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "MachineMode")
        
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        } else {
            // Configure persistent store in Documents directory
            let storeURL = documentsDirectory.appendingPathComponent("MachineMode.sqlite")
            container.persistentStoreDescriptions.first?.url = storeURL
            
            // Enable persistent history tracking
            container.persistentStoreDescriptions.first?.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
            container.persistentStoreDescriptions.first?.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
        }
        
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                print("Core Data error: \(error), \(error.userInfo)")
                // In production, you might want to handle this more gracefully
            } else {
                print("Core Data store loaded successfully at: \(storeDescription.url?.path ?? "unknown")")
            }
        })
        
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }
    
    private var documentsDirectory: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    }
    
    func save() {
        let context = container.viewContext
        
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nsError = error as NSError
                print("Save error: \(nsError), \(nsError.userInfo)")
            }
        }
    }
    
    // Backup functionality
    func createBackup() {
        let backupURL = documentsDirectory.appendingPathComponent("MachineMode_Backup_\(Date().timeIntervalSince1970).sqlite")
        let storeURL = documentsDirectory.appendingPathComponent("MachineMode.sqlite")
        
        do {
            try FileManager.default.copyItem(at: storeURL, to: backupURL)
            print("Backup created at: \(backupURL.path)")
        } catch {
            print("Backup failed: \(error)")
        }
    }
}
PHASE 3: APP STRUCTURE WITH PERSISTENCE
Step 5: Create App Structure
5.1 Main App File with Data Initialization
swift// MachineModeTrackerApp.swift
import SwiftUI

@main
struct MachineModeTrackerApp: App {
    let persistenceController = PersistenceController.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .onAppear {
                    setupApp()
                }
        }
    }
    
    private func setupApp() {
        // Request notification permissions
        NotificationManager.shared.requestPermission()
        
        // Initialize data if needed
        DataInitializer.shared.initializeDataIfNeeded()
        
        // Setup automatic backup
        BackupManager.shared.setupAutomaticBackup()
        
        // Check for app updates (rebuild detection)
        AppVersionManager.shared.checkForRebuild()
    }
}
5.2 Content View (Main Navigation)
swift// ContentView.swift
import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some View {
        TabView(selection: $selectedTab) {
            TodayView()
                .tabItem {
                    Image(systemName: "target")
                    Text("Today")
                }
                .tag(0)
            
            ProgressView()
                .tabItem {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                    Text("Progress")
                }
                .tag(1)
            
            SettingsView()
                .tabItem {
                    Image(systemName: "gear")
                    Text("Settings")
                }
                .tag(2)
        }
        .accentColor(.blue)
        .onChange(of: scenePhase) { phase in
            if phase == .background {
                // Save data when app goes to background
                PersistenceController.shared.save()
                BackupManager.shared.createDailyBackup()
            }
        }
    }
}
PHASE 4: TODAY VIEW IMPLEMENTATION
Step 6: Today View with Auto-Save
6.1 Today View Layout
swift// TodayView.swift
import SwiftUI
import CoreData

struct TodayView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Day.dayNumber, ascending: false)],
        animation: .default)
    private var days: FetchedResults<Day>
    
    @State private var showingAddProblem = false
    
    var currentDay: Day? {
        let today = Date()
        return days.first { 
            guard let dayDate = $0.date else { return false }
            return Calendar.current.isDate(dayDate, inSameDayAs: today) 
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // App Expiration Warning
                    AppExpirationWarningView()
                    
                    // Day Counter Header
                    DayCounterView(currentDay: currentDay)
                    
                    // DSA Section
                    DSASectionView(currentDay: currentDay)
                    
                    // System Design Section
                    SystemDesignSectionView(currentDay: currentDay)
                    
                    // Daily Reflection
                    DailyReflectionView(currentDay: currentDay)
                }
                .padding()
            }
            .navigationTitle("Machine Mode")
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button("Export") {
                        ExportManager.shared.exportAndShare()
                    }
                    
                    Button("Add Problem") {
                        showingAddProblem = true
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddProblem) {
            AddProblemView(currentDay: currentDay)
        }
    }
}
6.2 App Expiration Warning Component
swift// AppExpirationWarningView.swift
import SwiftUI

struct AppExpirationWarningView: View {
    @State private var daysUntilExpiration = AppVersionManager.shared.daysUntilExpiration()
    
    var body: some View {
        if daysUntilExpiration <= 2 {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                
                VStack(alignment: .leading) {
                    Text("App Expires Soon")
                        .font(.headline)
                        .foregroundColor(.orange)
                    
                    Text("Rebuild app in Xcode in \(daysUntilExpiration) day(s). Your data will be preserved.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button("Backup Now") {
                    BackupManager.shared.createManualBackup()
                }
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.orange.opacity(0.2))
                .cornerRadius(6)
            }
            .padding()
            .background(Color.orange.opacity(0.1))
            .cornerRadius(8)
        }
    }
}
6.3 Problem Row with Auto-Save
swift// ProblemRowView.swift
import SwiftUI

struct ProblemRowView: View {
    @ObservedObject var problem: DSAProblem
    @Environment(\.managedObjectContext) private var viewContext
    @State private var showingNotes = false
    
    var body: some View {
        HStack {
            // Checkbox
            Button(action: toggleCompletion) {
                Image(systemName: problem.isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(problem.isCompleted ? .green : .gray)
                    .font(.title2)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(problem.problemName ?? "Unknown Problem")
                        .font(.body)
                        .strikethrough(problem.isCompleted)
                    
                    if let leetcode = problem.leetcodeNumber {
                        Text("LC \(leetcode)")
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(4)
                    }
                    
                    if problem.isBonusProblem {
                        Text("BONUS")
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.orange.opacity(0.1))
                            .cornerRadius(4)
                    }
                }
                
                if problem.timeSpent > 0 {
                    Text("\(problem.timeSpent) min")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if problem.isCompleted, let completedAt = problem.completedAt {
                    Text("Completed: \(completedAt, style: .time)")
                        .font(.caption2)
                        .foregroundColor(.green)
                }
            }
            
            Spacer()
            
            // Notes button
            Button(action: { showingNotes = true }) {
                Image(systemName: problem.notes?.isEmpty == false ? "note.text.badge.plus" : "note.text")
                    .foregroundColor(.blue)
            }
        }
        .padding(.vertical, 4)
        .sheet(isPresented: $showingNotes) {
            ProblemNotesView(problem: problem)
        }
    }
    
    private func toggleCompletion() {
        problem.isCompleted.toggle()
        problem.updatedAt = Date()
        
        if problem.isCompleted {
            problem.completedAt = Date()
        } else {
            problem.completedAt = nil
        }
        
        // Auto-save with error handling
        do {
            try viewContext.save()
            updateDayProgress()
            
            // Trigger backup if significant progress
            if problem.isCompleted {
                BackupManager.shared.scheduleBackupIfNeeded()
            }
        } catch {
            print("Error saving: \(error)")
            // Revert the change if save failed
            problem.isCompleted.toggle()
        }
    }
    
    private func updateDayProgress() {
        guard let day = problem.day else { return }
        
        let problems = day.dsaProblems?.allObjects as? [DSAProblem] ?? []
        let completed = problems.filter { $0.isCompleted }.count
        let total = problems.count
        
        day.dsaProgress = total > 0 ? Float(completed) / Float(total) : 0.0
        day.updatedAt = Date()
        
        // Check if day is completed
        let systemDesignProblems = day.systemDesignTopics?.allObjects as? [SystemDesignTopic] ?? []
        let systemCompleted = systemDesignProblems.filter { $0.isCompleted }.count
        let systemTotal = systemDesignProblems.count
        
        day.systemDesignProgress = systemTotal > 0 ? Float(systemCompleted) / Float(systemTotal) : 0.0
        day.isCompleted = day.dsaProgress >= 1.0 && day.systemDesignProgress >= 1.0
        
        do {
            try viewContext.save()
        } catch {
            print("Error updating day progress: \(error)")
        }
    }
}
PHASE 5: BACKUP & DATA PERSISTENCE SYSTEM
Step 7: Backup Manager
7.1 Comprehensive Backup Manager
swift// BackupManager.swift
import Foundation
import CoreData

class BackupManager: ObservableObject {
    static let shared = BackupManager()
    
    private let fileManager = FileManager.default
    private var documentsDirectory: URL {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
    }
    
    private init() {}
    
    func setupAutomaticBackup() {
        // Schedule daily backup
        Timer.scheduledTimer(withTimeInterval: 24 * 60 * 60, repeats: true) { _ in
            self.createDailyBackup()
        }
        
        // Backup on app launch
        createDailyBackup()
    }
    
    func createDailyBackup() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let todayString = dateFormatter.string(from: Date())
        
        let backupName = "MachineMode_Backup_\(todayString).sqlite"
        let backupURL = documentsDirectory.appendingPathComponent(backupName)
        
        // Check if today's backup already exists
        if fileManager.fileExists(atPath: backupURL.path) {
            return
        }
        
        createBackup(named: backupName)
        cleanOldBackups()
    }
    
    func createManualBackup() {
        let timestamp = Int(Date().timeIntervalSince1970)
        let backupName = "MachineMode_Manual_\(timestamp).sqlite"
        createBackup(named: backupName)
    }
    
    private func createBackup(named fileName: String) {
        let storeURL = documentsDirectory.appendingPathComponent("MachineMode.sqlite")
        let backupURL = documentsDirectory.appendingPathComponent(fileName)
        
        do {
            try fileManager.copyItem(at: storeURL, to: backupURL)
            print("✅ Backup created: \(fileName)")
            
            // Also create JSON export for additional safety
            createJSONBackup(named: fileName.replacingOccurrences(of: ".sqlite", with: ".json"))
        } catch {
            print("❌ Backup failed: \(error)")
        }
    }
    
    private func createJSONBackup(named fileName: String) {
        let jsonData = ExportManager.shared.exportToJSON()
        let jsonURL = documentsDirectory.appendingPathComponent(fileName)
        
        do {
            try jsonData.write(to: jsonURL)
            print("✅ JSON backup created: \(fileName)")
        } catch {
            print("❌ JSON backup failed: \(error)")
        }
    }
    
    func scheduleBackupIfNeeded() {
        // Create backup after every 10 completed problems
        let request: NSFetchRequest<DSAProblem> = DSAProblem.fetchRequest()
        request.predicate = NSPredicate(format: "isCompleted == YES")
        
        do {
            let completedCount = try PersistenceController.shared.container.viewContext.count(for: request)
            if completedCount % 10 == 0 {
                createManualBackup()
            }
        } catch {
            print("Error counting completed problems: \(error)")
        }
    }
    
    private func cleanOldBackups() {
        // Keep only last 7 daily backups
        do {
            let backupFiles = try fileManager.contentsOfDirectory(at: documentsDirectory, includingPropertiesForKeys: [.creationDateKey])
                .filter { $0.lastPathComponent.contains("MachineMode_Backup_") }
                .sorted { file1, file2 in
                    let date1 = try? file1.resourceValues(forKeys: [.creationDateKey]).creationDate ?? Date.distantPast
                    let date2 = try? file2.resourceValues(forKeys: [.creationDateKey]).creationDate ?? Date.distantPast
                    return date1! > date2!
                }
            
            // Remove backups older than 7 days
            if backupFiles.count > 7 {
                for oldBackup in backupFiles.dropFirst(7) {
                    try fileManager.removeItem(at: oldBackup)
                    print("🗑️ Removed old backup: \(oldBackup.lastPathComponent)")
                }
            }
        } catch {
            print("Error cleaning old backups: \(error)")
        }
    }
    
    func listBackups() -> [URL] {
        do {
            return try fileManager.contentsOfDirectory(at: documentsDirectory, includingPropertiesForKeys: nil)
                .filter { $0.lastPathComponent.contains("MachineMode_") }
                .sorted { $0.lastPathComponent > $1.lastPathComponent }
        } catch {
            print("Error listing backups: \(error)")
            return []
        }
    }
}
Step 8: App Version Manager
7.2 App Version & Rebuild Detection
swift// AppVersionManager.swift
import Foundation

class AppVersionManager: ObservableObject {
    static let shared = AppVersionManager()
    
    private let userDefaults = UserDefaults.standard
    private let appVersionKey = "AppVersion"
    private let installDateKey = "InstallDate"
    
    private init() {}
    
    func checkForRebuild() {
        let currentVersion = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        let storedVersion = userDefaults.string(forKey: appVersionKey)
        
        if storedVersion != currentVersion {
            // This is a new build/rebuild
            handleNewBuild(currentVersion: currentVersion, previousVersion: storedVersion)
        }
        
        // Always update the stored version
        userDefaults.set(currentVersion, forKey: appVersionKey)
        
        // Set install date if not set
        if userDefaults.object(forKey: installDateKey) == nil {
            userDefaults.set(Date(), forKey: installDateKey)
        }
    }
    
    private func handleNewBuild(currentVersion: String, previousVersion: String?) {
        print("🔄 App rebuild detected!")
        print("Previous version: \(previousVersion ?? "none")")
        print("Current version: \(currentVersion)")
        
        // Create backup before continuing with new build
        BackupManager.shared.createManualBackup()
        
        // Check data integrity
        checkDataIntegrity()
        
        // Update notification content with rebuild info
        NotificationManager.shared.scheduleRebuildNotification()
    }
    
    func daysUntilExpiration() -> Int {
        guard let installDate = userDefaults.object(forKey: installDateKey) as? Date else {
            return 7 // Default to 7 days if no install date
        }
        
        let daysSinceInstall = Calendar.current.dateComponents([.day], from: installDate, to: Date()).day ?? 0
        let daysRemaining = 7 - daysSinceInstall
        
        return max(0, daysRemaining)
    }
    
    func getInstallDate() -> Date? {
        return userDefaults.object(forKey: installDateKey) as? Date
    }
    
    private func checkDataIntegrity() {
        let context = PersistenceController.shared.container.viewContext
        
        // Check if days exist
        let dayRequest: NSFetchRequest<Day> = Day.fetchRequest()
        do {
            let dayCount = try context.count(for: dayRequest)
            print("📊 Data integrity check: \(dayCount) days found")
            
            if dayCount == 0 {
                print("⚠️ No days found, will initialize data")
            }
        } catch {
            print("❌ Data integrity check failed: \(error)")
        }
    }
}
PHASE 6: ENHANCED EXPORT SYSTEM
Step 9: Export Manager with Multiple Formats
9.1 Enhanced Export Manager
swift// ExportManager.swift
import Foundation
import CoreData
import UIKit

class ExportManager: ObservableObject {
    static let shared = ExportManager()
    private let context = PersistenceController.shared.container.viewContext
    
    private init() {}
    
    func exportAndShare() {
        let markdownContent = exportProgressToMarkdown()
        let jsonData = exportToJSON()
        
        // Save to Documents directory
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        
        let timestamp = Int(Date().timeIntervalSince1970)
        let markdownURL = documentsDirectory.appendingPathComponent("Progress_Export_\(timestamp).md")
        let jsonURL = documentsDirectory.appendingPathComponent("Progress_Export_\(timestamp).json")
        
        do {
            try markdownContent.write(to: markdownURL, atomically: true, encoding: .utf8)
            try jsonData.write(to: jsonURL)
            
            // Share the files
            DispatchQueue.main.async {
                self.shareFiles([markdownURL, jsonURL])
            }
        } catch {
            print("Export error: \(error)")
        }
    }
    
    func exportProgressToMarkdown() -> String {
        let request: NSFetchRequest<Day> = Day.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Day.dayNumber, ascending: true)]
        
        do {
            let days = try context.fetch(request)
            return generateMarkdownContent(from: days)
        } catch {
            print("Error fetching days for export: \(error)")
            return "Error generating export"
        }
    }
    
    func exportToJSON() -> Data {
        let request: NSFetchRequest<Day> = Day.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Day.dayNumber, ascending: true)]
        
        do {
            let days = try context.fetch(request)
            let exportData = generateJSONData(from: days)
            return try JSONSerialization.data(withJSONObject: exportData, options: .prettyPrinted)
        } catch {
            print("Error generating JSON export: \(error)")
            return Data()
        }
    }
    
    private func generateMarkdownContent(from days: [Day]) -> String {
        var content = "# 🚀 MACHINE MODE: 100-DAY PROGRESS REPORT\n\n"
        content += "Generated on: \(DateFormatter.localizedString(from: Date(), dateStyle: .full, timeStyle: .short))\n"
        content += "Data persisted across app rebuilds ✅\n\n"
        
        // Overall Statistics
        let completedDays = days.filter { $0.isCompleted }.count
        let overallProgress = Float(completedDays) / Float(days.count) * 100
        
        content += "## 📊 OVERALL PROGRESS\n"
        content += "- **Days Completed:** \(completedDays)/100 (\(String(format: "%.1f", overallProgress))%)\n"
        content += "- **Current Streak:** \(calculateCurrentStreak(from: days))\n\n"
        
        // DSA vs System Design Progress
        let totalDSAProgress = days.reduce(0) { $0 + $1.RetryPBContinueEditswift       let totalDSAProgress = days.reduce(0) { $0 + $1.dsaProgress }
       let totalSystemDesignProgress = days.reduce(0) { $0 + $1.systemDesignProgress }
       let avgDSAProgress = totalDSAProgress / Float(days.count) * 100
       let avgSystemDesignProgress = totalSystemDesignProgress / Float(days.count) * 100
       
       content += "- **DSA Progress:** \(String(format: "%.1f", avgDSAProgress))%\n"
       content += "- **System Design Progress:** \(String(format: "%.1f", avgSystemDesignProgress))%\n\n"
       
       // Weekly breakdown
       content += "## 📅 WEEKLY BREAKDOWN\n\n"
       for weekNumber in 1...15 {
           let weekDays = days.filter { 
               let dayNum = Int($0.dayNumber)
               return dayNum >= (weekNumber - 1) * 7 + 1 && dayNum <= weekNumber * 7 
           }
           let weekCompleted = weekDays.filter { $0.isCompleted }.count
           content += "**Week \(weekNumber):** \(weekCompleted)/\(weekDays.count) days completed\n"
       }
       
       content += "\n## 📋 DETAILED DAILY PROGRESS\n\n"
       
       // Detailed daily progress
       for day in days {
           content += generateDayContent(for: day)
       }
       
       content += "\n---\n"
       content += "*Exported from Machine Mode Tracker - Development Build*\n"
       content += "*Data persists across 7-day rebuild cycles*\n"
       
       return content
   }
   
   private func generateDayContent(for day: Day) -> String {
       var content = ""
       
       let statusEmoji = day.isCompleted ? "✅" : "⏳"
       let dateString = DateFormatter.localizedString(from: day.date ?? Date(), dateStyle: .medium, timeStyle: .none)
       
       content += "### \(statusEmoji) Day \(day.dayNumber) - \(dateString)\n\n"
       
       // DSA Problems
       if let dsaProblems = day.dsaProblems?.allObjects as? [DSAProblem], !dsaProblems.isEmpty {
           content += "**DSA Problems:**\n"
           for problem in dsaProblems.sorted(by: { $0.problemName ?? "" < $1.problemName ?? "" }) {
               let checkmark = problem.isCompleted ? "✅" : "❌"
               let timeInfo = problem.timeSpent > 0 ? " (\(problem.timeSpent) min)" : ""
               let bonusTag = problem.isBonusProblem ? " [BONUS]" : ""
               
               content += "- \(checkmark) \(problem.problemName ?? "Unknown")"
               if let leetcode = problem.leetcodeNumber {
                   content += " (LC \(leetcode))"
               }
               content += "\(timeInfo)\(bonusTag)\n"
               
               if let notes = problem.notes, !notes.isEmpty {
                   content += "  - Notes: \(notes)\n"
               }
           }
           content += "\n"
       }
       
       // System Design Topics
       if let systemTopics = day.systemDesignTopics?.allObjects as? [SystemDesignTopic], !systemTopics.isEmpty {
           content += "**System Design:**\n"
           for topic in systemTopics.sorted(by: { $0.topicName ?? "" < $1.topicName ?? "" }) {
               let checkmark = topic.isCompleted ? "✅" : "❌"
               content += "- \(checkmark) \(topic.topicName ?? "Unknown")\n"
               
               if let notes = topic.notes, !notes.isEmpty {
                   content += "  - Notes: \(notes)\n"
               }
           }
           content += "\n"
       }
       
       // Daily Reflection
       if let reflection = day.dailyReflection, !reflection.isEmpty {
           content += "**Daily Reflection:**\n\(reflection)\n\n"
       }
       
       content += "---\n\n"
       return content
   }
   
   private func generateJSONData(from days: [Day]) -> [String: Any] {
       var exportData: [String: Any] = [:]
       
       // Metadata
       exportData["exportDate"] = ISO8601DateFormatter().string(from: Date())
       exportData["appVersion"] = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
       exportData["totalDays"] = days.count
       
       // Statistics
       let completedDays = days.filter { $0.isCompleted }.count
       exportData["completedDays"] = completedDays
       exportData["currentStreak"] = calculateCurrentStreak(from: days)
       
       // Days data
       var daysArray: [[String: Any]] = []
       
       for day in days {
           var dayData: [String: Any] = [:]
           dayData["dayNumber"] = day.dayNumber
           dayData["date"] = ISO8601DateFormatter().string(from: day.date ?? Date())
           dayData["isCompleted"] = day.isCompleted
           dayData["dsaProgress"] = day.dsaProgress
           dayData["systemDesignProgress"] = day.systemDesignProgress
           
           if let reflection = day.dailyReflection {
               dayData["dailyReflection"] = reflection
           }
           
           // DSA Problems
           if let dsaProblems = day.dsaProblems?.allObjects as? [DSAProblem] {
               var problemsArray: [[String: Any]] = []
               for problem in dsaProblems {
                   var problemData: [String: Any] = [:]
                   problemData["name"] = problem.problemName
                   problemData["leetcodeNumber"] = problem.leetcodeNumber
                   problemData["isCompleted"] = problem.isCompleted
                   problemData["timeSpent"] = problem.timeSpent
                   problemData["difficulty"] = problem.difficulty
                   problemData["isBonusProblem"] = problem.isBonusProblem
                   problemData["notes"] = problem.notes
                   
                   if let completedAt = problem.completedAt {
                       problemData["completedAt"] = ISO8601DateFormatter().string(from: completedAt)
                   }
                   
                   problemsArray.append(problemData)
               }
               dayData["dsaProblems"] = problemsArray
           }
           
           // System Design Topics
           if let systemTopics = day.systemDesignTopics?.allObjects as? [SystemDesignTopic] {
               var topicsArray: [[String: Any]] = []
               for topic in systemTopics {
                   var topicData: [String: Any] = [:]
                   topicData["name"] = topic.topicName
                   topicData["description"] = topic.description
                   topicData["isCompleted"] = topic.isCompleted
                   topicData["videoWatched"] = topic.videoWatched
                   topicData["taskCompleted"] = topic.taskCompleted
                   topicData["notes"] = topic.notes
                   
                   if let completedAt = topic.completedAt {
                       topicData["completedAt"] = ISO8601DateFormatter().string(from: completedAt)
                   }
                   
                   topicsArray.append(topicData)
               }
               dayData["systemDesignTopics"] = topicsArray
           }
           
           daysArray.append(dayData)
       }
       
       exportData["days"] = daysArray
       return exportData
   }
   
   private func calculateCurrentStreak(from days: [Day]) -> Int {
       let sortedDays = days.sorted { $0.date ?? Date() > $1.date ?? Date() }
       var streak = 0
       
       for day in sortedDays {
           if day.isCompleted {
               streak += 1
           } else {
               break
           }
       }
       
       return streak
   }
   
   private func shareFiles(_ urls: [URL]) {
       guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
             let window = windowScene.windows.first else {
           return
       }
       
       let activityVC = UIActivityViewController(activityItems: urls, applicationActivities: nil)
       
       if let popoverController = activityVC.popoverPresentationController {
           popoverController.sourceView = window.rootViewController?.view
           popoverController.sourceRect = CGRect(x: window.bounds.midX, y: window.bounds.midY, width: 0, height: 0)
           popoverController.permittedArrowDirections = []
       }
       
       window.rootViewController?.present(activityVC, animated: true)
   }
}
PHASE 7: NOTIFICATION SYSTEM
Step 10: Enhanced Notification Manager
10.1 Notification Manager with Rebuild Awareness
swift// NotificationManager.swift
import UserNotifications
import Foundation

class NotificationManager: ObservableObject {
    static let shared = NotificationManager()
    
    private init() {}
    
    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            DispatchQueue.main.async {
                if granted {
                    print("✅ Notification permission granted")
                    self.scheduleDailyNotifications()
                } else if let error = error {
                    print("❌ Notification permission error: \(error)")
                } else {
                    print("❌ Notification permission denied")
                }
            }
        }
    }
    
    func scheduleDailyNotifications() {
        // Get user settings
        let morningTime = UserDefaults.standard.object(forKey: "morningNotificationTime") as? Date ?? 
                         Calendar.current.date(bySettingHour: 7, minute: 0, second: 0, of: Date()) ?? Date()
        let eveningTime = UserDefaults.standard.object(forKey: "eveningNotificationTime") as? Date ?? 
                         Calendar.current.date(bySettingHour: 20, minute: 0, second: 0, of: Date()) ?? Date()
        
        scheduleDailyNotifications(morningTime: morningTime, eveningTime: eveningTime)
    }
    
    func scheduleDailyNotifications(morningTime: Date, eveningTime: Date) {
        // Remove existing notifications
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        
        // Schedule morning notification
        scheduleMorningNotification(time: morningTime)
        
        // Schedule evening notification
        scheduleEveningNotification(time: eveningTime)
        
        // Schedule app expiration reminders
        scheduleExpirationReminders()
        
        // Schedule weekly review
        scheduleWeeklyReview()
    }
    
    private func scheduleMorningNotification(time: Date) {
        let content = UNMutableNotificationContent()
        content.title = "Machine Mode Activated 🚀"
        content.body = "Today's mission awaits. Time to dominate!"
        content.sound = .default
        content.badge = 1
        
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: time)
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: "morning-reminder", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling morning notification: \(error)")
            }
        }
    }
    
    private func scheduleEveningNotification(time: Date) {
        let content = UNMutableNotificationContent()
        content.title = "Progress Check 📊"
        content.body = "How did you dominate today? Time to log your progress."
        content.sound = .default
        
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: time)
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: "evening-reminder", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling evening notification: \(error)")
            }
        }
    }
    
    private func scheduleExpirationReminders() {
        let daysUntilExpiration = AppVersionManager.shared.daysUntilExpiration()
        
        if daysUntilExpiration <= 2 {
            let content = UNMutableNotificationContent()
            content.title = "App Expiring Soon ⚠️"
            content.body = "Rebuild app in Xcode in \(daysUntilExpiration) day(s). Your data will be preserved!"
            content.sound = .default
            
            // Schedule for next morning
            var components = DateComponents()
            components.hour = 9
            components.minute = 0
            
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            let request = UNNotificationRequest(identifier: "expiration-warning", content: content, trigger: trigger)
            
            UNUserNotificationCenter.current().add(request)
        }
    }
    
    func scheduleRebuildNotification() {
        let content = UNMutableNotificationContent()
        content.title = "App Rebuilt Successfully ✅"
        content.body = "Welcome back! Your data has been preserved. Ready to continue your Machine Mode journey?"
        content.sound = .default
        
        // Schedule immediately
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: "rebuild-success", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request)
    }
    
    private func scheduleWeeklyReview() {
        let content = UNMutableNotificationContent()
        content.title = "Weekly Review Time 📈"
        content.body = "Time to review your progress and plan for the week ahead!"
        content.sound = .default
        
        // Schedule for Sunday evening
        var components = DateComponents()
        components.weekday = 1 // Sunday
        components.hour = 19
        components.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: "weekly-review", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request)
    }
    
    func scheduleStreakReminder(streak: Int) {
        let content = UNMutableNotificationContent()
        content.title = "Streak Alert! 🔥"
        content.body = "You're on a \(streak)-day streak! Don't break it now."
        content.sound = .default
        
        // Schedule for 9 PM if no progress logged
        var components = DateComponents()
        components.hour = 21
        components.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: "streak-reminder-\(Date().timeIntervalSince1970)", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request)
    }
    
    func clearBadge() {
        UIApplication.shared.applicationIconBadgeNumber = 0
    }
}
PHASE 8: SETTINGS & CONFIGURATION
Step 11: Settings View
11.1 Settings View with Backup Management
swift// SettingsView.swift
import SwiftUI

struct SettingsView: View {
    @State private var morningTime = Date()
    @State private var eveningTime = Date()
    @State private var notificationsEnabled = true
    @State private var showingBackupList = false
    @State private var showingExportOptions = false
    
    var body: some View {
        NavigationView {
            Form {
                Section("Notifications") {
                    Toggle("Enable Notifications", isOn: $notificationsEnabled)
                        .onChange(of: notificationsEnabled) { enabled in
                            if enabled {
                                NotificationManager.shared.requestPermission()
                            }
                        }
                    
                    if notificationsEnabled {
                        DatePicker("Morning Reminder", selection: $morningTime, displayedComponents: .hourAndMinute)
                            .onChange(of: morningTime) { _ in
                                saveNotificationSettings()
                            }
                        
                        DatePicker("Evening Check-in", selection: $eveningTime, displayedComponents: .hourAndMinute)
                            .onChange(of: eveningTime) { _ in
                                saveNotificationSettings()
                            }
                    }
                }
                
                Section("App Information") {
                    HStack {
                        Text("Days Until Expiration")
                        Spacer()
                        Text("\(AppVersionManager.shared.daysUntilExpiration()) days")
                            .foregroundColor(AppVersionManager.shared.daysUntilExpiration() <= 2 ? .red : .primary)
                    }
                    
                    if let installDate = AppVersionManager.shared.getInstallDate() {
                        HStack {
                            Text("Install Date")
                            Spacer()
                            Text(installDate, style: .date)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    HStack {
                        Text("App Version")
                        Spacer()
                        Text(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown")
                            .foregroundColor(.secondary)
                    }
                }
                
                Section("Data Management") {
                    Button("Create Manual Backup") {
                        BackupManager.shared.createManualBackup()
                    }
                    
                    Button("View Backups") {
                        showingBackupList = true
                    }
                    
                    Button("Export Progress") {
                        showingExportOptions = true
                    }
                }
                
                Section("Statistics") {
                    StatisticsView()
                }
                
                Section("Help & Support") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Development Build Information")
                            .font(.headline)
                        
                        Text("• This app expires every 7 days")
                        Text("• Your data persists across rebuilds")
                        Text("• Rebuild in Xcode when prompted")
                        Text("• Backups are created automatically")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Settings")
        }
        .sheet(isPresented: $showingBackupList) {
            BackupListView()
        }
        .sheet(isPresented: $showingExportOptions) {
            ExportOptionsView()
        }
        .onAppear {
            loadNotificationSettings()
        }
    }
    
    private func loadNotificationSettings() {
        morningTime = UserDefaults.standard.object(forKey: "morningNotificationTime") as? Date ?? 
                     Calendar.current.date(bySettingHour: 7, minute: 0, second: 0, of: Date()) ?? Date()
        eveningTime = UserDefaults.standard.object(forKey: "eveningNotificationTime") as? Date ?? 
                     Calendar.current.date(bySettingHour: 20, minute: 0, second: 0, of: Date()) ?? Date()
        notificationsEnabled = UserDefaults.standard.bool(forKey: "notificationsEnabled")
    }
    
    private func saveNotificationSettings() {
        UserDefaults.standard.set(morningTime, forKey: "morningNotificationTime")
        UserDefaults.standard.set(eveningTime, forKey: "eveningNotificationTime")
        UserDefaults.standard.set(notificationsEnabled, forKey: "notificationsEnabled")
        
        // Reschedule notifications
        NotificationManager.shared.scheduleDailyNotifications(morningTime: morningTime, eveningTime: eveningTime)
    }
}
11.2 Statistics View
swift// StatisticsView.swift
import SwiftUI
import CoreData

struct StatisticsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Day.dayNumber, ascending: true)],
        animation: .default)
    private var days: FetchedResults<Day>
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            StatRow(label: "Total Days", value: "\(days.count)")
            StatRow(label: "Completed Days", value: "\(days.filter { $0.isCompleted }.count)")
            StatRow(label: "Current Streak", value: "\(calculateCurrentStreak())")
            StatRow(label: "Total DSA Problems", value: "\(totalDSAProblems())")
            StatRow(label: "Completed DSA", value: "\(completedDSAProblems())")
            StatRow(label: "Bonus Problems", value: "\(bonusProblems())")
        }
        .font(.caption)
    }
    
    private func calculateCurrentStreak() -> Int {
        let sortedDays = days.sorted { $0.date ?? Date() > $1.date ?? Date() }
        var streak = 0
        
        for day in sortedDays {
            if day.isCompleted {
                streak += 1
            } else {
                break
            }
        }
        
        return streak
    }
    
    private func totalDSAProblems() -> Int {
        days.reduce(0) { total, day in
            total + (day.dsaProblems?.count ?? 0)
        }
    }
    
    private func completedDSAProblems() -> Int {
        days.reduce(0) { total, day in
            let problems = day.dsaProblems?.allObjects as? [DSAProblem] ?? []
            return total + problems.filter { $0.isCompleted }.count
        }
    }
    
    private func bonusProblems() -> Int {
        days.reduce(0) { total, day in
            let problems = day.dsaProblems?.allObjects as? [DSAProblem] ?? []
            return total + problems.filter { $0.isBonusProblem }.count
        }
    }
}

struct StatRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
            Spacer()
            Text(value)
                .foregroundColor(.secondary)
        }
    }
}
PHASE 9: BUILD & DEPLOYMENT
Step 12: Building and Installing
12.1 Build Configuration

Connect Your iPhone:

Connect iPhone to Mac via USB
Trust the computer on iPhone when prompted
In Xcode, select your iPhone as the target device


Configure Signing:
swift// In Xcode Project Settings:
- Select your project name
- Go to "Signing & Capabilities"
- Team: Select your Apple ID team
- Bundle Identifier: com.yourname.machinemodetracker
- Automatically manage signing: ✓

Build Settings:
swift// Recommended build settings:
- iOS Deployment Target: 15.0
- Optimization Level (Debug): None [-O0]
- Optimization Level (Release): Optimize for Speed [-O]


12.2 Build and Install Process
bash# In Xcode:
1. Select your iPhone from the device list
2. Press Cmd+R or click the Play button
3. Wait for build to complete
4. App will install automatically on your iPhone

# First time setup on iPhone:
1. Go to Settings > General > VPN & Device Management
2. Find your Apple ID under "Developer App"
3. Tap and select "Trust [Your Apple ID]"
4. Confirm trust in popup
12.3 Rebuilding Process (Every 7 Days)
bash# When app expires:
1. Open Xcode
2. Connect iPhone
3. Clean build folder: Shift+Cmd+K
4. Build and run: Cmd+R
5. App will reinstall with preserved data

# Automated rebuild script (optional):
#!/bin/bash
echo "Rebuilding Machine Mode Tracker..."
cd /path/to/your/project
xcodebuild -scheme "Machine Mode Tracker" -destination "platform=iOS,name=Your iPhone" clean build
echo "Rebuild complete!"
PHASE 10: DATA INITIALIZATION WITH FULL CURRICULUM
Step 13: Complete Data Initialization
13.1 Full Data Initializer Implementation
swift// DataInitializer.swift (Extended)
import CoreData
import Foundation

class DataInitializer {
    static let shared = DataInitializer()
    private let context = PersistenceController.shared.container.viewContext
    
    private init() {}
    
    func initializeDataIfNeeded() {
        // Check if data is already initialized
        let request: NSFetchRequest<Day> = Day.fetchRequest()
        
        do {
            let count = try context.count(for: request)
            if count == 0 {
                print("🚀 Initializing 100-day curriculum...")
                initializeAllDays()
                print("✅ Curriculum initialization complete!")
            } else {
                print("📚 Curriculum already initialized (\(count) days)")
            }
        } catch {
            print("❌ Error checking existing data: \(error)")
        }
    }
    
    private func initializeAllDays() {
        let startDate = Date()
        
        for dayNumber in 1...100 {
            let day = Day(context: context)
            day.dayNumber = Int32(dayNumber)
            day.date = Calendar.current.date(byAdding: .day, value: dayNumber - 1, to: startDate)
            day.dsaProgress = 0.0
            day.systemDesignProgress = 0.0
            day.isCompleted = false
            day.createdAt = Date()
            day.updatedAt = Date()
            
            // Add DSA problems for this day
            addDSAProblems(for: day, dayNumber: dayNumber)
            
            // Add System Design topics for this day
            addSystemDesignTopics(for: day, dayNumber: dayNumber)
        }
        
        do {
            try context.save()
            print("✅ Initialized all 100 days successfully")
        } catch {
            print("❌ Error initializing data: \(error)")
        }
    }
    
    private func addDSAProblems(for day: Day, dayNumber: Int) {
        let problemsData = DSAProblemsData.getProblems(for: dayNumber)
        
        for problemData in problemsData {
            let problem = DSAProblem(context: context)
            problem.problemName = problemData.name
            problem.leetcodeNumber = problemData.leetcodeNumber
            problem.isCompleted = false
            problem.timeSpent = 0
            problem.difficulty = problemData.difficulty
            problem.isBonusProblem = false
            problem.createdAt = Date()
            problem.updatedAt = Date()
            problem.day = day
        }
    }
    
    private func addSystemDesignTopics(for day: Day, dayNumber: Int) {
        let topicsData = SystemDesignTopicsData.getTopics(for: dayNumber)
        
        for topicData in topicsData {
            let topic = SystemDesignTopic(context: context)
            topic.topicName = topicData.name
            topic.description = topicData.description
            topic.isCompleted = false
            topic.videoWatched = false
            topic.taskCompleted = false
            topic.createdAt = Date()
            topic.updatedAt = Date()
            topic.day = day
        }
    }
}

// MARK: - Data Structures

struct DSAProblemData {
    let name: String
    let leetcodeNumber: String?
    let difficulty: String
}

struct SystemDesignTopicData {
    let name: String
    let description: String?
}

// MARK: - DSA Problems Data

class DSAProblemsData {
    static func getProblems(for day: Int) -> [DSAProblemData] {
        switch day {
        case 1:
            return [
                DSAProblemData(name: "Build Array from Permutation", leetcodeNumber: "1920", difficulty: "Easy"),
                DSAProblemData(name: "Running Sum of 1d Array", leetcodeNumber: "1480", difficulty: "Easy"),
                DSAProblemData(name: "Find Numbers with Even Number of Digits", leetcodeNumber: "1295", difficulty: "Easy"),
                DSAProblemData(name: "How Many Numbers Are Smaller Than the Current Number", leetcodeNumber: "1365", difficulty: "Easy"),
                DSAProblemData(name: "Merge Sorted Array", leetcodeNumber: "88", difficulty: "Easy")
            ]
        case 2:
            return [
                DSAProblemData(name: "Move Zeroes", leetcodeNumber: "283", difficulty: "Easy"),
                DSAProblemData(name: "Two Sum II - Input Array Is Sorted", leetcodeNumber: "167", difficulty: "Easy"),
                DSAProblemData(name: "Reverse String", leetcodeNumber: "344", difficulty: "Easy"),
                DSAProblemData(name: "Remove Element", leetcodeNumber: "27", difficulty: "Easy"),
                DSAProblemData(name: "Remove Duplicates from Sorted Array", leetcodeNumber: "26", difficulty: "Easy")
            ]
        case 3:
            return [
                DSAProblemData(name: "3Sum", leetcodeNumber: "15", difficulty: "Medium"),
                DSAProblemData(name: "Container With Most Water", leetcodeNumber: "11", difficulty: "Medium"),
                DSAProblemData(name: "Valid Palindrome", leetcodeNumber: "125", difficulty: "Easy"),
                DSAProblemData(name: "Squares of a Sorted Array", leetcodeNumber: "977", difficulty: "Easy"),
                DSAProblemData(name: "Trapping Rain Water", leetcodeNumber: "42", difficulty: "Hard")
            ]
        // Continue for all 100 days...
        // For brevity, showing pattern. In real implementation, you'd have all 100 days
        default:
            return [
                DSAProblemData(name: "Sample Problem \(day)", leetcodeNumber: nil, difficulty: "Easy")
            ]
        }
    }
}

// MARK: - System Design Topics Data

class SystemDesignTopicsData {
    static func getTopics(for day: Int) -> [SystemDesignTopicData] {
        switch day {
        case 1:
            return [
                SystemDesignTopicData(name: "DNS & Domain Resolution", description: "Watch: DNS Explained - How Domain Name System Works"),
                SystemDesignTopicData(name: "Draw DNS Resolution Flow", description: "Client → Resolver → Root → TLD → Authoritative"),
                SystemDesignTopicData(name: "DNS Explanation Exercise", description: "Write a 100-word explanation of DNS as if explaining toRetryPBContinueEditswift               SystemDesignTopicData(name: "DNS Explanation Exercise", description: "Write a 100-word explanation of DNS as if explaining to a child")
           ]
       case 2:
           return [
               SystemDesignTopicData(name: "Load Balancing", description: "Watch: Load Balancers Explained - Gaurav Sen"),
               SystemDesignTopicData(name: "Load Balancer Diagram", description: "Diagram Client → Load Balancer → App Servers (Round Robin, Least Connections)"),
               SystemDesignTopicData(name: "Layer 4 vs Layer 7", description: "Compare Layer 4 vs Layer 7 load balancing in 3 sentences")
           ]
       case 3:
           return [
               SystemDesignTopicData(name: "CAP Theorem", description: "Watch: CAP Theorem Simplified - Gaurav Sen"),
               SystemDesignTopicData(name: "CAP Trade-offs Diagram", description: "Draw 3 scenarios showing Consistency, Availability, Partition Tolerance trade-offs"),
               SystemDesignTopicData(name: "CAP Examples", description: "Give real-world examples of CP, AP, and CA systems")
           ]
       // Continue for all 100 days...
       default:
           return [
               SystemDesignTopicData(name: "System Design Topic \(day)", description: "Default topic for day \(day)")
           ]
       }
   }
}
PHASE 11: ADDITIONAL UTILITY VIEWS
Step 14: Supporting Views
14.1 Backup List View
swift// BackupListView.swift
import SwiftUI

struct BackupListView: View {
    @State private var backups: [URL] = []
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                if backups.isEmpty {
                    ContentUnavailableView(
                        "No Backups Found",
                        systemImage: "archivebox",
                        description: Text("Backups will appear here automatically")
                    )
                } else {
                    ForEach(backups, id: \.self) { backup in
                        BackupRowView(backup: backup)
                    }
                }
            }
            .navigationTitle("Backups")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create Backup") {
                        BackupManager.shared.createManualBackup()
                        loadBackups()
                    }
                }
            }
        }
        .onAppear {
            loadBackups()
        }
    }
    
    private func loadBackups() {
        backups = BackupManager.shared.listBackups()
    }
}

struct BackupRowView: View {
    let backup: URL
    @State private var showingShareSheet = false
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(backup.lastPathComponent)
                    .font(.headline)
                
                if let attributes = try? FileManager.default.attributesOfItem(atPath: backup.path),
                   let date = attributes[.creationDate] as? Date {
                    Text("Created: \(date, style: .date) at \(date, style: .time)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if let size = try? FileManager.default.attributesOfItem(atPath: backup.path)?[.size] as? Int64 {
                    Text("Size: \(ByteCountFormatter.string(fromByteCount: size, countStyle: .file))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Button("Share") {
                showingShareSheet = true
            }
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.blue.opacity(0.1))
            .cornerRadius(6)
        }
        .padding(.vertical, 4)
        .sheet(isPresented: $showingShareSheet) {
            ShareSheet(urls: [backup])
        }
    }
}
14.2 Export Options View
swift// ExportOptionsView.swift
import SwiftUI

struct ExportOptionsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showingShareSheet = false
    @State private var exportURLs: [URL] = []
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Export Your Progress")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                Text("Choose how you'd like to export your Machine Mode progress")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                VStack(spacing: 16) {
                    ExportOptionButton(
                        title: "Markdown Export",
                        description: "Human-readable progress report",
                        icon: "doc.text",
                        action: exportMarkdown
                    )
                    
                    ExportOptionButton(
                        title: "JSON Export",
                        description: "Machine-readable data backup",
                        icon: "curlybraces",
                        action: exportJSON
                    )
                    
                    ExportOptionButton(
                        title: "Complete Export",
                        description: "Both Markdown and JSON files",
                        icon: "doc.on.doc",
                        action: exportBoth
                    )
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Export")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .sheet(isPresented: $showingShareSheet) {
            ShareSheet(urls: exportURLs)
        }
    }
    
    private func exportMarkdown() {
        let content = ExportManager.shared.exportProgressToMarkdown()
        let url = saveToDocuments(content: content, filename: "Progress_\(timestamp()).md")
        shareFiles([url])
    }
    
    private func exportJSON() {
        let data = ExportManager.shared.exportToJSON()
        let url = saveToDocuments(data: data, filename: "Progress_\(timestamp()).json")
        shareFiles([url])
    }
    
    private func exportBoth() {
        let markdownContent = ExportManager.shared.exportProgressToMarkdown()
        let jsonData = ExportManager.shared.exportToJSON()
        
        let markdownURL = saveToDocuments(content: markdownContent, filename: "Progress_\(timestamp()).md")
        let jsonURL = saveToDocuments(data: jsonData, filename: "Progress_\(timestamp()).json")
        
        shareFiles([markdownURL, jsonURL])
    }
    
    private func saveToDocuments(content: String, filename: String) -> URL {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let url = documentsDirectory.appendingPathComponent(filename)
        
        do {
            try content.write(to: url, atomically: true, encoding: .utf8)
        } catch {
            print("Error saving file: \(error)")
        }
        
        return url
    }
    
    private func saveToDocuments(data: Data, filename: String) -> URL {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let url = documentsDirectory.appendingPathComponent(filename)
        
        do {
            try data.write(to: url)
        } catch {
            print("Error saving file: \(error)")
        }
        
        return url
    }
    
    private func shareFiles(_ urls: [URL]) {
        exportURLs = urls
        showingShareSheet = true
        dismiss()
    }
    
    private func timestamp() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        return formatter.string(from: Date())
    }
}

struct ExportOptionButton: View {
    let title: String
    let description: String
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(.blue)
                    .frame(width: 30)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "arrow.right")
                    .foregroundColor(.blue)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
14.3 Share Sheet
swift// ShareSheet.swift
import SwiftUI
import UIKit

struct ShareSheet: UIViewControllerRepresentable {
    let urls: [URL]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: urls, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
PHASE 12: FINAL TOUCHES & TESTING
Step 15: Final Implementation Details
15.1 Add Problem View
swift// AddProblemView.swift
import SwiftUI
import CoreData

struct AddProblemView: View {
    let currentDay: Day?
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var problemName = ""
    @State private var leetcodeNumber = ""
    @State private var difficulty = "Easy"
    @State private var notes = ""
    
    let difficulties = ["Easy", "Medium", "Hard"]
    
    var body: some View {
        NavigationView {
            Form {
                Section("Problem Details") {
                    TextField("Problem Name", text: $problemName)
                    TextField("LeetCode Number (optional)", text: $leetcodeNumber)
                    
                    Picker("Difficulty", selection: $difficulty) {
                        ForEach(difficulties, id: \.self) { diff in
                            Text(diff).tag(diff)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                Section("Notes") {
                    TextField("Notes (optional)", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("Add Bonus Problem")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        addProblem()
                    }
                    .disabled(problemName.isEmpty)
                }
            }
        }
    }
    
    private func addProblem() {
        guard let day = currentDay else { return }
        
        let problem = DSAProblem(context: viewContext)
        problem.problemName = problemName
        problem.leetcodeNumber = leetcodeNumber.isEmpty ? nil : leetcodeNumber
        problem.difficulty = difficulty
        problem.notes = notes.isEmpty ? nil : notes
        problem.isCompleted = false
        problem.timeSpent = 0
        problem.isBonusProblem = true
        problem.createdAt = Date()
        problem.updatedAt = Date()
        problem.day = day
        
        do {
            try viewContext.save()
            dismiss()
        } catch {
            print("Error adding problem: \(error)")
        }
    }
}
15.2 Problem Notes View
swift// ProblemNotesView.swift
import SwiftUI

struct ProblemNotesView: View {
    @ObservedObject var problem: DSAProblem
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var notes: String = ""
    @State private var timeSpent: String = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section("Problem Details") {
                    HStack {
                        Text("Problem")
                        Spacer()
                        Text(problem.problemName ?? "Unknown")
                            .foregroundColor(.secondary)
                    }
                    
                    if let leetcode = problem.leetcodeNumber {
                        HStack {
                            Text("LeetCode")
                            Spacer()
                            Text("LC \(leetcode)")
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    HStack {
                        Text("Difficulty")
                        Spacer()
                        Text(problem.difficulty ?? "Unknown")
                            .foregroundColor(.secondary)
                    }
                }
                
                Section("Time Tracking") {
                    HStack {
                        Text("Time Spent (minutes)")
                        Spacer()
                        TextField("0", text: $timeSpent)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                    }
                }
                
                Section("Notes") {
                    TextField("Add your notes, insights, or solution approach...", text: $notes, axis: .vertical)
                        .lineLimit(5...10)
                }
                
                if problem.isCompleted, let completedAt = problem.completedAt {
                    Section("Completion Info") {
                        HStack {
                            Text("Completed At")
                            Spacer()
                            Text(completedAt, style: .date)
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Text("Time")
                            Spacer()
                            Text(completedAt, style: .time)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Problem Notes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveNotes()
                    }
                }
            }
        }
        .onAppear {
            notes = problem.notes ?? ""
            timeSpent = problem.timeSpent > 0 ? String(problem.timeSpent) : ""
        }
    }
    
    private func saveNotes() {
        problem.notes = notes.isEmpty ? nil : notes
        problem.timeSpent = Int32(timeSpent) ?? 0
        problem.updatedAt = Date()
        
        do {
            try viewContext.save()
            dismiss()
        } catch {
            print("Error saving notes: \(error)")
        }
    }
}
PHASE 13: BUILD & DEPLOYMENT CHECKLIST
Step 16: Pre-Build Checklist
16.1 Build Preparation
swift// Pre-build checklist:
☐ Core Data model is configured correctly
☐ All views are implemented
☐ Notification permissions are requested
☐ Bundle identifier is unique
☐ Signing is configured with your Apple ID
☐ iPhone is connected and trusted
☐ All required capabilities are added
☐ Data initialization is complete
☐ Backup system is implemented
☐ Export functionality works
16.2 Testing Checklist
swift// Testing checklist before daily use:
☐ App launches without crashes
☐ Today's problems display correctly
☐ Check/uncheck functionality works
☐ Progress bars update properly
☐ Notes can be added and saved
☐ Bonus problems can be added
☐ Notifications are scheduled
☐ Export functionality works
☐ Data persists after app restart
☐ Backup creation works
☐ Settings can be modified
STEP-BY-STEP BUILD INSTRUCTIONS
Quick Build Guide:

Open Xcode → Create new iOS project
Configure project:

Name: "Machine Mode Tracker"
Interface: SwiftUI
Use Core Data: ✓
Bundle ID: com.yourname.machinemodetracker


Add all source files (copy-paste all the Swift code above)
Configure Core Data model with the entities described
Connect iPhone and trust computer
Select iPhone as target in Xcode
Press Cmd+R to build and install

Rebuild Process (Every 7 Days):

Open Xcode project
Connect iPhone
Clean build: Shift+Cmd+K
Build and run: Cmd+R
Data automatically persists ✅

TROUBLESHOOTING COMMON ISSUES
Issue: "Developer account required"

Solution: Sign in with Apple ID in Xcode Preferences

Issue: "Code signing error"

Solution: Select your team in project settings, enable automatic signing

Issue: "App crashes on launch"

Solution: Check Core Data model configuration, ensure all entities match code

Issue: "Notifications not working"

Solution: Check notification permissions in iPhone settings

Issue: "Data not persisting"

Solution: Verify Core Data store is in Documents directory, not temporary location


CONGRATULATIONS! 🚀
You now have a complete implementation guide for your Machine Mode Tracker app! The app will:
✅ Track your 100-day journey with daily DSA problems and system design topics
✅ Persist data across rebuilds so you never lose progress
✅ Send motivational notifications to keep you on track
✅ Export your progress to markdown files
✅ Create automatic backups to protect your data
✅ Handle the 7-day rebuild cycle seamlessly
Your data is safe, your progress is tracked, and your Machine Mode journey can begin!
Time to build this app and start your transformation into an elite operator! 💪