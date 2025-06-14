//
//  IconManager.swift
//  Strum
//
//  Created by leongo on 14/6/25.
//  Refactored on 14/6/25 for better code organization
//

import SwiftUI
import AppKit

// MARK: - Icon Manager

/**
 * Manages dynamic app icon changes based on selected color themes.
 *
 * This class handles:
 * - Mapping color themes to corresponding app icon variants
 * - Updating the app icon in the Dock and throughout macOS
 * - Providing icon preview functionality for preferences
 *
 * The IconManager uses a singleton pattern to ensure consistent
 * icon management across the application lifecycle.
 */
class IconManager: ObservableObject {
    /// Shared singleton instance
    static let shared = IconManager()

    /// Private initializer to enforce singleton pattern
    private init() {}

    // MARK: - Icon Mapping

    /**
     * Maps a ColorTheme to its corresponding app icon asset name.
     *
     * Each theme is associated with a specific icon variant that
     * matches the theme's color scheme. The tangerine theme uses
     * the default icon (nil return value).
     *
     * - Parameter theme: The color theme to map
     * - Returns: The icon asset name, or nil for the default icon
     */
    private func iconName(for theme: ColorTheme) -> String? {
        switch theme {
        case .blue, .teal, .system:
            return "AppIcon-blue"
        case .purple, .pink:
            return "AppIcon-pink"
        case .green:
            return "AppIcon-green"
        case .orange:
            return "AppIcon-yellow"
        case .red:
            return "AppIcon-red"
        case .indigo:
            return "AppIcon-purple"
        case .tangerine:
            return nil // Default icon (AppIcon)
        }
    }

    // MARK: - Icon Update Methods

    /**
     * Updates the app icon to match the selected theme.
     *
     * This method changes the app icon that appears in:
     * - The Dock
     * - The Applications folder
     * - Spotlight search results
     * - System dialogs and notifications
     *
     * The update is performed on the main queue to ensure UI consistency.
     *
     * - Parameter theme: The color theme to match with an icon
     */
    func updateIcon(for theme: ColorTheme) {
        let iconName = iconName(for: theme)

        // For macOS apps, we use NSApplication's applicationIconImage property
        // This changes the icon in the Dock and throughout the system
        DispatchQueue.main.async {
            self.setAppIcon(iconName: iconName)
        }
    }

    /**
     * Sets the application icon using the specified icon name.
     *
     * This method handles the actual icon loading and setting process,
     * including fallback to the default icon if the specified icon
     * cannot be loaded.
     *
     * - Parameter iconName: The name of the icon asset, or nil for default
     */
    private func setAppIcon(iconName: String?) {
        guard let iconName = iconName else {
            // Reset to default icon
            if let defaultIcon = NSImage(named: "AppIcon") {
                NSApplication.shared.applicationIconImage = defaultIcon
            }
            return
        }

        // Try to load the icon from the asset catalog
        if let iconImage = NSImage(named: iconName) {
            NSApplication.shared.applicationIconImage = iconImage
        } else {
            // Fallback to default icon if the themed icon is not found
            if let defaultIcon = NSImage(named: "AppIcon") {
                NSApplication.shared.applicationIconImage = defaultIcon
            }
        }
    }

    /**
     * Gets the icon asset name for the specified theme.
     *
     * This method provides the asset name that would be used for
     * the given theme, useful for UI previews and debugging.
     *
     * - Parameter theme: The color theme to query
     * - Returns: The icon asset name (defaults to "AppIcon" if no specific icon)
     */
    func getCurrentIconName(for theme: ColorTheme) -> String {
        return iconName(for: theme) ?? "AppIcon"
    }
}

// MARK: - Icon Preview Helper

/**
 * Extension providing icon preview functionality for UI components.
 *
 * This extension enables the preferences interface to show previews
 * of how the app icon will look with different themes.
 */
extension IconManager {
    /**
     * Creates a preview image for the specified theme.
     *
     * This method generates a resized version of the theme's icon
     * for display in the preferences interface. It handles fallback
     * to the default icon if the theme-specific icon is unavailable.
     *
     * - Parameters:
     *   - theme: The color theme to create a preview for
     *   - size: The desired size for the preview image (default: 64x64)
     * - Returns: A resized NSImage for preview, or nil if creation fails
     */
    func previewIcon(for theme: ColorTheme, size: CGSize = CGSize(width: 64, height: 64)) -> NSImage? {
        let iconName = iconName(for: theme) ?? "AppIcon"

        guard let baseImage = NSImage(named: iconName) else {
            return NSImage(named: "AppIcon")
        }

        // Create a new image with the specified size
        let resizedImage = NSImage(size: size)
        resizedImage.lockFocus()
        baseImage.draw(in: NSRect(origin: .zero, size: size))
        resizedImage.unlockFocus()

        return resizedImage
    }
}
