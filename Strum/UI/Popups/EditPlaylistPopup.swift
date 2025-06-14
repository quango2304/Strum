//
//  EditPlaylistPopup.swift
//  Strum
//
//  Created by leongo on 13/6/25.
//  Refactored on 14/6/25 for better code organization
//

import SwiftUI

// MARK: - Edit Playlist Popup

/**
 * Modal popup for editing existing playlist names.
 * 
 * This popup provides:
 * - Pre-filled text input with the current playlist name
 * - Themed visual design with a pencil icon
 * - Keyboard shortcuts (Enter to save, Escape to cancel)
 * - Input validation to prevent empty playlist names
 * - Smooth animations for appearance and dismissal
 * 
 * The popup uses a blur background with ultra-thin material for
 * a native macOS appearance and automatically focuses the text field.
 */
struct EditPlaylistPopup: View {
    // MARK: - Properties
    
    /// Controls the visibility of the popup
    @Binding var isPresented: Bool
    
    /// Text input for the playlist name (pre-filled with current name)
    @Binding var playlistName: String
    
    /// The playlist being edited (for context)
    let playlist: Playlist
    
    /// Callback function executed when the user saves the changes
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
                // Header with themed styling
                VStack(spacing: DesignSystem.Spacing.md) {
                    // Themed pencil icon with gradient background
                    ZStack {
                        // Gradient circle background
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: colorTheme.gradientColors,
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: 48, height: 48)
                            .shadow(color: DesignSystem.colors(for: colorTheme).primary.opacity(0.3), radius: 6, x: 0, y: 3)

                        // White pencil icon on top
                        Image(systemName: "pencil")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(.white)
                    }

                    Text("Edit Playlist")
                        .font(DesignSystem.Typography.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)

                    Text("Enter a new name for your playlist")
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
                }

                // Themed buttons
                HStack(spacing: DesignSystem.Spacing.md) {
                    Button("Cancel") {
                        isPresented = false
                    }
                    .buttonStyle(SecondaryButtonStyle())
                    .keyboardShortcut(.escape)

                    Button("Save") {
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
    EditPlaylistPopup(
        isPresented: .constant(true),
        playlistName: .constant("My Playlist"),
        playlist: Playlist(name: "My Playlist"),
        onSave: {}
    )
    .environment(\.colorTheme, .tangerine)
}
