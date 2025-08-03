import SwiftUI
import CoreData

struct DSAProblemRowView: View {
    @ObservedObject var problem: DSAProblem
    let onToggle: () -> Void
    
    @EnvironmentObject private var accessibilityManager: AccessibilityManager
    @EnvironmentObject private var errorHandler: ErrorHandler
    @Environment(\.managedObjectContext) private var viewContext
    
    @State private var showingNotes = false
    @State private var showingTimeTracker = false
    
    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 12) {
                // ACCESSIBILITY INTEGRATED CHECKBOX
                AccessibleCheckbox(
                    isChecked: .constant(problem.isCompleted),
                    problemName: problem.problemName ?? "Unknown Problem",
                    difficulty: problem.difficulty ?? "Unknown",
                    timeSpent: problem.timeSpent,
                    hasNotes: !(problem.notes?.isEmpty ?? true)
                ) {
                    onToggle()
                }
                
                // Problem details
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(problem.problemName ?? "Unknown Problem")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .strikethrough(problem.isCompleted)
                            .foregroundColor(problem.isCompleted ? .secondary : .primary)
                            .accessibilityAddTraits(.isHeader)
                        
                        Spacer()
                        
                        if let leetcodeNumber = problem.leetcodeNumber {
                            Text("LC \(leetcodeNumber)")
                                .font(.caption)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.blue.opacity(0.1))
                                .foregroundColor(.blue)
                                .cornerRadius(4)
                                .accessibilityLabel("LeetCode number \(leetcodeNumber)")
                        }
                    }
                    
                    HStack {
                        // Difficulty badge
                        Text(problem.difficulty ?? "Unknown")
                            .font(.caption)
                            .fontWeight(.medium)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(difficultyColor.opacity(0.1))
                            .foregroundColor(difficultyColor)
                            .cornerRadius(4)
                            .accessibilityLabel("Difficulty: \(problem.difficulty ?? "Unknown")")
                        
                        if problem.isBonusProblem {
                            Text("BONUS")
                                .font(.caption)
                                .fontWeight(.bold)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.green.opacity(0.1))
                                .foregroundColor(.green)
                                .cornerRadius(4)
                                .accessibilityLabel("Bonus problem")
                        }
                        
                        Spacer()
                        
                        // Time spent
                        if problem.timeSpent > 0 {
                            HStack(spacing: 4) {
                                Image(systemName: "clock")
                                    .font(.caption)
                                    .accessibilityHidden(true)
                                Text(problem.formattedTimeSpent)
                                    .font(.caption)
                            }
                            .foregroundColor(.secondary)
                            .accessibilityElement(children: .combine)
                            .accessibilityLabel("Time spent: \(formatTimeAccessible(problem.timeSpent))")
                        }
                    }
                }
                
                // Action buttons
                HStack(spacing: 8) {
                    if problem.hasNotes {
                        AccessibleButton("Notes", icon: "note.text", accessibilityHint: "View problem notes") {
                            showingNotes = true
                        }
                        .font(.caption)
                        .foregroundColor(.blue)
                    }
                    
                    AccessibleButton("Timer", icon: "timer", accessibilityHint: "Track time for this problem") {
                        showingTimeTracker = true
                    }
                    .font(.caption)
                    .foregroundColor(.orange)
                }
            }
            
            // Completion timestamp
            if let completedAt = problem.completedAt {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundColor(.green)
                        .accessibilityHidden(true)
                    
                    Text("Completed \(completedAt, style: .relative) ago")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Completed \(completedAt, style: .relative) ago")
            }
        }
        .padding(.vertical, 4)
        .sheet(isPresented: $showingNotes) {
            ProblemNotesView(problem: problem)
        }
        .sheet(isPresented: $showingTimeTracker) {
            TimeTrackerView(problem: problem)
        }
        .accessibilityElement(children: .contain)
    }
    
    private var difficultyColor: Color {
        switch problem.difficulty {
        case "Easy":
            return .green
        case "Medium":
            return .orange
        case "Hard":
            return .red
        default:
            return .gray
        }
    }
    
    private func formatTimeAccessible(_ minutes: Int32) -> String {
        if minutes == 0 {
            return "0 minutes"
        } else if minutes < 60 {
            return minutes == 1 ? "1 minute" : "\(minutes) minutes"
        } else {
            let hours = minutes / 60
            let remainingMinutes = minutes % 60
            let hourText = hours == 1 ? "1 hour" : "\(hours) hours"
            if remainingMinutes > 0 {
                let minText = remainingMinutes == 1 ? "1 minute" : "\(remainingMinutes) minutes"
                return "\(hourText) and \(minText)"
            } else {
                return hourText
            }
        }
    }
}

// MARK: - Problem Notes View
struct ProblemNotesView: View {
    @ObservedObject var problem: DSAProblem
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var errorHandler: ErrorHandler
    @EnvironmentObject private var accessibilityManager: AccessibilityManager
    
    @State private var notesText: String = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(problem.problemName ?? "Unknown Problem")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .accessibilityAddTraits(.isHeader)
                    
                    if let leetcodeNumber = problem.leetcodeNumber {
                        Text("LeetCode #\(leetcodeNumber)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Solution Notes")
                        .font(.headline)
                        .accessibilityAddTraits(.isHeader)
                    
                    TextEditor(text: $notesText)
                        .padding(8)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        .frame(minHeight: 200)
                        .accessibilityLabel("Problem notes text editor")
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Problem Notes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    AccessibleButton("Cancel", accessibilityHint: "Cancel editing notes") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    AccessibleButton("Save", accessibilityHint: "Save problem notes") {
                        saveNotes()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .onAppear {
            notesText = problem.notes ?? ""
        }
        .accessibilityElement(children: .contain)
    }
    
    private func saveNotes() {
        do {
            problem.updateNotes(notesText.isEmpty ? nil : notesText)
            try viewContext.save()
            
            accessibilityManager.announceForVoiceOver("Notes saved")
            dismiss()
            
        } catch {
            errorHandler.handle(error: .coreDataError(error), source: "ProblemNotesView.saveNotes")
        }
    }
}

// MARK: - Time Tracker View
struct TimeTrackerView: View {
    @ObservedObject var problem: DSAProblem
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject private var errorHandler: ErrorHandler
    @EnvironmentObject private var accessibilityManager: AccessibilityManager
    
    @State private var hours: Int = 0
    @State private var minutes: Int = 0
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(problem.problemName ?? "Unknown Problem")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .accessibilityAddTraits(.isHeader)
                    
                    Text("Current time: \(problem.formattedTimeSpent)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .accessibilityLabel("Current time spent: \(formatTimeAccessible(problem.timeSpent))")
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                VStack(spacing: 20) {
                    Text("Set Time Spent")
                        .font(.headline)
                        .accessibilityAddTraits(.isHeader)
                    
                    HStack(spacing: 20) {
                        VStack {
                            Text("Hours")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Picker("Hours", selection: $hours) {
                                ForEach(0..<24) { hour in
                                    Text("\(hour)").tag(hour)
                                }
                            }
                            .pickerStyle(WheelPickerStyle())
                            .frame(width: 80, height: 120)
                            .accessibilityLabel("Hours picker")
                        }
                        
                        VStack {
                            Text("Minutes")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Picker("Minutes", selection: $minutes) {
                                ForEach(0..<60) { minute in
                                    Text("\(minute)").tag(minute)
                                }
                            }
                            .pickerStyle(WheelPickerStyle())
                            .frame(width: 80, height: 120)
                            .accessibilityLabel("Minutes picker")
                        }
                    }
                    
                    // Quick time buttons
                    VStack(spacing: 12) {
                        Text("Quick Add")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        HStack(spacing: 12) {
                            ForEach([15, 30, 45, 60], id: \.self) { mins in
                                AccessibleButton("+\(mins)m", accessibilityHint: "Add \(mins) minutes to current time") {
                                    addMinutes(mins)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.blue.opacity(0.1))
                                .foregroundColor(.blue)
                                .cornerRadius(8)
                            }
                        }
                    }
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Time Tracker")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    AccessibleButton("Cancel", accessibilityHint: "Cancel time tracking") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    AccessibleButton("Save", accessibilityHint: "Save time spent") {
                        saveTime()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .onAppear {
            let totalMinutes = Int(problem.timeSpent)
            hours = totalMinutes / 60
            minutes = totalMinutes % 60
        }
        .accessibilityElement(children: .contain)
    }
    
    private func addMinutes(_ mins: Int) {
        let totalMinutes = hours * 60 + minutes + mins
        hours = totalMinutes / 60
        minutes = totalMinutes % 60
        
        accessibilityManager.announceForVoiceOver("Added \(mins) minutes")
    }
    
    private func saveTime() {
        do {
            let totalMinutes = Int32(hours * 60 + minutes)
            problem.setTime(minutes: totalMinutes)
            try viewContext.save()
            
            accessibilityManager.announceForVoiceOver("Time saved")
            dismiss()
            
        } catch {
            errorHandler.handle(error: .coreDataError(error), source: "TimeTrackerView.saveTime")
        }
    }
    
    private func formatTimeAccessible(_ minutes: Int32) -> String {
        if minutes == 0 {
            return "0 minutes"
        } else if minutes < 60 {
            return minutes == 1 ? "1 minute" : "\(minutes) minutes"
        } else {
            let hours = minutes / 60
            let remainingMinutes = minutes % 60
            let hourText = hours == 1 ? "1 hour" : "\(hours) hours"
            if remainingMinutes > 0 {
                let minText = remainingMinutes == 1 ? "1 minute" : "\(remainingMinutes) minutes"
                return "\(hourText) and \(minText)"
            } else {
                return hourText
            }
        }
    }
}

// MARK: - Extensions
extension DSAProblem {
    var formattedTimeSpent: String {
        if timeSpent == 0 {
            return "0m"
        } else if timeSpent < 60 {
            return "\(timeSpent)m"
        } else {
            let hours = timeSpent / 60
            let remainingMinutes = timeSpent % 60
            return remainingMinutes > 0 ? "\(hours)h \(remainingMinutes)m" : "\(hours)h"
        }
    }
    
    var hasNotes: Bool {
        return !(notes?.isEmpty ?? true)
    }
    
    func updateNotes(_ newNotes: String?) {
        notes = newNotes
        updatedAt = Date()
    }
    
    func setTime(minutes: Int32) {
        timeSpent = minutes
        updatedAt = Date()
    }
}