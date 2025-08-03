import SwiftUI
import CoreData

struct SystemDesignTopicRowView: View {
    let topic: SystemDesignTopic
    let onToggle: () -> Void
    
    @State private var showingNotes = false
    @State private var showingDetails = false
    
    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 12) {
                // Completion checkbox
                Button(action: onToggle) {
                    Image(systemName: topic.isCompleted ? "checkmark.circle.fill" : "circle")
                        .font(.title2)
                        .foregroundColor(topic.isCompleted ? .green : .gray)
                }
                .buttonStyle(PlainButtonStyle())
                
                // Topic details
                VStack(alignment: .leading, spacing: 4) {
                    Text(topic.topicName ?? "Unknown Topic")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .strikethrough(topic.isCompleted)
                        .foregroundColor(topic.isCompleted ? .secondary : .primary)
                    
                    if let description = topic.topicDescription, !description.isEmpty {
                        Text(description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                    
                    // Progress indicators
                    HStack(spacing: 12) {
                        HStack(spacing: 4) {
                            Image(systemName: topic.videoWatched ? "checkmark.circle.fill" : "circle")
                                .font(.caption)
                                .foregroundColor(topic.videoWatched ? .green : .gray)
                            Text("Video")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        HStack(spacing: 4) {
                            Image(systemName: topic.taskCompleted ? "checkmark.circle.fill" : "circle")
                                .font(.caption)
                                .foregroundColor(topic.taskCompleted ? .green : .gray)
                            Text("Task")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        // Progress percentage
                        Text("\(Int(topic.completionPercentage * 100))%")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.orange)
                    }
                }
                
                // Action buttons
                HStack(spacing: 8) {
                    if topic.hasNotes {
                        Button(action: { showingNotes = true }) {
                            Image(systemName: "note.text")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    
                    Button(action: { showingDetails = true }) {
                        Image(systemName: "info.circle")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                    .buttonStyle(PlainButtonStyle())
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
            }
        }
        .padding(.vertical, 4)
        .sheet(isPresented: $showingNotes) {
            TopicNotesView(topic: topic)
        }
        .sheet(isPresented: $showingDetails) {
            TopicDetailView(topic: topic)
        }
    }
}

// MARK: - Topic Notes View

struct TopicNotesView: View {
    let topic: SystemDesignTopic
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    
    @State private var notesText: String = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(topic.topicName ?? "Unknown Topic")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    if let description = topic.topicDescription {
                        Text(description)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Learning Notes")
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
            .navigationTitle("Topic Notes")
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
            notesText = topic.notes ?? ""
        }
    }
    
    private func saveNotes() {
        topic.updateNotes(notesText.isEmpty ? nil : notesText)
        
        do {
            try viewContext.save()
            dismiss()
        } catch {
            print("Error saving notes: \(error)")
        }
    }
}

// MARK: - Topic Detail View

struct TopicDetailView: View {
    let topic: SystemDesignTopic
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    
    @State private var videoWatched: Bool = false
    @State private var taskCompleted: Bool = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 12) {
                    Text(topic.topicName ?? "Unknown Topic")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    if let description = topic.topicDescription {
                        Text(description)
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                VStack(spacing: 16) {
                    Text("Task Progress")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    VStack(spacing: 12) {
                        HStack {
                            Button(action: {
                                videoWatched.toggle()
                            }) {
                                HStack {
                                    Image(systemName: videoWatched ? "checkmark.circle.fill" : "circle")
                                        .foregroundColor(videoWatched ? .green : .gray)
                                    
                                    Text("Video Watched")
                                        .foregroundColor(.primary)
                                    
                                    Spacer()
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        
                        HStack {
                            Button(action: {
                                taskCompleted.toggle()
                            }) {
                                HStack {
                                    Image(systemName: taskCompleted ? "checkmark.circle.fill" : "circle")
                                        .foregroundColor(taskCompleted ? .green : .gray)
                                    
                                    Text("Task Completed")
                                        .foregroundColor(.primary)
                                    
                                    Spacer()
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    }
                    
                    // Progress indicator
                    VStack(spacing: 8) {
                        HStack {
                            Text("Overall Progress")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            Spacer()
                            
                            let progress = (videoWatched ? 0.5 : 0.0) + (taskCompleted ? 0.5 : 0.0)
                            Text("\(Int(progress * 100))%")
                                .font(.subheadline)
                                .fontWeight(.bold)
                                .foregroundColor(.orange)
                        }
                        
                        ProgressView(value: progress)
                            .progressViewStyle(LinearProgressViewStyle(tint: .orange))
                            .scaleEffect(x: 1, y: 2)
                    }
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Topic Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveProgress()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .onAppear {
            videoWatched = topic.videoWatched
            taskCompleted = topic.taskCompleted
        }
    }
    
    private func saveProgress() {
        topic.videoWatched = videoWatched
        topic.taskCompleted = taskCompleted
        topic.updateCompletionStatus()
        
        do {
            try viewContext.save()
            dismiss()
        } catch {
            print("Error saving progress: \(error)")
        }
    }
}

// MARK: - Preview

struct SystemDesignTopicRowView_Previews: PreviewProvider {
    static var previews: some View {
        let context = PersistenceController.preview.container.viewContext
        let topic = SystemDesignTopic(context: context)
        topic.topicName = "DNS & Domain Resolution"
        topic.topicDescription = "Watch: 'DNS Explained - How Domain Name System Works' - PowerCert Animated Videos"
        topic.isCompleted = false
        topic.videoWatched = true
        topic.taskCompleted = false
        
        return SystemDesignTopicRowView(topic: topic) {
            topic.isCompleted.toggle()
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}