//
//  PlaylistNamePopup.swift
//  Strum
//
//  Created by leongo on 13/6/25.
//  Refactored on 14/6/25 for better code organization
//

import SwiftUI

// MARK: - Playlist Name Popup

/**
 * Modal popup for creating a new playlist when importing files.
 * 
 * This popup appears when users drag files into the app or select
 * files for import but need to create a new playlist to contain them.
 * 
 * Features:
 * - Text input for new playlist name
 * - Display of pending file count
 * - Themed visual design with music note icon
 * - Keyboard shortcuts (Enter to create, Escape to cancel)
 * - Input validation to prevent empty playlist names
 * - Smooth animations for appearance and dismissal
 * 
 * The popup provides context about the files waiting to be imported
 * and creates the playlist before proceeding with the import operation.
 */
struct PlaylistNamePopup: View {
    // MARK: - Properties
    
    /// Controls the visibility of the popup
    @Binding var isPresented: Bool
    
    /// Text input for the new playlist name
    @Binding var playlistName: String
    
    /// Array of file URLs waiting to be imported
    let pendingFiles: [URL]
    
    /// Callback function executed when the user creates the playlist
    let onSave: () -> Void
    
    /// Focus state for the text field to enable automatic focus
    @FocusState private var isTextFieldFocused: Bool
    
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
                // Header with theme styling
                VStack(spacing: DesignSystem.Spacing.md) {
                    Image(systemName: "music.note.list")
                        .font(.system(size: 48, weight: .medium))
                        .foregroundStyle(DesignSystem.colors(for: colorTheme).gradient)
                        .shadow(color: DesignSystem.colors(for: colorTheme).primary.opacity(0.3), radius: 6, x: 0, y: 3)

                    Text("Create New Playlist")
                        .font(DesignSystem.Typography.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)

                    Text("Enter a name for your new playlist")
                        .font(DesignSystem.Typography.callout)
                        .foregroundColor(.secondary)
                        .opacity(0.8)
                }

                // Text field with theme styling
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                    TextField("Playlist name", text: $playlistName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .font(DesignSystem.Typography.body)
                        .frame(width: 280)
                        .focused($isTextFieldFocused)
                        .onSubmit {
                            onSave()
                        }

                    // File count information
                    Text("\(pendingFiles.count) file\(pendingFiles.count == 1 ? "" : "s") ready to import")
                        .font(DesignSystem.Typography.caption)
                        .foregroundColor(.secondary)
                        .opacity(0.8)
                }

                // Themed buttons
                HStack(spacing: DesignSystem.Spacing.md) {
                    Button("Cancel") {
                        isPresented = false
                    }
                    .buttonStyle(SecondaryButtonStyle())
                    .keyboardShortcut(.escape)

                    Button("Create") {
                        onSave()
                    }
                    .buttonStyle(ThemedPrimaryButtonStyle(theme: colorTheme))
                    .keyboardShortcut(.return)
                    .disabled(playlistName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .padding(DesignSystem.Spacing.xxxl)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.xl)
                    .fill(.ultraThinMaterial)
                    .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
            )
            .frame(width: 320)
        }
        .onAppear {
            isTextFieldFocused = true
        }
        .transition(.asymmetric(
            insertion: .scale(scale: 0.8).combined(with: .opacity),
            removal: .scale(scale: 1.1).combined(with: .opacity)
        ))
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isPresented)
    }
}

// MARK: - Preview

#Preview {
    PlaylistNamePopup(
        isPresented: .constant(true),
        playlistName: .constant(""),
        pendingFiles: [
            URL(fileURLWithPath: "/path/to/song1.mp3"),
            URL(fileURLWithPath: "/path/to/song2.mp3"),
            URL(fileURLWithPath: "/path/to/song3.mp3")
        ],
        onSave: {}
    )
    .environment(\.colorTheme, .tangerine)
}
