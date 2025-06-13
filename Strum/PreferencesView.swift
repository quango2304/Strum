//
//  PreferencesView.swift
//  Strum
//
//  Created by leongo on 13/6/25.
//

import SwiftUI

struct PreferencesView: View {
    @ObservedObject var preferencesManager: PreferencesManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Preferences")
                    .font(DesignSystem.Typography.title)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                        .font(.system(size: 20))
                }
                .buttonStyle(PlainButtonStyle())
                .help("Close")
            }
            .padding(DesignSystem.Spacing.xl)
            .background(
                ZStack {
                    Rectangle()
                        .fill(DesignSystem.colors(for: preferencesManager.colorTheme).surface)
                        .shadow(color: DesignSystem.Shadow.light, radius: 1, x: 0, y: 1)
                    preferencesManager.colorTheme.surfaceTint
                }
            )
            
            // Content
            ScrollView {
                VStack(spacing: DesignSystem.Spacing.xxl) {
                    // Appearance Section
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
                        HStack {
                            Image(systemName: "paintbrush.fill")
                                .foregroundColor(preferencesManager.colorTheme.primaryColor)
                                .font(.system(size: 20))
                            
                            Text("Appearance")
                                .font(DesignSystem.Typography.headline)
                                .foregroundColor(.primary)
                        }
                        
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                            Text("Color Theme")
                                .font(DesignSystem.Typography.callout)
                                .foregroundColor(.secondary)
                            
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: DesignSystem.Spacing.md), count: 5), spacing: DesignSystem.Spacing.md) {
                                ForEach(ColorTheme.allCases) { theme in
                                    ThemeColorButton(
                                        theme: theme,
                                        isSelected: preferencesManager.colorTheme == theme,
                                        action: {
                                            withAnimation(.easeInOut(duration: 0.2)) {
                                                preferencesManager.colorTheme = theme
                                            }
                                        }
                                    )
                                }
                            }
                        }
                        .cardStyle()
                    }
                    
                    // Preview Section
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
                        HStack {
                            Image(systemName: "eye.fill")
                                .foregroundColor(preferencesManager.colorTheme.primaryColor)
                                .font(.system(size: 20))
                            
                            Text("Preview")
                                .font(DesignSystem.Typography.headline)
                                .foregroundColor(.primary)
                        }
                        
                        ThemePreview(theme: preferencesManager.colorTheme)
                            .cardStyle()
                    }
                    
                    // Reset Section
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
                        HStack {
                            Image(systemName: "arrow.clockwise")
                                .foregroundColor(.secondary)
                                .font(.system(size: 20))
                            
                            Text("Reset")
                                .font(DesignSystem.Typography.headline)
                                .foregroundColor(.primary)
                        }
                        
                        HStack {
                            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                                Text("Reset to Defaults")
                                    .font(DesignSystem.Typography.body)
                                    .foregroundColor(.primary)
                                
                                Text("Restore all settings to their default values")
                                    .font(DesignSystem.Typography.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Button("Reset") {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    preferencesManager.resetToDefaults()
                                }
                            }
                            .buttonStyle(SecondaryButtonStyle())
                        }
                        .cardStyle()
                    }
                }
                .padding(DesignSystem.Spacing.xl)
            }
        }
        .frame(width: 500, height: 600)
        .background(
            ZStack {
                DesignSystem.colors(for: preferencesManager.colorTheme).background
                preferencesManager.colorTheme.backgroundTint
            }
        )
    }
}

// MARK: - Theme Color Button
struct ThemeColorButton: View {
    let theme: ColorTheme
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: DesignSystem.Spacing.sm) {
                // Color circle
                Circle()
                    .fill(
                        LinearGradient(
                            colors: theme.gradientColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 40, height: 40)
                    .overlay(
                        Circle()
                            .stroke(isSelected ? Color.primary : Color.clear, lineWidth: 3)
                    )
                    .overlay(
                        Circle()
                            .stroke(Color.white, lineWidth: 2)
                    )
                    .shadow(color: DesignSystem.Shadow.medium, radius: 4, x: 0, y: 2)
                
                // Theme name
                Text(theme.displayName)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(isSelected ? theme.primaryColor : .secondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

// MARK: - Theme Preview
struct ThemePreview: View {
    let theme: ColorTheme
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            Text("Theme Preview")
                .font(DesignSystem.Typography.headline)
                .foregroundColor(.primary)
            
            // Mock player controls
            HStack(spacing: DesignSystem.Spacing.lg) {
                // Previous button
                Button(action: {}) {
                    Image(systemName: "backward.fill")
                        .foregroundColor(.primary)
                }
                .buttonStyle(ThemedIconButtonStyle(size: 32, theme: theme))
                
                // Play button
                Button(action: {}) {
                    Image(systemName: "play.fill")
                        .foregroundColor(.white)
                }
                .buttonStyle(ThemedIconButtonStyle(size: 44, isActive: true, theme: theme))
                
                // Next button
                Button(action: {}) {
                    Image(systemName: "forward.fill")
                        .foregroundColor(.primary)
                }
                .buttonStyle(ThemedIconButtonStyle(size: 32, theme: theme))
            }
            
            // Mock buttons
            HStack(spacing: DesignSystem.Spacing.md) {
                Button("Primary") {}
                    .buttonStyle(ThemedPrimaryButtonStyle(theme: theme))
                
                Button("Secondary") {}
                    .buttonStyle(SecondaryButtonStyle())
            }
            
            // Color swatches
            HStack(spacing: DesignSystem.Spacing.sm) {
                ForEach(theme.gradientColors.indices, id: \.self) { index in
                    Circle()
                        .fill(theme.gradientColors[index])
                        .frame(width: 20, height: 20)
                }
            }
        }
        .padding(DesignSystem.Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                .fill(DesignSystem.Colors.surfaceSecondary)
        )
    }
}

#Preview {
    PreferencesView(preferencesManager: PreferencesManager())
}
