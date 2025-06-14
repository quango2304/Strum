//
//  PreferencesManager.swift
//  Strum
//
//  Created by leongo on 13/6/25.
//

import SwiftUI
import Foundation

// MARK: - Color Theme
enum ColorTheme: String, CaseIterable, Identifiable {
    case blue = "blue"
    case purple = "purple"
    case green = "green"
    case orange = "orange"
    case red = "red"
    case pink = "pink"
    case teal = "teal"
    case indigo = "indigo"
    case tangerine = "tangerine"
    case system = "system"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .blue: return "Ocean Blue"
        case .purple: return "Royal Purple"
        case .green: return "Forest Green"
        case .orange: return "Sunset Orange"
        case .red: return "Cherry Red"
        case .pink: return "Rose Pink"
        case .teal: return "Tropical Teal"
        case .indigo: return "Deep Indigo"
        case .tangerine: return "Tangerine"
        case .system: return "System"
        }
    }
    
    var primaryColor: Color {
        switch self {
        case .blue: return Color.blue
        case .purple: return Color.purple
        case .green: return Color.green
        case .orange: return Color.orange
        case .red: return Color.red
        case .pink: return Color.pink
        case .teal: return Color.teal
        case .indigo: return Color.indigo
        case .tangerine: return Color(red: 1.0, green: 0.4, blue: 0.35) // Tangerine color
        case .system: return Color.accentColor // macOS system accent color
        }
    }
    
    var gradientColors: [Color] {
        switch self {
        case .blue: return [Color.blue, Color.cyan]
        case .purple: return [Color.purple, Color.pink]
        case .green: return [Color.green, Color.mint]
        case .orange: return [Color.orange, Color.yellow]
        case .red: return [Color.red, Color.pink]
        case .pink: return [Color.pink, Color.purple]
        case .teal: return [Color.teal, Color.cyan]
        case .indigo: return [Color.indigo, Color.purple]
        case .tangerine: return [Color(red: 1.0, green: 0.4, blue: 0.35), Color(red: 1.0, green: 0.5, blue: 0.4)]
        case .system: return [Color.accentColor, Color.accentColor.opacity(0.7)]
        }
    }

    // Subtle background tint - very light
    var backgroundTint: Color {
        primaryColor.opacity(0.02)
    }

    // Subtle surface tint for cards and panels
    var surfaceTint: Color {
        primaryColor.opacity(0.04)
    }
    
    var accentColor: Color {
        return primaryColor
    }
}

// MARK: - Preferences Manager
class PreferencesManager: ObservableObject {
    @Published var colorTheme: ColorTheme = .tangerine {
        didSet {
            savePreferences()
        }
    }
    
    @Published var showPreferences = false
    @Published var showAbout = false
    
    private let userDefaults = UserDefaults.standard
    private let colorThemeKey = "StrumColorTheme"
    
    init() {
        loadPreferences()
    }
    
    private func savePreferences() {
        userDefaults.set(colorTheme.rawValue, forKey: colorThemeKey)
    }
    
    private func loadPreferences() {
        if let savedTheme = userDefaults.string(forKey: colorThemeKey),
           let theme = ColorTheme(rawValue: savedTheme) {
            colorTheme = theme
        }
    }
}

// MARK: - Theme Environment Key
struct ThemeEnvironmentKey: EnvironmentKey {
    static let defaultValue: ColorTheme = .red
}

extension EnvironmentValues {
    var colorTheme: ColorTheme {
        get { self[ThemeEnvironmentKey.self] }
        set { self[ThemeEnvironmentKey.self] = newValue }
    }
}

// MARK: - Theme-Aware Design System
extension DesignSystem {
    struct ThemedColors {
        let theme: ColorTheme

        var primary: Color { theme.primaryColor }
        var accent: Color { theme.accentColor }
        var gradient: LinearGradient {
            LinearGradient(
                colors: theme.gradientColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }

        // Reasonably themed base colors - subtle but beautiful
        var secondary: Color { Color.secondary }
        var background: Color {
            // Very subtle background tint - blend colors properly
            Color(NSColor.windowBackgroundColor)
        }
        var surface: Color {
            // Subtle surface tint for panels - blend colors properly
            Color(NSColor.controlBackgroundColor)
        }
        var surfaceSecondary: Color { Color(NSColor.controlBackgroundColor) }
        var border: Color {
            // Slightly themed borders
            Color(NSColor.separatorColor)
        }
        var overlay: Color { Color.black.opacity(0.3) }

        // Enhanced colors with theme - reasonable opacity levels
        var cardBackground: Color {
            Color(NSColor.controlBackgroundColor).opacity(0.95)
        }
        var hoverBackground: Color { primary.opacity(0.06) }
        var activeBackground: Color { primary.opacity(0.1) }
        var shadowColor: Color { Color.black.opacity(0.08) }

        // Progress and volume controls - themed but not overwhelming
        var progressTrack: Color { theme.primaryColor.opacity(0.2) }
        var progressFill: Color { theme.primaryColor }
        var volumeTrack: Color { theme.primaryColor.opacity(0.25) }
        var volumeThumb: Color { theme.primaryColor }

        // Sidebar theming - very subtle
        var sidebarBackground: Color {
            Color(NSColor.controlBackgroundColor)
        }
        var sidebarSelection: Color { theme.primaryColor.opacity(0.12) }
        var sidebarHover: Color { theme.primaryColor.opacity(0.05) }

        // Consistent section backgrounds with subtle theme gradient
        var sectionBackground: LinearGradient {
            LinearGradient(
                colors: [
                    theme.gradientColors[0].opacity(0.03),
                    theme.gradientColors[1].opacity(0.02),
                    theme.gradientColors[0].opacity(0.03)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
    
    static func colors(for theme: ColorTheme) -> ThemedColors {
        return ThemedColors(theme: theme)
    }
}

// MARK: - Theme-Aware Button Styles
struct ThemedPrimaryButtonStyle: ButtonStyle {
    let isCompact: Bool
    let theme: ColorTheme
    
    init(isCompact: Bool = false, theme: ColorTheme = .red) {
        self.isCompact = isCompact
        self.theme = theme
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(isCompact ? .system(size: 14, weight: .medium) : .system(size: 16, weight: .medium))
            .foregroundColor(.white)
            .padding(.horizontal, isCompact ? 12 : 16)
            .padding(.vertical, isCompact ? 6 : 8)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                    .fill(theme.primaryColor)
                    .opacity(configuration.isPressed ? 0.8 : 1.0)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct ThemedIconButtonStyle: ButtonStyle {
    let size: CGFloat
    let isActive: Bool
    let theme: ColorTheme
    let useGradient: Bool

    init(size: CGFloat = 32, isActive: Bool = false, theme: ColorTheme = .red, useGradient: Bool = false) {
        self.size = size
        self.isActive = isActive
        self.theme = theme
        self.useGradient = useGradient
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: size * 0.5))
            .foregroundColor(isActive ? .white : .primary)
            .frame(width: size, height: size)
            .background(
                Circle()
                    .fill(
                        isActive && useGradient ?
                        AnyShapeStyle(LinearGradient(
                            colors: theme.gradientColors,
                            startPoint: .leading,
                            endPoint: .trailing
                        )) :
                        AnyShapeStyle(isActive ? theme.primaryColor : DesignSystem.colors(for: theme).hoverBackground)
                    )
                    .opacity(configuration.isPressed ? 0.8 : 1.0)
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}
