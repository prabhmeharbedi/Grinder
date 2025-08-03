import SwiftUI

// MARK: - Accessible Checkbox
struct AccessibleCheckbox: View {
    @Binding var isChecked: Bool
    let problemName: String
    let difficulty: String
    let timeSpent: Int32
    let hasNotes: Bool
    let onToggle: () -> Void
    
    @StateObject private var accessibilityManager = AccessibilityManager.shared
    
    var body: some View {
        OptimizedCheckbox(isChecked: $isChecked) {
            onToggle()
            
            // Announce state change
            let message = isChecked ? 
                "\(problemName) marked as complete" : 
                "\(problemName) marked as incomplete"
            accessibilityManager.announceForVoiceOver(message)
        }
        .accessibilityLabel(VoiceOverHelper.problemRowAccessibilityLabel(
            problemName: problemName,
            difficulty: difficulty,
            isCompleted: isChecked,
            timeSpent: timeSpent,
            hasNotes: hasNotes
        ))
        .accessibilityHint(VoiceOverHelper.problemRowAccessibilityHint(isCompleted: isChecked))
        .accessibilityAddTraits(isChecked ? .isSelected : [])
        .accessibilityElement(children: .ignore)
    }
}

// MARK: - Accessible Progress Bar
struct AccessibleProgressBar: View {
    let current: Int
    let total: Int
    let color: Color
    
    private var percentage: Double {
        guard total > 0 else { return 0 }
        return Double(current) / Double(total) * 100
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 8)
                
                RoundedRectangle(cornerRadius: 4)
                    .fill(color)
                    .frame(width: geometry.size.width * (Double(current) / Double(total)), height: 8)
                    .animation(.easeInOut(duration: AccessibilityManager.shared.getOptimalAnimationDuration(0.3)), value: current)
            }
        }
        .frame(height: 8)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(VoiceOverHelper.progressAccessibilityLabel(
            current: current,
            total: total,
            percentage: percentage
        ))
        .accessibilityValue(Text("\(String(format: "%.0f", percentage))%"))
        .accessibilityAddTraits(.updatesFrequently)
    }
}

// MARK: - Accessible Tab View
struct AccessibleTabView<Content: View>: View {
    @Binding var selectedTab: Int
    let content: Content
    
    @StateObject private var accessibilityManager = AccessibilityManager.shared
    
    init(selection: Binding<Int>, @ViewBuilder content: () -> Content) {
        self._selectedTab = selection
        self.content = content()
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            content
        }
        .onChange(of: selectedTab) { newTab in
            let tabNames = ["Today", "Progress", "Settings"]
            if newTab < tabNames.count {
                accessibilityManager.announceForVoiceOver("\(tabNames[newTab]) tab selected")
            }
        }
    }
}

// MARK: - Accessible Button
struct AccessibleButton: View {
    let title: String
    let icon: String?
    let action: () -> Void
    let accessibilityHint: String?
    
    @StateObject private var accessibilityManager = AccessibilityManager.shared
    
    init(_ title: String, icon: String? = nil, accessibilityHint: String? = nil, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.accessibilityHint = accessibilityHint
        self.action = action
    }
    
    var body: some View {
        Button(action: {
            action()
            accessibilityManager.announceForVoiceOver("\(title) activated")
        }) {
            HStack {
                if let icon = icon {
                    Image(systemName: icon)
                }
                Text(title)
            }
        }
        .accessibilityLabel(title)
        .accessibilityHint(accessibilityHint ?? "")
        .accessibilityAddTraits(.isButton)
    }
}