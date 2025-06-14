//
//  AddPlaylistPopup.swift
//  Strum
//
//  Created by leongo on 13/6/25.
//  Refactored on 14/6/25 for better code organization
//

import SwiftUI

// MARK: - Add Playlist Popup

/**
 * Modal popup for creating new playlists.
 * 
 * This popup provides:
 * - Text input for playlist name
 * - Themed visual design matching the current color scheme
 * - Keyboard shortcuts (Enter to save, Escape to cancel)
 * - Input validation to prevent empty playlist names
 * - Smooth animations for appearance and dismissal
 * 
 * The popup uses a blur background with ultra-thin material for
 * a native macOS appearance and automatically focuses the text field.
 */
struct AddPlaylistPopup: View {
    // MARK: - Properties
    
    /// Controls the visibility of the popup
    @Binding var isPresented: Bool
    
    /// Text input for the new playlist name
    @Binding var playlistName: String
    
    /// Callback function executed when the user saves the playlist
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
                // Icon and Title
                VStack(spacing: DesignSystem.Spacing.md) {
                    Image(systemName: "music.note.list")
                        .font(.system(size: 40))
                        .foregroundStyle(DesignSystem.colors(for: colorTheme).gradient)

                    Text("New Playlist")
                        .font(DesignSystem.Typography.title2)
                        .foregroundColor(.primary)
                }

                // Text field
                TextField("Playlist Name", text: $playlistName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .font(DesignSystem.Typography.body)
                    .focused($isTextFieldFocused)
                    .onSubmit {
                        onSave()
                    }

                // Buttons
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
        .onKeyPress(.escape) {
            isPresented = false
            return .handled
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
    AddPlaylistPopup(
        isPresented: .constant(true),
        playlistName: .constant(""),
        onSave: {}
    )
    .environment(\.colorTheme, .tangerine)
}
