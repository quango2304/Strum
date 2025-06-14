//
//  ProgressPopup.swift
//  Strum
//
//  Created by leongo on 13/6/25.
//  Refactored on 14/6/25 for better code organization
//

import SwiftUI

// MARK: - Progress Popup

/**
 * Modal popup displaying import progress for file operations.
 * 
 * This popup provides real-time feedback during long-running import operations:
 * - Visual progress bar with percentage completion
 * - Current file being processed
 * - File count progress (e.g., "5 of 20")
 * - Themed visual design with download icon
 * - Fixed dimensions to prevent layout shifts during updates
 * 
 * The popup appears automatically when import operations begin and
 * disappears when they complete. It cannot be dismissed by user interaction
 * to prevent interruption of the import process.
 * 
 * Design considerations:
 * - Uses ultra-thin material for native macOS appearance
 * - Fixed height container prevents text changes from causing layout shifts
 * - Monospaced digits for stable progress counter display
 * - Smooth animations for appearance and progress updates
 */
struct ProgressPopup: View {
    // MARK: - Properties
    
    /// Whether the progress popup should be visible
    let isShowing: Bool
    
    /// Progress value from 0.0 to 1.0
    let progress: Double
    
    /// Name of the file currently being processed
    let currentFile: String
    
    /// Total number of files to be imported
    let totalFiles: Int
    
    /// Number of files that have been processed so far
    let processedFiles: Int
    
    /// Current color theme from environment
    @Environment(\.colorTheme) private var colorTheme

    // MARK: - Body
    
    var body: some View {
        ZStack {
            // Native macOS-style transparent blur background
            Rectangle()
                .fill(.ultraThinMaterial)
                .opacity(0.3)
                .ignoresSafeArea()

            // Popup content with fixed height to prevent layout shifts
            VStack(spacing: DesignSystem.Spacing.xl) {
                // Icon and Title
                VStack(spacing: DesignSystem.Spacing.md) {
                    Image(systemName: "arrow.down.circle.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(DesignSystem.colors(for: colorTheme).gradient)

                    Text("Importing Files")
                        .font(DesignSystem.Typography.title2)
                        .foregroundColor(.primary)
                }

                // Progress information with fixed layout
                VStack(spacing: DesignSystem.Spacing.lg) {
                    // Progress bar section
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                        HStack {
                            Text("Progress")
                                .font(DesignSystem.Typography.caption)
                                .foregroundColor(.secondary)

                            Spacer()

                            Text("\(processedFiles) of \(totalFiles)")
                                .font(DesignSystem.Typography.caption)
                                .foregroundColor(.secondary)
                                .monospacedDigit() // Prevents width changes during updates
                        }

                        ProgressView(value: progress)
                            .progressViewStyle(LinearProgressViewStyle(tint: DesignSystem.colors(for: colorTheme).primary))
                            .scaleEffect(y: 1.5) // Make progress bar slightly thicker
                    }

                    // Current file section with fixed height
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                        Text("Current File")
                            .font(DesignSystem.Typography.caption)
                            .foregroundColor(.secondary)

                        // Fixed height container for current file text to prevent layout shifts
                        HStack {
                            Text(currentFile.isEmpty ? "Preparing..." : currentFile)
                                .font(DesignSystem.Typography.body)
                                .foregroundColor(.primary)
                                .lineLimit(1)
                                .truncationMode(.middle) // Show beginning and end of filename
                            Spacer()
                        }
                        .frame(height: 20) // Fixed height to prevent layout shifts
                    }
                }
            }
            .padding(DesignSystem.Spacing.xxxl)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xl)
                    .fill(.ultraThinMaterial)
                    .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
            )
            .frame(width: 380, height: 220) // Fixed dimensions to prevent size changes
        }
        .opacity(isShowing ? 1 : 0)
        .scaleEffect(isShowing ? 1 : 0.8)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isShowing)
    }
}

// MARK: - Preview

#Preview {
    ProgressPopup(
        isShowing: true,
        progress: 0.65,
        currentFile: "My Favorite Song - Artist Name.mp3",
        totalFiles: 20,
        processedFiles: 13
    )
    .environment(\.colorTheme, .tangerine)
}
