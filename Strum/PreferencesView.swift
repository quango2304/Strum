//
//  PreferencesView.swift
//  Strum
//
//  Created by leongo on 13/6/25.
//

import SwiftUI

struct PreferencesView: View {
    @ObservedObject var preferencesManager: PreferencesManager
    
    var body: some View {
        ZStack {
            // Native macOS-style transparent blur background
            Rectangle()
                .fill(.thinMaterial)
                .opacity(0.3)
                .ignoresSafeArea()
                .onTapGesture {
                    preferencesManager.showPreferences = false
                }

            // Main content
            VStack(spacing: DesignSystem.Spacing.xl) {
                // Header
                HStack {
                    Text("Preferences")
                        .font(DesignSystem.Typography.title)
                        .foregroundColor(.primary)

                    Spacer()

                    Button(action: {
                        preferencesManager.showPreferences = false
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                            .font(.system(size: 20))
                    }
                    .buttonStyle(PlainButtonStyle())
                    .help("Close")
                }

                // Appearance Section
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
                    HStack {
                        Image(systemName: "paintbrush.fill")
                            .foregroundColor(preferencesManager.colorTheme.primaryColor)
                            .font(.system(size: 18))

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
                }

                // Preview Section
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
                    HStack {
                        Image(systemName: "eye.fill")
                            .foregroundColor(preferencesManager.colorTheme.primaryColor)
                            .font(.system(size: 18))

                        Text("Preview")
                            .font(DesignSystem.Typography.headline)
                            .foregroundColor(.primary)
                    }

                    ThemePreview(theme: preferencesManager.colorTheme)
                }
            }
            .padding(DesignSystem.Spacing.xxxl)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xl)
                    .fill(.ultraThinMaterial)
                    .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
            )
            .frame(width: 480, height: 520)
        }
        .onKeyPress(.escape) {
            preferencesManager.showPreferences = false
            return .handled
        }
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
                    .frame(width: 36, height: 36)
                    .overlay(
                        Circle()
                            .stroke(isSelected ? Color.primary : Color.clear, lineWidth: 2.5)
                    )
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.8), lineWidth: 1.5)
                    )
                    .shadow(color: DesignSystem.Shadow.medium, radius: 3, x: 0, y: 2)

                // Theme name
                Text(theme.displayName)
                    .font(.system(size: 10, weight: .medium))
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
                        .frame(width: 16, height: 16)
                        .shadow(color: DesignSystem.Shadow.light, radius: 2, x: 0, y: 1)
                }
            }
        }
        .padding(DesignSystem.Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
        )
    }
}

#Preview {
    PreferencesView(preferencesManager: PreferencesManager())
}
