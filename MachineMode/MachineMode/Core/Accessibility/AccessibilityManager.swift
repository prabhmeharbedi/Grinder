import SwiftUI
import UIKit

class AccessibilityManager: ObservableObject {
    static let shared = AccessibilityManager()
    
    @Published var isVoiceOverEnabled = false
    @Published var preferredContentSizeCategory: ContentSizeCategory = .medium
    @Published var isReduceMotionEnabled = false
    @Published var isHighContrastEnabled = false
    
    private init() {
        observeAccessibilityChanges()
        updateAccessibilityStatus()
    }
    
    private func observeAccessibilityChanges() {
        NotificationCenter.default.addObserver(
            forName: UIAccessibility.voiceOverStatusDidChangeNotification,
            object: nil,
            queue: .main
        ) { _ in
            self.updateAccessibilityStatus()
        }
        
        NotificationCenter.default.addObserver(
            forName: UIContentSizeCategory.didChangeNotification,
            object: nil,
            queue: .main
        ) { _ in
            self.updateAccessibilityStatus()
        }
        
        NotificationCenter.default.addObserver(
            forName: UIAccessibility.reduceMotionStatusDidChangeNotification,
            object: nil,
            queue: .main
        ) { _ in
            self.updateAccessibilityStatus()
        }
    }
    
    private func updateAccessibilityStatus() {
        isVoiceOverEnabled = UIAccessibility.isVoiceOverRunning
        preferredContentSizeCategory = ContentSizeCategory(UIApplication.shared.preferredContentSizeCategory)
        isReduceMotionEnabled = UIAccessibility.isReduceMotionEnabled
        isHighContrastEnabled = UIAccessibility.isDarkerSystemColorsEnabled
        
        print("♿ Accessibility Status Updated:")
        print("   VoiceOver: \(isVoiceOverEnabled)")
        print("   Content Size: \(preferredContentSizeCategory)")
        print("   Reduce Motion: \(isReduceMotionEnabled)")
        print("   High Contrast: \(isHighContrastEnabled)")
    }
    
    // MARK: - Accessibility Helpers
    
    func announceForVoiceOver(_ message: String) {
        if isVoiceOverEnabled {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                UIAccessibility.post(notification: .announcement, argument: message)
            }
        }
    }
    
    func focusOnElement(_ element: Any) {
        if isVoiceOverEnabled {
            UIAccessibility.post(notification: .screenChanged, argument: element)
        }
    }
    
    func getAccessibleFont(for style: Font.TextStyle, weight: Font.Weight = .regular) -> Font {
        return Font.system(style, design: .default, weight: weight)
    }
    
    func getOptimalAnimationDuration(_ baseDuration: TimeInterval) -> TimeInterval {
        return isReduceMotionEnabled ? 0.01 : baseDuration
    }
}