import SwiftUI
import Combine

// MARK: - Theme Manager for Light/Dark Mode Support
class ThemeManager: ObservableObject {
    static let shared = ThemeManager()
    
    @Published var currentTheme: AppTheme = .system
    @Published var isDarkMode: Bool = false
    
    private var cancellables = Set<AnyCancellable>()
    
    enum AppTheme: String, CaseIterable {
        case light = "Light"
        case dark = "Dark"
        case system = "System"
        
        var colorScheme: ColorScheme? {
            switch self {
            case .light:
                return .light
            case .dark:
                return .dark
            case .system:
                return nil
            }
        }
    }
    
    private init() {
        loadTheme()
        observeSystemThemeChanges()
    }
    
    private func loadTheme() {
        let savedTheme = UserDefaults.standard.string(forKey: "AppTheme") ?? AppTheme.system.rawValue
        currentTheme = AppTheme(rawValue: savedTheme) ?? .system
        updateDarkModeStatus()
    }
    
    private func observeSystemThemeChanges() {
        NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)
            .sink { [weak self] _ in
                self?.updateDarkModeStatus()
            }
            .store(in: &cancellables)
    }
    
    func setTheme(_ theme: AppTheme) {
        currentTheme = theme
        UserDefaults.standard.set(theme.rawValue, forKey: "AppTheme")
        updateDarkModeStatus()
    }
    
    private func updateDarkModeStatus() {
        switch currentTheme {
        case .light:
            isDarkMode = false
        case .dark:
            isDarkMode = true
        case .system:
            isDarkMode = UITraitCollection.current.userInterfaceStyle == .dark
        }
    }
}

// MARK: - Theme Colors
extension Color {
    static let theme = ThemeColors()
}

struct ThemeColors {
    // Primary Colors
    let primary = Color("PrimaryColor", bundle: nil) ?? Color.blue
    let secondary = Color("SecondaryColor", bundle: nil) ?? Color.gray
    let accent = Color("AccentColor", bundle: nil) ?? Color.blue
    
    // Background Colors
    let background = Color("BackgroundColor", bundle: nil) ?? Color(.systemBackground)
    let secondaryBackground = Color("SecondaryBackgroundColor", bundle: nil) ?? Color(.secondarySystemBackground)
    let tertiaryBackground = Color("TertiaryBackgroundColor", bundle: nil) ?? Color(.tertiarySystemBackground)
    
    // Text Colors
    let primaryText = Color("PrimaryTextColor", bundle: nil) ?? Color(.label)
    let secondaryText = Color("SecondaryTextColor", bundle: nil) ?? Color(.secondaryLabel)
    let tertiaryText = Color("TertiaryTextColor", bundle: nil) ?? Color(.tertiaryLabel)
    
    // Status Colors
    let success = Color("SuccessColor", bundle: nil) ?? Color.green
    let warning = Color("WarningColor", bundle: nil) ?? Color.orange
    let error = Color("ErrorColor", bundle: nil) ?? Color.red
    let info = Color("InfoColor", bundle: nil) ?? Color.blue
    
    // Difficulty Colors
    let easy = Color("EasyColor", bundle: nil) ?? Color.green
    let medium = Color("MediumColor", bundle: nil) ?? Color.orange
    let hard = Color("HardColor", bundle: nil) ?? Color.red
    
    // Progress Colors
    let dsaProgress = Color("DSAProgressColor", bundle: nil) ?? Color.blue
    let systemDesignProgress = Color("SystemDesignProgressColor", bundle: nil) ?? Color.orange
    let overallProgress = Color("OverallProgressColor", bundle: nil) ?? Color.purple
}

// MARK: - Theme-Aware View Modifier
struct ThemeAware: ViewModifier {
    @StateObject private var themeManager = ThemeManager.shared
    
    func body(content: Content) -> some View {
        content
            .preferredColorScheme(themeManager.currentTheme.colorScheme)
            .environmentObject(themeManager)
    }
}

extension View {
    func themeAware() -> some View {
        modifier(ThemeAware())
    }
}

// MARK: - Adaptive Colors for Better Dark Mode Support
extension Color {
    static func adaptive(light: Color, dark: Color) -> Color {
        return Color(UIColor { traitCollection in
            switch traitCollection.userInterfaceStyle {
            case .dark:
                return UIColor(dark)
            default:
                return UIColor(light)
            }
        })
    }
    
    // Optimized colors for both themes
    static let adaptiveBlue = adaptive(light: .blue, dark: Color.blue.opacity(0.8))
    static let adaptiveGreen = adaptive(light: .green, dark: Color.green.opacity(0.8))
    static let adaptiveOrange = adaptive(light: .orange, dark: Color.orange.opacity(0.8))
    static let adaptiveRed = adaptive(light: .red, dark: Color.red.opacity(0.8))
    static let adaptivePurple = adaptive(light: .purple, dark: Color.purple.opacity(0.8))
    
    // Background colors that work well in both themes
    static let adaptiveBackground = adaptive(
        light: Color(.systemBackground),
        dark: Color(.systemBackground)
    )
    
    static let adaptiveSecondaryBackground = adaptive(
        light: Color(.secondarySystemBackground),
        dark: Color(.secondarySystemBackground)
    )
    
    // Card background with subtle differences
    static let cardBackground = adaptive(
        light: Color.white,
        dark: Color(.systemGray6)
    )
    
    // Shadow colors
    static let shadowColor = adaptive(
        light: Color.black.opacity(0.1),
        dark: Color.black.opacity(0.3)
    )
}

// MARK: - Theme-Aware Components
struct ThemedCard<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .padding()
            .background(Color.cardBackground)
            .cornerRadius(16)
            .shadow(color: Color.shadowColor, radius: 8, x: 0, y: 2)
    }
}

struct ThemedButton: View {
    let title: String
    let icon: String?
    let color: Color
    let action: () -> Void
    
    @State private var isPressed = false
    
    init(_ title: String, icon: String? = nil, color: Color = .adaptiveBlue, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.color = color
        self.action = action
    }
    
    var body: some View {
        Button(action: {
            // Haptic feedback
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
            
            action()
        }) {
            HStack(spacing: 8) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .medium))
                }
                
                Text(title)
                    .font(.system(size: 16, weight: .medium))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(color)
            .cornerRadius(12)
            .scaleEffect(isPressed ? 0.95 : 1.0)
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

// MARK: - Theme Settings View
struct ThemeSettingsView: View {
    @StateObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Appearance")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(spacing: 12) {
                ForEach(ThemeManager.AppTheme.allCases, id: \.self) { theme in
                    Button(action: {
                        themeManager.setTheme(theme)
                    }) {
                        HStack {
                            Image(systemName: themeIcon(for: theme))
                                .font(.system(size: 20))
                                .foregroundColor(themeManager.currentTheme == theme ? .adaptiveBlue : .secondary)
                            
                            Text(theme.rawValue)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            if themeManager.currentTheme == theme {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(.adaptiveBlue)
                            }
                        }
                        .padding()
                        .background(Color.adaptiveSecondaryBackground)
                        .cornerRadius(12)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .padding()
    }
    
    private func themeIcon(for theme: ThemeManager.AppTheme) -> String {
        switch theme {
        case .light:
            return "sun.max.fill"
        case .dark:
            return "moon.fill"
        case .system:
            return "gear"
        }
    }
}