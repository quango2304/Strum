//
//  ImportPopup.swift
//  Strum
//
//  Created by leongo on 13/6/25.
//  Refactored on 14/6/25 for better code organization
//

import SwiftUI

// MARK: - Import Popup

/**
 * Modal popup for selecting music import options.
 * 
 * This popup provides:
 * - Two import options: individual files or entire folders
 * - Themed visual design with music note icon
 * - Clear descriptions for each import method
 * - Keyboard shortcuts (Enter for files, Escape to cancel)
 * - Integration with PlaylistManager for import operations
 * 
 * The popup displays the target playlist name and provides
 * intuitive options for adding music content.
 */
struct ImportPopup: View {
    // MARK: - Properties
    
    /// Controls the visibility of the popup
    @Binding var isPresented: Bool
    
    /// The playlist to import music into
    let playlist: Playlist
    
    /// Playlist manager for handling import operations
    let playlistManager: PlaylistManager
    
    /// Current color theme from environment
    @Environment(\.colorTheme) private var colorTheme

    // MARK: - Body
    
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

            // Popup content
            VStack(spacing: DesignSystem.Spacing.xl) {
                // Icon and Title
                VStack(spacing: DesignSystem.Spacing.lg) {
                    // Music icon with theme gradient
                    Image(systemName: "music.note.list")
                        .font(.system(size: 48, weight: .medium))
                        .foregroundStyle(DesignSystem.colors(for: colorTheme).gradient)
                        .shadow(color: DesignSystem.colors(for: colorTheme).primary.opacity(0.3), radius: 6, x: 0, y: 3)

                    // Title
                    Text("Add Music")
                        .font(DesignSystem.Typography.title)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)

                    // Subtitle showing target playlist
                    Text("to \"\(playlist.name)\"")
                        .font(DesignSystem.Typography.title2)
                        .foregroundColor(.secondary)
                }

                // Action buttons with theme styling
                VStack(spacing: DesignSystem.Spacing.lg) {
                    // Import Files button
                    Button(action: {
                        playlistManager.selectPlaylist(playlist)
                        playlistManager.importFiles()
                        isPresented = false
                    }) {
                        HStack(spacing: DesignSystem.Spacing.md) {
                            Image(systemName: "doc.badge.plus")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(DesignSystem.colors(for: colorTheme).primary)

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Import Files")
                                    .font(DesignSystem.Typography.headline)
                                    .foregroundColor(.primary)
                                Text("Select individual music files")
                                    .font(DesignSystem.Typography.caption)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, DesignSystem.Spacing.xl)
                        .padding(.vertical, DesignSystem.Spacing.lg)
                        .background(
                            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                                .fill(DesignSystem.colors(for: colorTheme).primary.opacity(0.08))
                                .stroke(DesignSystem.colors(for: colorTheme).primary.opacity(0.2), lineWidth: 1)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    .keyboardShortcut(.return)

                    // Import Folder button
                    Button(action: {
                        playlistManager.selectPlaylist(playlist)
                        playlistManager.importFolder()
                        isPresented = false
                    }) {
                        HStack(spacing: DesignSystem.Spacing.md) {
                            Image(systemName: "folder.badge.plus")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(DesignSystem.colors(for: colorTheme).primary)

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Import Folder")
                                    .font(DesignSystem.Typography.headline)
                                    .foregroundColor(.primary)
                                Text("Select an entire music folder")
                                    .font(DesignSystem.Typography.caption)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, DesignSystem.Spacing.xl)
                        .padding(.vertical, DesignSystem.Spacing.lg)
                        .background(
                            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                                .fill(DesignSystem.colors(for: colorTheme).primary.opacity(0.08))
                                .stroke(DesignSystem.colors(for: colorTheme).primary.opacity(0.2), lineWidth: 1)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }

                // Cancel button
                Button("Cancel") {
                    isPresented = false
                }
                .keyboardShortcut(.escape)
                .buttonStyle(.plain)
                .foregroundColor(.secondary)
            }
            .padding(DesignSystem.Spacing.xxxl)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xl)
                    .fill(.ultraThinMaterial)
                    .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
            )
            .frame(width: 380)
        }
        .onKeyPress(.escape) {
            isPresented = false
            return .handled
        }
    }
}

// MARK: - Preview

#Preview {
    ImportPopup(
        isPresented: .constant(true),
        playlist: Playlist(name: "My Music"),
        playlistManager: PlaylistManager()
    )
    .environment(\.colorTheme, .tangerine)
}
