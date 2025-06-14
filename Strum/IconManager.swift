//
//  IconManager.swift
//  Strum
//
//  Created by leongo on 14/6/25.
//

import SwiftUI
import AppKit

// MARK: - Icon Manager
class IconManager: ObservableObject {
    static let shared = IconManager()
    
    private init() {}
    
    /// Maps ColorTheme to the corresponding alternate icon name
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
    
    /// Changes the app icon based on the selected theme
    func updateIcon(for theme: ColorTheme) {
        let iconName = iconName(for: theme)

        // For macOS apps, we use NSApplication's applicationIconImage property
        // This changes the icon in the Dock and throughout the system
        DispatchQueue.main.async {
            self.setAppIcon(iconName: iconName)
        }
    }
    
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
            // Fallback to default icon
            if let defaultIcon = NSImage(named: "AppIcon") {
                NSApplication.shared.applicationIconImage = defaultIcon
            }
        }
    }
    
    /// Gets the current icon name for the given theme
    func getCurrentIconName(for theme: ColorTheme) -> String {
        return iconName(for: theme) ?? "AppIcon"
    }
}

// MARK: - Icon Preview Helper
extension IconManager {
    /// Creates a preview image for the given theme (for use in preferences)
    func previewIcon(for theme: ColorTheme, size: CGSize = CGSize(width: 64, height: 64)) -> NSImage? {
        let iconName = iconName(for: theme) ?? "AppIcon"
        
        guard let baseImage = NSImage(named: iconName) else {
            return NSImage(named: "AppIcon")
        }
        
        let resizedImage = NSImage(size: size)
        resizedImage.lockFocus()
        baseImage.draw(in: NSRect(origin: .zero, size: size))
        resizedImage.unlockFocus()
        
        return resizedImage
    }
}
