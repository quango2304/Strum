//
//  DesignSystem.swift
//  Strum
//
//  Created by leongo on 13/6/25.
//  Refactored on 14/6/25 for better code organization
//

import SwiftUI
import AppKit

// MARK: - Design System

/**
 * Central design system providing consistent styling across the application.
 *
 * The DesignSystem struct contains:
 * - Color definitions (legacy and themed)
 * - Typography scales and custom fonts
 * - Spacing constants for consistent layouts
 * - Corner radius values for rounded elements
 * - Shadow definitions for depth and elevation
 *
 * This design system ensures visual consistency and makes it easy to
 * maintain and update the app's appearance from a central location.
 */
struct DesignSystem {

    // MARK: - Colors (Legacy - use ThemedColors instead)

    /**
     * Legacy color definitions using system colors.
     *
     * These colors are being phased out in favor of the themed color system.
     * They provide fallback values and are used in components that haven't
     * been updated to use the new theming system.
     */
    struct Colors {
        /// Primary accent color from system preferences
        static let primary = Color.accentColor

        /// Secondary text and UI element color
        static let secondary = Color.secondary

        /// Main background color for controls
        static let background = Color(NSColor.controlBackgroundColor)

        /// Window background color
        static let surface = Color(NSColor.windowBackgroundColor)

        /// Secondary surface color for elevated elements
        static let surfaceSecondary = Color(NSColor.controlBackgroundColor)

        /// Border and separator color
        static let border = Color(NSColor.separatorColor)

        /// Overlay color for modal backgrounds
        static let overlay = Color.black.opacity(0.3)

        // MARK: - Enhanced UI Colors

        /// Semi-transparent background for card elements
        static let cardBackground = Color(NSColor.controlBackgroundColor).opacity(0.8)

        /// Subtle hover state background
        static let hoverBackground = Color.primary.opacity(0.08)

        /// Active/pressed state background
        static let activeBackground = Color.primary.opacity(0.12)

        /// Standard shadow color for depth effects
        static let shadowColor = Color.black.opacity(0.1)
    }

    // MARK: - Typography

    /**
     * Typography scale providing consistent text styling across the application.
     *
     * Includes both system font styles with custom weights and specialized
     * fonts for specific UI components like the music player and track lists.
     */
    struct Typography {
        // MARK: - System Typography

        /// Large title for main headings (bold weight)
        static let largeTitle = Font.largeTitle.weight(.bold)

        /// Primary title for section headers (semibold weight)
        static let title = Font.title.weight(.semibold)

        /// Secondary title for subsections (semibold weight)
        static let title2 = Font.title2.weight(.semibold)

        /// Headline for prominent text (medium weight)
        static let headline = Font.headline.weight(.medium)

        /// Standard body text
        static let body = Font.body

        /// Callout text for secondary information
        static let callout = Font.callout

        /// Caption text for labels and metadata
        static let caption = Font.caption

        /// Smaller caption text for fine details
        static let caption2 = Font.caption2

        // MARK: - Custom Typography

        /// Title text in the music player controls
        static let playerTitle = Font.system(size: 16, weight: .medium, design: .default)

        /// Subtitle text in the music player controls
        static let playerSubtitle = Font.system(size: 14, weight: .regular, design: .default)

        /// Track title in track list rows
        static let trackTitle = Font.system(size: 14, weight: .medium, design: .default)

        /// Track metadata in track list rows
        static let trackSubtitle = Font.system(size: 12, weight: .regular, design: .default)
    }

    // MARK: - Spacing

    /**
     * Consistent spacing values for layouts and component padding.
     *
     * Provides a scale from extra-small (4pt) to extra-extra-extra-large (32pt)
     * to ensure consistent spacing throughout the interface.
     */
    struct Spacing {
        /// Extra small spacing (4pt) - for tight layouts
        static let xs: CGFloat = 4

        /// Small spacing (8pt) - for compact elements
        static let sm: CGFloat = 8

        /// Medium spacing (12pt) - standard element spacing
        static let md: CGFloat = 12

        /// Large spacing (16pt) - section spacing
        static let lg: CGFloat = 16

        /// Extra large spacing (20pt) - major section spacing
        static let xl: CGFloat = 20

        /// Extra extra large spacing (24pt) - large gaps
        static let xxl: CGFloat = 24

        /// Extra extra extra large spacing (32pt) - major layout spacing
        static let xxxl: CGFloat = 32
    }

    // MARK: - Corner Radius

    /**
     * Corner radius values for rounded rectangles and UI elements.
     *
     * Provides consistent rounding from small (6pt) to fully round (50pt)
     * for buttons, cards, and other interface elements.
     */
    struct CornerRadius {
        /// Small corner radius (6pt) - subtle rounding
        static let sm: CGFloat = 6

        /// Medium corner radius (8pt) - standard buttons and cards
        static let md: CGFloat = 8

        /// Large corner radius (12pt) - prominent elements
        static let lg: CGFloat = 12

        /// Extra large corner radius (16pt) - major containers
        static let xl: CGFloat = 16

        /// Fully round corners (50pt) - circular elements
        static let round: CGFloat = 50
    }

    // MARK: - Shadows

    /**
     * Shadow color definitions for depth and elevation effects.
     *
     * Provides three levels of shadow intensity for different
     * elevation levels in the interface hierarchy.
     */
    struct Shadow {
        /// Light shadow (5% opacity) - subtle depth
        static let light = Color.black.opacity(0.05)

        /// Medium shadow (10% opacity) - standard elevation
        static let medium = Color.black.opacity(0.1)

        /// Heavy shadow (20% opacity) - prominent elevation
        static let heavy = Color.black.opacity(0.2)
    }
}

// MARK: - Custom Button Styles
struct PrimaryButtonStyle: ButtonStyle {
    let isCompact: Bool
    
    init(isCompact: Bool = false) {
        self.isCompact = isCompact
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(isCompact ? .system(size: 14, weight: .medium) : .system(size: 16, weight: .medium))
            .foregroundColor(.white)
            .padding(.horizontal, isCompact ? 12 : 16)
            .padding(.vertical, isCompact ? 6 : 8)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                    .fill(Color.accentColor)
                    .opacity(configuration.isPressed ? 0.8 : 1.0)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    let isCompact: Bool
    
    init(isCompact: Bool = false) {
        self.isCompact = isCompact
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(isCompact ? .system(size: 14, weight: .medium) : .system(size: 16, weight: .medium))
            .foregroundColor(.primary)
            .padding(.horizontal, isCompact ? 12 : 16)
            .padding(.vertical, isCompact ? 6 : 8)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                    .fill(DesignSystem.Colors.surfaceSecondary)
                    .opacity(configuration.isPressed ? 0.8 : 1.0)
            )
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                    .stroke(DesignSystem.Colors.border, lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct IconButtonStyle: ButtonStyle {
    let size: CGFloat
    let isActive: Bool
    
    init(size: CGFloat = 32, isActive: Bool = false) {
        self.size = size
        self.isActive = isActive
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: size * 0.5))
            .foregroundColor(isActive ? .white : .primary)
            .frame(width: size, height: size)
            .background(
                Circle()
                    .fill(isActive ? Color.accentColor : DesignSystem.Colors.hoverBackground)
                    .opacity(configuration.isPressed ? 0.8 : 1.0)
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Custom Card Style
struct CardModifier: ViewModifier {
    let padding: CGFloat
    let cornerRadius: CGFloat
    
    init(padding: CGFloat = DesignSystem.Spacing.md, cornerRadius: CGFloat = DesignSystem.CornerRadius.lg) {
        self.padding = padding
        self.cornerRadius = cornerRadius
    }
    
    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(DesignSystem.Colors.cardBackground)
                    .shadow(color: DesignSystem.Shadow.light, radius: 2, x: 0, y: 1)
            )
    }
}

extension View {
    func cardStyle(padding: CGFloat = DesignSystem.Spacing.md, cornerRadius: CGFloat = DesignSystem.CornerRadius.lg) -> some View {
        modifier(CardModifier(padding: padding, cornerRadius: cornerRadius))
    }
}
