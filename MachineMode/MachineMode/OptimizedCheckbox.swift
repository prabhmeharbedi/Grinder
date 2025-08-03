import SwiftUI

// MARK: - Optimized Checkbox with Immediate Feedback
struct OptimizedCheckbox: View {
    @Binding var isChecked: Bool
    let onToggle: () -> Void
    
    @State private var isPressed = false
    @State private var scale: CGFloat = 1.0
    
    var body: some View {
        Button(action: {
            // Immediate visual feedback
            withAnimation(.easeInOut(duration: 0.1)) {
                scale = 0.9
            }
            
            // Haptic feedback
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
            
            // Toggle state immediately for responsive UI
            isChecked.toggle()
            
            // Scale back with completion animation
            withAnimation(.easeInOut(duration: 0.2).delay(0.1)) {
                scale = 1.0
            }
            
            // Call the actual toggle action
            onToggle()
        }) {
            ZStack {
                // Background circle
                Circle()
                    .fill(isChecked ? Color.adaptiveGreen : Color.clear)
                    .overlay(
                        Circle()
                            .stroke(isChecked ? Color.adaptiveGreen : Color.secondary, lineWidth: 2)
                    )
                    .frame(width: 24, height: 24)
                
                // Checkmark
                if isChecked {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .scaleEffect(scale)
            .animation(.easeInOut(duration: 0.15), value: isChecked)
            .animation(.easeInOut(duration: 0.1), value: scale)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
                scale = pressing ? 0.95 : 1.0
            }
        }, perform: {})
    }
}

// MARK: - Optimized Problem Row with Auto-save
struct OptimizedDSAProblemRowView: View {
    @ObservedObject var problem: DSAProblem
    @Environment(\.managedObjectContext) private var viewContext
    
    @State private var showingNotes = false
    @State private var showingTimeTracker = false
    @State private var notesText = ""
    @State private var autoSaveTimer: Timer?
    
    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 12) {
                // Optimized completion checkbox
                OptimizedCheckbox(isChecked: .constant(problem.isCompleted)) {
                    toggleCompletion()
                }
                
                // Problem details
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(problem.problemName ?? "Unknown Problem")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .strikethrough(problem.isCompleted)
                            .foregroundColor(problem.isCompleted ? .secondary : .primary)
                            .animation(.easeInOut(duration: 0.2), value: problem.isCompleted)
                        
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
                        
                        // Time spent with smooth updates
                        if problem.timeSpent > 0 {
                            HStack(spacing: 4) {
                                Image(systemName: "clock")
                                    .font(.caption)
                                Text(problem.formattedTimeSpent)
                                    .font(.caption)
                                    .animation(.easeInOut(duration: 0.3), value: problem.timeSpent)
                            }
                            .foregroundColor(.secondary)
                        }
                    }
                }
                
                // Action buttons with improved feedback
                HStack(spacing: 8) {
                    if problem.hasNotes {
                        OptimizedActionButton(
                            icon: "note.text",
                            color: .blue,
                            action: { showingNotes = true }
                        )
                    }
                    
                    OptimizedActionButton(
                        icon: "timer",
                        color: .orange,
                        action: { showingTimeTracker = true }
                    )
                }
            }
            
            // Completion timestamp with smooth transition
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
                .transition(.move(edge: .top).combined(with: .opacity))
                .animation(.easeInOut(duration: 0.3), value: problem.completedAt)
            }
        }
        .padding(.vertical, 4)
        .sheet(isPresented: $showingNotes) {
            OptimizedNotesView(problem: problem, notesText: $notesText)
        }
        .sheet(isPresented: $showingTimeTracker) {
            OptimizedTimeTrackerView(problem: problem)
        }
        .onAppear {
            notesText = problem.notes ?? ""
        }
    }
    
    private var difficultyColor: Color {
        switch problem.difficulty {
        case "Easy":
            return .adaptiveGreen
        case "Medium":
            return .adaptiveOrange
        case "Hard":
            return .adaptiveRed
        default:
            return .secondary
        }
    }
    
    private func toggleCompletion() {
        // Immediate UI update with animation
        withAnimation(.easeInOut(duration: 0.3)) {
            problem.isCompleted.toggle()
            
            if problem.isCompleted {
                problem.completedAt = Date()
            } else {
                problem.completedAt = nil
            }
            
            problem.updatedAt = Date()
        }
        
        // Auto-save with debouncing
        autoSaveChanges()
    }
    
    private func autoSaveChanges() {
        // Cancel previous timer
        autoSaveTimer?.invalidate()
        
        // Set new timer for auto-save
        autoSaveTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { _ in
            do {
                try viewContext.save()
                
                // Update streaks and check for milestones
                NotificationManager.shared.updateStreakAndCheckMilestones()
            } catch {
                print("❌ Auto-save failed: \(error)")
                
                // Revert changes on save failure
                viewContext.rollback()
            }
        }
    }
}

// MARK: - Optimized Action Button
struct OptimizedActionButton: View {
    let icon: String
    let color: Color
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            // Haptic feedback
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
            
            action()
        }) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(color)
                .scaleEffect(isPressed ? 0.9 : 1.0)
                .animation(.easeInOut(duration: 0.1), value: isPressed)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
            }
        }, perform: {})
    }
}

// MARK: - Optimized Notes View with Auto-save
struct OptimizedNotesView: View {
    @ObservedObject var problem: DSAProblem
    @Binding var notesText: String
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    
    @State private var autoSaveTimer: Timer?
    @State private var hasUnsavedChanges = false
    
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
                    HStack {
                        Text("Solution Notes")
                            .font(.headline)
                        
                        Spacer()
                        
                        if hasUnsavedChanges {
                            HStack(spacing: 4) {
                                Image(systemName: "circle.fill")
                                    .font(.system(size: 6))
                                    .foregroundColor(.orange)
                                Text("Auto-saving...")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    
                    TextEditor(text: $notesText)
                        .padding(8)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        .frame(minHeight: 200)
                        .onChange(of: notesText) { _ in
                            hasUnsavedChanges = true
                            scheduleAutoSave()
                        }
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Problem Notes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        saveAndDismiss()
                    }
                }
            }
        }
        .onDisappear {
            // Ensure final save when view disappears
            saveNotes()
        }
    }
    
    private func scheduleAutoSave() {
        // Cancel previous timer
        autoSaveTimer?.invalidate()
        
        // Set new timer for auto-save
        autoSaveTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false) { _ in
            saveNotes()
        }
    }
    
    private func saveNotes() {
        problem.updateNotes(notesText.isEmpty ? nil : notesText)
        
        do {
            try viewContext.save()
            hasUnsavedChanges = false
        } catch {
            print("❌ Error saving notes: \(error)")
        }
    }
    
    private func saveAndDismiss() {
        saveNotes()
        dismiss()
    }
}

// MARK: - Optimized Time Tracker with Auto-save
struct OptimizedTimeTrackerView: View {
    @ObservedObject var problem: DSAProblem
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    
    @State private var hours: Int = 0
    @State private var minutes: Int = 0
    @State private var autoSaveTimer: Timer?
    
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
                        .animation(.easeInOut(duration: 0.3), value: problem.timeSpent)
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
                            .onChange(of: hours) { _ in
                                scheduleAutoSave()
                            }
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
                            .onChange(of: minutes) { _ in
                                scheduleAutoSave()
                            }
                        }
                    }
                    
                    // Quick time buttons with improved feedback
                    VStack(spacing: 12) {
                        Text("Quick Add")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        HStack(spacing: 12) {
                            ForEach([15, 30, 45, 60], id: \.self) { mins in
                                OptimizedQuickTimeButton(minutes: mins) {
                                    addMinutes(mins)
                                }
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
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        saveAndDismiss()
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
        .onDisappear {
            // Ensure final save when view disappears
            saveTime()
        }
    }
    
    private func addMinutes(_ mins: Int) {
        let totalMinutes = hours * 60 + minutes + mins
        hours = totalMinutes / 60
        minutes = totalMinutes % 60
        
        scheduleAutoSave()
    }
    
    private func scheduleAutoSave() {
        // Cancel previous timer
        autoSaveTimer?.invalidate()
        
        // Set new timer for auto-save
        autoSaveTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { _ in
            saveTime()
        }
    }
    
    private func saveTime() {
        let totalMinutes = Int32(hours * 60 + minutes)
        problem.setTime(minutes: totalMinutes)
        
        do {
            try viewContext.save()
        } catch {
            print("❌ Error saving time: \(error)")
        }
    }
    
    private func saveAndDismiss() {
        saveTime()
        dismiss()
    }
}

// MARK: - Optimized Quick Time Button
struct OptimizedQuickTimeButton: View {
    let minutes: Int
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button("+\(minutes)m") {
            // Haptic feedback
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
            
            action()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.blue.opacity(isPressed ? 0.2 : 0.1))
        .foregroundColor(.blue)
        .cornerRadius(8)
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
            }
        }, perform: {})
    }
}

// MARK: - Optimized System Design Topic Row
struct OptimizedSystemDesignTopicRowView: View {
    @ObservedObject var topic: SystemDesignTopic
    @Environment(\.managedObjectContext) private var viewContext
    
    @State private var showingNotes = false
    @State private var autoSaveTimer: Timer?
    
    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 12) {
                // Completion checkbox
                OptimizedCheckbox(isChecked: .constant(topic.isCompleted)) {
                    toggleCompletion()
                }
                
                // Topic details
                VStack(alignment: .leading, spacing: 4) {
                    Text(topic.topicName ?? "Unknown Topic")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .strikethrough(topic.isCompleted)
                        .foregroundColor(topic.isCompleted ? .secondary : .primary)
                        .animation(.easeInOut(duration: 0.2), value: topic.isCompleted)
                    
                    if let description = topic.description, !description.isEmpty {
                        Text(description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                    
                    // Progress indicators
                    HStack(spacing: 8) {
                        if topic.videoWatched {
                            HStack(spacing: 2) {
                                Image(systemName: "play.circle.fill")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                                Text("Video")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                            }
                            .transition(.scale.combined(with: .opacity))
                        }
                        
                        if topic.taskCompleted {
                            HStack(spacing: 2) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.caption)
                                    .foregroundColor(.green)
                                Text("Task")
                                    .font(.caption)
                                    .foregroundColor(.green)
                            }
                            .transition(.scale.combined(with: .opacity))
                        }
                        
                        Spacer()
                    }
                    .animation(.easeInOut(duration: 0.3), value: topic.videoWatched)
                    .animation(.easeInOut(duration: 0.3), value: topic.taskCompleted)
                }
                
                // Action buttons
                HStack(spacing: 8) {
                    if topic.hasNotes {
                        OptimizedActionButton(
                            icon: "note.text",
                            color: .purple,
                            action: { showingNotes = true }
                        )
                    }
                    
                    // Video toggle button
                    OptimizedActionButton(
                        icon: topic.videoWatched ? "play.circle.fill" : "play.circle",
                        color: topic.videoWatched ? .blue : .gray,
                        action: { toggleVideo() }
                    )
                    
                    // Task toggle button
                    OptimizedActionButton(
                        icon: topic.taskCompleted ? "checkmark.circle.fill" : "circle",
                        color: topic.taskCompleted ? .green : .gray,
                        action: { toggleTask() }
                    )
                }
            }
            
            // Completion timestamp
            if let completedAt = topic.completedAt {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundColor(.green)
                    
                    Text("Completed \(completedAt, style: .relative) ago")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                }
                .transition(.move(edge: .top).combined(with: .opacity))
                .animation(.easeInOut(duration: 0.3), value: topic.completedAt)
            }
        }
        .padding(.vertical, 4)
        .sheet(isPresented: $showingNotes) {
            OptimizedTopicNotesView(topic: topic)
        }
    }
    
    private func toggleCompletion() {
        withAnimation(.easeInOut(duration: 0.3)) {
            topic.isCompleted.toggle()
            
            if topic.isCompleted {
                topic.completedAt = Date()
                topic.videoWatched = true
                topic.taskCompleted = true
            } else {
                topic.completedAt = nil
            }
            
            topic.updatedAt = Date()
        }
        
        autoSaveChanges()
    }
    
    private func toggleVideo() {
        withAnimation(.easeInOut(duration: 0.2)) {
            topic.videoWatched.toggle()
            topic.updatedAt = Date()
            
            // Update completion status
            updateCompletionStatus()
        }
        
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        autoSaveChanges()
    }
    
    private func toggleTask() {
        withAnimation(.easeInOut(duration: 0.2)) {
            topic.taskCompleted.toggle()
            topic.updatedAt = Date()
            
            // Update completion status
            updateCompletionStatus()
        }
        
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        autoSaveChanges()
    }
    
    private func updateCompletionStatus() {
        let wasCompleted = topic.isCompleted
        let shouldBeCompleted = topic.videoWatched && topic.taskCompleted
        
        if wasCompleted != shouldBeCompleted {
            withAnimation(.easeInOut(duration: 0.3)) {
                topic.isCompleted = shouldBeCompleted
                topic.completedAt = shouldBeCompleted ? Date() : nil
            }
        }
    }
    
    private func autoSaveChanges() {
        // Cancel previous timer
        autoSaveTimer?.invalidate()
        
        // Set new timer for auto-save
        autoSaveTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { _ in
            do {
                try viewContext.save()
                
                // Update streaks and check for milestones
                NotificationManager.shared.updateStreakAndCheckMilestones()
            } catch {
                print("❌ Auto-save failed: \(error)")
                
                // Revert changes on save failure
                viewContext.rollback()
            }
        }
    }
}

// MARK: - Optimized Topic Notes View
struct OptimizedTopicNotesView: View {
    @ObservedObject var topic: SystemDesignTopic
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    
    @State private var notesText = ""
    @State private var autoSaveTimer: Timer?
    @State private var hasUnsavedChanges = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(topic.topicName ?? "Unknown Topic")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    if let description = topic.description {
                        Text(description)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Learning Notes")
                            .font(.headline)
                        
                        Spacer()
                        
                        if hasUnsavedChanges {
                            HStack(spacing: 4) {
                                Image(systemName: "circle.fill")
                                    .font(.system(size: 6))
                                    .foregroundColor(.orange)
                                Text("Auto-saving...")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    
                    TextEditor(text: $notesText)
                        .padding(8)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        .frame(minHeight: 200)
                        .onChange(of: notesText) { _ in
                            hasUnsavedChanges = true
                            scheduleAutoSave()
                        }
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Topic Notes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        saveAndDismiss()
                    }
                }
            }
        }
        .onAppear {
            notesText = topic.notes ?? ""
        }
        .onDisappear {
            saveNotes()
        }
    }
    
    private func scheduleAutoSave() {
        // Cancel previous timer
        autoSaveTimer?.invalidate()
        
        // Set new timer for auto-save
        autoSaveTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false) { _ in
            saveNotes()
        }
    }
    
    private func saveNotes() {
        topic.notes = notesText.isEmpty ? nil : notesText
        topic.updatedAt = Date()
        
        do {
            try viewContext.save()
            hasUnsavedChanges = false
        } catch {
            print("❌ Error saving topic notes: \(error)")
        }
    }
    
    private func saveAndDismiss() {
        saveNotes()
        dismiss()
    }
}// MA
RK: - Optimized Reflection View with Auto-save
struct OptimizedReflectionView: View {
    let day: Day?
    @Binding var reflectionText: String
    let onDismiss: () -> Void
    
    @Environment(\.managedObjectContext) private var viewContext
    @State private var autoSaveTimer: Timer?
    @State private var hasUnsavedChanges = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("How did today go?")
                    .font(.headline)
                    .padding(.top)
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Daily Reflection")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Spacer()
                        
                        if hasUnsavedChanges {
                            HStack(spacing: 4) {
                                Image(systemName: "circle.fill")
                                    .font(.system(size: 6))
                                    .foregroundColor(.orange)
                                Text("Auto-saving...")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    
                    TextEditor(text: $reflectionText)
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(12)
                        .frame(minHeight: 200)
                        .onChange(of: reflectionText) { _ in
                            hasUnsavedChanges = true
                            scheduleAutoSave()
                        }
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Daily Reflection")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        saveAndDismiss()
                    }
                }
            }
        }
        .onDisappear {
            saveReflection()
        }
    }
    
    private func scheduleAutoSave() {
        // Cancel previous timer
        autoSaveTimer?.invalidate()
        
        // Set new timer for auto-save
        autoSaveTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: false) { _ in
            saveReflection()
        }
    }
    
    private func saveReflection() {
        guard let day = day else { return }
        
        day.dailyReflection = reflectionText.isEmpty ? nil : reflectionText
        day.updatedAt = Date()
        
        do {
            try viewContext.save()
            hasUnsavedChanges = false
        } catch {
            print("❌ Error saving reflection: \(error)")
        }
    }
    
    private func saveAndDismiss() {
        saveReflection()
        onDismiss()
    }
}