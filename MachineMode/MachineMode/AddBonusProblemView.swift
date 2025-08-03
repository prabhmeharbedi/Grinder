import SwiftUI

struct AddBonusProblemView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    let day: Day
    
    @State private var problemName = ""
    @State private var leetcodeNumber = ""
    @State private var selectedDifficulty = "Easy"
    @State private var showingError = false
    @State private var errorMessage = ""
    
    private let difficulties = ["Easy", "Medium", "Hard"]
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Problem Details")) {
                    TextField("Problem Name", text: $problemName)
                        .textInputAutocapitalization(.words)
                    
                    TextField("LeetCode Number (optional)", text: $leetcodeNumber)
                        .keyboardType(.numberPad)
                    
                    Picker("Difficulty", selection: $selectedDifficulty) {
                        ForEach(difficulties, id: \.self) { difficulty in
                            Text(difficulty).tag(difficulty)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                Section(footer: Text("Bonus problems are additional problems you solve beyond the daily curriculum. They contribute to your overall progress.")) {
                    EmptyView()
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
                        addBonusProblem()
                    }
                    .fontWeight(.semibold)
                    .disabled(problemName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func addBonusProblem() {
        let trimmedName = problemName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedNumber = leetcodeNumber.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedName.isEmpty else {
            errorMessage = "Problem name cannot be empty"
            showingError = true
            return
        }
        
        // Validate LeetCode number if provided
        if !trimmedNumber.isEmpty && Int(trimmedNumber) == nil {
            errorMessage = "LeetCode number must be a valid number"
            showingError = true
            return
        }
        
        // Create the bonus problem
        if let bonusProblem = day.addBonusProblem(
            name: trimmedName,
            leetcodeNumber: trimmedNumber.isEmpty ? nil : trimmedNumber,
            difficulty: selectedDifficulty
        ) {
            do {
                try viewContext.save()
                dismiss()
            } catch {
                errorMessage = "Failed to save bonus problem: \(error.localizedDescription)"
                showingError = true
            }
        } else {
            errorMessage = "Failed to create bonus problem"
            showingError = true
        }
    }
}

// MARK: - Preview
struct AddBonusProblemView_Previews: PreviewProvider {
    static var previews: some View {
        let context = PersistenceController.preview.container.viewContext
        let day = Day(context: context)
        day.dayNumber = 1
        day.date = Date()
        
        return AddBonusProblemView(day: day)
            .environment(\.managedObjectContext, context)
    }
}