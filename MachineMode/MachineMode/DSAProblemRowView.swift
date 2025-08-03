import SwiftUI
import CoreData

struct DSAProblemRowView: View {
    let problem: DSAProblem
    let onToggle: () -> Void
    
    @State private var showingNotes = false
    @State private var showingTimeTracker = false
    
    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 12) {
                // Completion checkbox
                Button(action: onToggle) {
                    Image(systemName: problem.isCompleted ? "checkmark.circle.fill" : "circle")
                        .font(.title2)
                        .foregroundColor(problem.isCompleted ? .green : .gray)
                }
                .buttonStyle(PlainButtonStyle())
                
                // Problem details
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(problem.problemName ?? "Unknown Problem")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .strikethrough(problem.isCompleted)
                            .foregroundColor(problem.isCompleted ? .secondary : .primary)
                        
                        Spacer()
                        
                        if let leetcodeNumber = problem.leetcodeNumber {
                            Text("LC \(leetcodeNumber)")
                                .font(.caption)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.blue.opacity(0.1))
                                .foregroundColor(.blue)
                                .cornerRadius(4)
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
                        
                        if problem.isBonusProblem {
                            Text("BONUS")
                                .font(.caption)
                                .fontWeight(.bold)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.green.opacity(0.1))
                                .foregroundColor(.green)
                                .cornerRadius(4)
                        }
                        
                        Spacer()
                        
                        // Time spent
                        if problem.timeSpent > 0 {
                            HStack(spacing: 4) {
                                Image(systemName: "clock")
                                    .font(.caption)
                                Text(problem.formattedTimeSpent)
                                    .font(.caption)
                            }
                            .foregroundColor(.secondary)
                        }
                    }
                }
                
                // Action buttons
                HStack(spacing: 8) {
                    if problem.hasNotes {
                        Button(action: { showingNotes = true }) {
                            Image(systemName: "note.text")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    
                    Button(action: { showingTimeTracker = true }) {
                        Image(systemName: "timer")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            
            // Completion timestamp
            if let completedAt = problem.completedAt {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundColor(.green)
                    
                    Text("Completed \(completedAt, style: .relative) ago")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                }
            }
        }
        .padding(.vertical, 4)
        .sheet(isPresented: $showingNotes) {
            ProblemNotesView(problem: problem)
        }
        .sheet(isPresented: $showingTimeTracker) {
            TimeTrackerView(problem: problem)
        }
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
}

// MARK: - Problem Notes View

struct ProblemNotesView: View {
    let problem: DSAProblem
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    
    @State private var notesText: String = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(problem.problemName ?? "Unknown Problem")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
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
                    
                    TextEditor(text: $notesText)
                        .padding(8)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        .frame(minHeight: 200)
                }
                
                Spacer()
            }
            .padding()
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
                    .fontWeight(.semibold)
                }
            }
        }
        .onAppear {
            notesText = problem.notes ?? ""
        }
    }
    
    private func saveNotes() {
        problem.updateNotes(notesText.isEmpty ? nil : notesText)
        
        do {
            try viewContext.save()
            dismiss()
        } catch {
            print("Error saving notes: \(error)")
        }
    }
}

// MARK: - Time Tracker View

struct TimeTrackerView: View {
    let problem: DSAProblem
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    
    @State private var hours: Int = 0
    @State private var minutes: Int = 0
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(problem.problemName ?? "Unknown Problem")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text("Current time: \(problem.formattedTimeSpent)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                VStack(spacing: 20) {
                    Text("Set Time Spent")
                        .font(.headline)
                    
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
                        }
                    }
                    
                    // Quick time buttons
                    VStack(spacing: 12) {
                        Text("Quick Add")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        HStack(spacing: 12) {
                            ForEach([15, 30, 45, 60], id: \.self) { mins in
                                Button("+\(mins)m") {
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
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
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
    }
    
    private func addMinutes(_ mins: Int) {
        let totalMinutes = hours * 60 + minutes + mins
        hours = totalMinutes / 60
        minutes = totalMinutes % 60
    }
    
    private func saveTime() {
        let totalMinutes = Int32(hours * 60 + minutes)
        problem.setTime(minutes: totalMinutes)
        
        do {
            try viewContext.save()
            dismiss()
        } catch {
            print("Error saving time: \(error)")
        }
    }
}

// MARK: - Preview

struct DSAProblemRowView_Previews: PreviewProvider {
    static var previews: some View {
        let context = PersistenceController.preview.container.viewContext
        let problem = DSAProblem(context: context)
        problem.problemName = "Two Sum"
        problem.leetcodeNumber = "1"
        problem.difficulty = "Easy"
        problem.isCompleted = false
        problem.timeSpent = 45
        
        return DSAProblemRowView(problem: problem) {
            problem.isCompleted.toggle()
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}