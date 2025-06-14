//
//  AboutView.swift
//  Strum
//
//  Created by Quan Ngo on 12/6/25.
//

import SwiftUI

struct AboutView: View {
    @Binding var isPresented: Bool
    @Environment(\.colorTheme) private var colorTheme
    
    var body: some View {
        ZStack {
            // Native macOS-style transparent blur background
            Rectangle()
                .fill(.thinMaterial)
                .opacity(0.3)
                .ignoresSafeArea()
                .onTapGesture {
                    isPresented = false
                }
            
            // Main content
            VStack(spacing: DesignSystem.Spacing.xl) {
                // App Info Section (Combined App + Author)
                VStack(spacing: DesignSystem.Spacing.lg) {
                    // App Icon
                    Image(systemName: "music.note")
                        .font(.system(size: 64, weight: .light))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    colorTheme.primaryColor.opacity(0.3),
                                    colorTheme.primaryColor
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    // App Name
                    Text("Strum")
                        .font(.system(size: 32, weight: .light, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    colorTheme.primaryColor.opacity(0.3),
                                    colorTheme.primaryColor
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    // Version and Author in same section
                    VStack(spacing: DesignSystem.Spacing.sm) {
                        Text("Version 1.0")
                            .font(DesignSystem.Typography.body)
                            .foregroundColor(.secondary)

                        HStack(spacing: DesignSystem.Spacing.xs) {
                            Image(systemName: "person.circle.fill")
                                .foregroundColor(colorTheme.primaryColor)
                                .font(.system(size: 14))

                            Text("by Quan Ngo")
                                .font(DesignSystem.Typography.body)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                // Supported File Types Section
                VStack(spacing: DesignSystem.Spacing.md) {
                    HStack {
                        Image(systemName: "doc.audio.fill")
                            .foregroundColor(colorTheme.primaryColor)
                            .font(.system(size: 18))
                        
                        Text("Supported Audio Formats")
                            .font(DesignSystem.Typography.headline)
                            .foregroundColor(.primary)
                    }
                    
                    // File types in a beautiful grid
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: DesignSystem.Spacing.sm) {
                        ForEach(supportedFileTypes, id: \.self) { fileType in
                            Text(fileType)
                                .font(.system(size: 12, weight: .medium, design: .monospaced))
                                .padding(.horizontal, DesignSystem.Spacing.sm)
                                .padding(.vertical, DesignSystem.Spacing.xs)
                                .background(
                                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.sm)
                                        .fill(colorTheme.primaryColor.opacity(0.1))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.sm)
                                                .stroke(colorTheme.primaryColor.opacity(0.3), lineWidth: 1)
                                        )
                                )
                                .foregroundColor(colorTheme.primaryColor)
                        }
                    }
                }
                
                // Features Section
                VStack(spacing: DesignSystem.Spacing.md) {
                    HStack {
                        Image(systemName: "star.fill")
                            .foregroundColor(colorTheme.primaryColor)
                            .font(.system(size: 18))
                        
                        Text("Key Features")
                            .font(DesignSystem.Typography.headline)
                            .foregroundColor(.primary)
                    }
                    
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                        ForEach(keyFeatures, id: \.self) { feature in
                            HStack(alignment: .top, spacing: DesignSystem.Spacing.sm) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(colorTheme.primaryColor)
                                    .font(.system(size: 12))
                                    .padding(.top, 2)
                                
                                Text(feature)
                                    .font(.system(size: 13))
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.leading)
                                
                                Spacer()
                            }
                        }
                    }
                }
                
                // Close Button
                Button("Close") {
                    isPresented = false
                }
                .buttonStyle(ThemedPrimaryButtonStyle(theme: colorTheme))
                .keyboardShortcut(.escape)
            }
            .padding(DesignSystem.Spacing.xxxl)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xl)
                    .fill(.ultraThinMaterial)
                    .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
            )
            .frame(width: 480)
        }
        .transition(.asymmetric(
            insertion: .scale(scale: 0.9).combined(with: .opacity),
            removal: .scale(scale: 1.1).combined(with: .opacity)
        ))
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isPresented)
    }
    
    // MARK: - Data
    private let supportedFileTypes = [
        "MP3", "M4A", "WAV", "FLAC",
        "AAC", "OGG", "WMA", "AIFF"
    ]
    
    private let keyFeatures = [
        "Color Themes",
        "Playlist Management & Organization",
        "Drag & Drop File Import",
        "Keyboard Shortcuts Support",
        "Responsive Design",
        "Search & Filter Tracks"
    ]
}

#Preview {
    AboutView(isPresented: .constant(true))
        .environment(\.colorTheme, .tangerine)
}
