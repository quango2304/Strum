//
//  PreferencesManager.swift
//  Strum
//
//  Created by leongo on 13/6/25.
//  Refactored on 14/6/25 for better code organization
//

import SwiftUI
import Foundation
import AppKit

// MARK: - Color Theme

/**
 * Enumeration defining available color themes for the application.
 *
 * Each theme provides:
 * - A unique identifier and display name
 * - Primary and accent colors
 * - Gradient color combinations
 * - Background and surface tints
 *
 * Themes are designed to provide visual variety while maintaining
 * accessibility and readability across the interface.
 */
enum ColorTheme: String, CaseIterable, Identifiable {
    /// Ocean blue theme with cyan accents
    case blue = "blue"

    /// Royal purple theme with pink accents
    case purple = "purple"

    /// Forest green theme with mint accents
    case green = "green"

    /// Sunset orange theme with yellow accents
    case orange = "orange"

    /// Cherry red theme with pink accents
    case red = "red"

    /// Rose pink theme with purple accents
    case pink = "pink"

    /// Tropical teal theme with cyan accents
    case teal = "teal"

    /// Deep indigo theme with purple accents
    case indigo = "indigo"

    /// Tangerine theme (default) with warm orange tones
    case tangerine = "tangerine"

    /// System theme using macOS accent color
    case system = "system"

    /// Unique identifier for the theme
    var id: String { rawValue }

    /**
     * User-friendly display name for the theme.
     *
     * These names are shown in the preferences interface and provide
     * descriptive, appealing names for each color scheme.
     */
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

    /**
     * Primary color for the theme.
     *
     * This color is used for main UI elements like buttons, progress bars,
     * and active states. Each theme provides a distinct primary color that
     * defines the overall visual character.
     */
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
        case .tangerine: return Color(red: 1.0, green: 0.4, blue: 0.35) // Custom tangerine color
        case .system: return Color.accentColor // Uses macOS system accent color
        }
    }

    /**
     * Gradient colors for enhanced visual effects.
     *
     * Each theme provides a two-color gradient that creates smooth
     * transitions and visual depth in UI elements like buttons and backgrounds.
     */
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

    /**
     * Subtle background tint for the main application background.
     *
     * Provides a very light theme-colored tint (2% opacity) to give
     * the background a subtle themed appearance without overwhelming content.
     */
    var backgroundTint: Color {
        primaryColor.opacity(0.02)
    }

    /**
     * Subtle surface tint for cards, panels, and elevated surfaces.
     *
     * Provides a light theme-colored tint (4% opacity) for UI surfaces
     * that need to stand out from the background while maintaining subtlety.
     */
    var surfaceTint: Color {
        primaryColor.opacity(0.04)
    }

    /**
     * Accent color for the theme (alias for primaryColor).
     *
     * Provides semantic naming for accent color usage in the interface.
     */
    var accentColor: Color {
        return primaryColor
    }
}

// MARK: - Preferences Manager

/**
 * Manages application preferences and settings.
 *
 * This class handles:
 * - Color theme selection and persistence
 * - UI state for preferences and about dialogs
 * - Automatic app icon updates when themes change
 * - UserDefaults integration for persistent storage
 *
 * The PreferencesManager automatically saves changes and coordinates
 * with the IconManager to update the app icon when themes change.
 */
class PreferencesManager: ObservableObject {
    // MARK: - Published Properties

    /**
     * Currently selected color theme.
     *
     * When changed, automatically saves the preference and updates
     * the app icon to match the new theme.
     */
    @Published var colorTheme: ColorTheme = .tangerine {
        didSet {
            savePreferences()
            // Update app icon when theme changes
            IconManager.shared.updateIcon(for: colorTheme)
        }
    }

    /// Controls visibility of the preferences popup
    @Published var showPreferences = false

    /// Controls visibility of the about dialog
    @Published var showAbout = false

    // MARK: - Private Properties

    /// UserDefaults instance for persistent storage
    private let userDefaults = UserDefaults.standard

    /// Key for storing color theme preference
    private let colorThemeKey = "StrumColorTheme"

    // MARK: - Initialization

    /**
     * Initializes the preferences manager.
     *
     * Loads saved preferences from UserDefaults and sets the
     * appropriate app icon for the current theme.
     */
    init() {
        loadPreferences()
        // Set the correct icon for the loaded theme
        IconManager.shared.updateIcon(for: colorTheme)
    }

    // MARK: - Persistence Methods

    /**
     * Saves current preferences to UserDefaults.
     *
     * Currently saves the selected color theme. This method is
     * called automatically when the colorTheme property changes.
     */
    private func savePreferences() {
        userDefaults.set(colorTheme.rawValue, forKey: colorThemeKey)
    }

    /**
     * Loads preferences from UserDefaults.
     *
     * Attempts to restore the previously selected color theme.
     * If no saved theme exists, uses the default (.tangerine).
     */
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
            .foregroundColor(isActive ? Color.white : Color.primary)
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

// MARK: - Action-Specific Icon Button Style
enum IconActionType {
    case add
    case edit
    case delete

    var backgroundColor: Color {
        switch self {
        case .add:
            return .green
        case .edit:
            return .yellow
        case .delete:
            return .red
        }
    }
}

struct ActionIconButtonStyle: ButtonStyle {
    let size: CGFloat
    let actionType: IconActionType

    init(size: CGFloat = 32, actionType: IconActionType) {
        self.size = size
        self.actionType = actionType
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: size * 0.5))
            .foregroundColor(.white)
            .frame(width: size, height: size)
            .background(
                Circle()
                    .fill(actionType.backgroundColor)
                    .opacity(configuration.isPressed ? 0.8 : 1.0)
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}
