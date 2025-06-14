//
//  ContentView.swift
//  Strum
//
//  Created by leongo on 13/6/25.
//  Refactored on 14/6/25 for better code organization
//

import SwiftUI
import AppKit

// MARK: - Content View

/**
 * Main content view for the Strum music player application.
 *
 * This view serves as the primary interface and handles:
 * - Responsive layout switching between desktop and compact modes
 * - Playlist management UI coordination
 * - Popup and modal management (preferences, about, import dialogs)
 * - Toast notification display
 * - Global keyboard shortcuts and ESC key handling
 * - Integration between playlist management and music playback
 *
 * The ContentView adapts its layout based on window size, providing
 * an optimal experience across different screen sizes and orientations.
 */
struct ContentView: View {
    // MARK: - Environment Objects

    /// Manages playlist data and operations
    @EnvironmentObject private var playlistManager: PlaylistManager

    /// Manages music playback functionality
    @StateObject private var musicPlayer = MusicPlayerManager()

    /// Manages app preferences and settings
    @EnvironmentObject private var preferencesManager: PreferencesManager

    /// Current color theme from environment
    @Environment(\.colorTheme) private var colorTheme

    // MARK: - Popup State Management

    /// Controls visibility of the add playlist popup
    @State private var showingAddPlaylistPopup = false

    /// Text input for new playlist name
    @State private var newPlaylistName = ""

    /// Controls visibility of the edit playlist popup
    @State private var showingEditPlaylistPopup = false

    /// Text input for editing playlist name
    @State private var editPlaylistName = ""

    /// Currently selected playlist for editing
    @State private var selectedPlaylistForEdit: Playlist?

    /// Controls visibility of the import options popup
    @State private var showingImportPopup = false

    /// Currently selected playlist for importing files
    @State private var selectedPlaylistForImport: Playlist?

    /// Controls visibility of the playlist name input popup for file imports
    @State private var showingPlaylistNamePopup = false

    /// Text input for new playlist name when importing files
    @State private var playlistNameForFiles = ""

    /// Array of file URLs pending import into a new playlist
    @State private var pendingFiles: [URL] = []

    // MARK: - Toast Notification State

    /// Controls visibility of toast notifications
    @State private var showingToast = false

    /// Message text for toast notifications
    @State private var toastMessage = ""

    /// Type of toast notification (success, error, etc.)
    @State private var toastType: ToastView.ToastType = .success

    // MARK: - Animation and Focus State

    /// Triggers animations for empty state view
    @State private var animationTrigger = false

    /// Tracks focus state of search fields across the interface
    @FocusState private var isSearchFieldFocused: Bool

    // MARK: - Layout Constants

    /// Responsive breakpoint - switches to compact layout when width < 1000px
    private let responsiveBreakpoint: CGFloat = 1000

    // MARK: - Computed Properties

    /**
     * Gradient for title text using current theme colors.
     *
     * Creates a horizontal gradient from the theme's gradient colors
     * for use in headings and prominent text elements.
     */
    private var titleGradient: LinearGradient {
        LinearGradient(
            colors: colorTheme.gradientColors,
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    /**
     * Themed color palette for the current color theme.
     *
     * Provides access to the complete set of themed colors
     * including backgrounds, surfaces, and accent colors.
     */
    private var themedColors: DesignSystem.ThemedColors {
        DesignSystem.colors(for: colorTheme)
    }

    var body: some View {
        GeometryReader { geometry in
            let isCompact = geometry.size.width < responsiveBreakpoint

            mainContentView(isCompact: isCompact)
        }
        .frame(minWidth: 500, minHeight: 700) // Ensure desktop mode by default
        .background(
            ZStack {
                DesignSystem.colors(for: colorTheme).background
                colorTheme.backgroundTint
            }
        )
        .overlay(
            // Toast notification overlay
            Group {
                if showingToast {
                    ToastView(message: toastMessage, type: toastType, isShowing: $showingToast)
                        .zIndex(1000)
                        .padding(.top, DesignSystem.Spacing.lg)
                }
            },
            alignment: .top
        )
        .onAppear {
            // Set up toast callback for import success
            playlistManager.onImportSuccess = { message in
                toastMessage = message
                toastType = .success
                showingToast = true
            }
        }

        .overlay(aboutPopupOverlay)
        .overlay(preferencesPopupOverlay)
        .overlay(addPlaylistPopupOverlay)
        .overlay(editPlaylistPopupOverlay)
        .overlay(
            // Import Popup - Centered in entire app window
            Group {
                if showingImportPopup, let selectedPlaylist = selectedPlaylistForImport {
                    ImportPopup(
                        isPresented: $showingImportPopup,
                        playlist: selectedPlaylist,
                        playlistManager: playlistManager
                    )
                }
            }
        )
        .overlay(
            // Playlist Name Popup for Files - Centered in entire app window
            Group {
                if showingPlaylistNamePopup {
                    PlaylistNamePopup(
                        isPresented: $showingPlaylistNamePopup,
                        playlistName: $playlistNameForFiles,
                        pendingFiles: pendingFiles,
                        onSave: {
                            guard !playlistNameForFiles.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                                return
                            }

                            let newPlaylist = playlistManager.createPlaylist(name: playlistNameForFiles.trimmingCharacters(in: .whitespacesAndNewlines))
                            playlistManager.selectPlaylist(newPlaylist)

                            // Add all pending files to the new playlist
                            for fileUrl in pendingFiles {
                                let track = Track(url: fileUrl)
                                newPlaylist.addTrack(track)
                            }

                            // Save the playlists to persist the changes
                            playlistManager.savePlaylists()

                            // Show success toast
                            let fileCount = pendingFiles.count
                            toastMessage = fileCount == 1 ? "1 file imported successfully" : "\(fileCount) files imported successfully"
                            toastType = .success
                            showingToast = true

                            // Clear state and close popup
                            pendingFiles = []
                            showingPlaylistNamePopup = false
                            playlistNameForFiles = ""
                        }
                    )
                }
            }
        )
        .overlay(
            // Progress Popup - Centered in entire app window
            ProgressPopup(
                isShowing: playlistManager.isImporting,
                progress: playlistManager.importProgress,
                currentFile: playlistManager.importCurrentFile,
                totalFiles: playlistManager.importTotalFiles,
                processedFiles: playlistManager.importProcessedFiles
            )
        )
        .onKeyPress(.escape) {
            // Global ESC key handling to close any open popup
            if preferencesManager.showAbout {
                preferencesManager.showAbout = false
                return .handled
            }
            if showingAddPlaylistPopup {
                showingAddPlaylistPopup = false
                return .handled
            }
            if showingEditPlaylistPopup {
                showingEditPlaylistPopup = false
                return .handled
            }
            if showingImportPopup {
                showingImportPopup = false
                return .handled
            }
            if showingPlaylistNamePopup {
                showingPlaylistNamePopup = false
                return .handled
            }
            if preferencesManager.showPreferences {
                preferencesManager.showPreferences = false
                return .handled
            }
            return .ignored
        }
    }

    // MARK: - View Components
    @ViewBuilder
    private func mainContentView(isCompact: Bool) -> some View {
        VStack(spacing: 0) {
            // Main Content Area - Responsive Layout
            if isCompact {
                compactLayout()
            } else {
                desktopLayout()
            }

            // Player Controls - Only for desktop layout (compact has its own)
            if !isCompact {
                PlayerControlsView(musicPlayer: musicPlayer, playlistManager: playlistManager, isSearchFieldFocused: $isSearchFieldFocused, isCompact: isCompact)
            }
        }
        .frame(minWidth: 500, minHeight: 700)
        .background(backgroundView)
        .onAppear(perform: setupToastCallback)

        .overlay(addPlaylistPopupOverlay)
        .overlay(importPopupOverlay)
        .overlay(playlistNamePopupOverlay)
        .onKeyPress(.escape) {
            // Global ESC key handling to close any open popup
            if showingAddPlaylistPopup {
                showingAddPlaylistPopup = false
                return .handled
            }
            if showingEditPlaylistPopup {
                showingEditPlaylistPopup = false
                return .handled
            }
            if showingImportPopup {
                showingImportPopup = false
                return .handled
            }
            if showingPlaylistNamePopup {
                showingPlaylistNamePopup = false
                return .handled
            }
            if preferencesManager.showPreferences {
                preferencesManager.showPreferences = false
                return .handled
            }
            return .ignored
        }
    }

    @ViewBuilder
    private func compactLayout() -> some View {
        VStack(spacing: 0) {
            // Main Content (Track List) - takes available space above player controls
            if let selectedPlaylist = playlistManager.selectedPlaylist {
                TrackListView(playlist: selectedPlaylist, musicPlayer: musicPlayer, isSearchFieldFocused: $isSearchFieldFocused)
                    .environmentObject(playlistManager)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                emptyStateView(isCompact: true)
            }

            // Player Controls - Always visible and not cut off
            PlayerControlsView(musicPlayer: musicPlayer, playlistManager: playlistManager, isSearchFieldFocused: $isSearchFieldFocused, isCompact: true)

            // Playlist Sidebar (at bottom in compact mode)
            compactSidebar()
        }
    }

    @ViewBuilder
    private func desktopLayout() -> some View {
        HStack(spacing: 0) {
            // Sidebar
            desktopSidebar()

            Divider()

            // Main Content
            if let selectedPlaylist = playlistManager.selectedPlaylist {
                TrackListView(playlist: selectedPlaylist, musicPlayer: musicPlayer, isSearchFieldFocused: $isSearchFieldFocused)
                    .environmentObject(playlistManager)
            } else {
                emptyStateView(isCompact: false)
            }
        }
    }

    @ViewBuilder
    private func emptyStateView(isCompact: Bool) -> some View {
        VStack(spacing: DesignSystem.Spacing.xl) {
            Spacer()

            Image(systemName: "music.note.list")
                .font(.system(size: isCompact ? 56 : 72, weight: .light))
                .foregroundStyle(themedColors.gradient)
                .shadow(color: themedColors.primary.opacity(0.3), radius: isCompact ? 6 : 8, x: 0, y: isCompact ? 3 : 4)
                .scaleEffect(animationTrigger ? 1.05 : 1.0)
                .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: animationTrigger)

            VStack(spacing: isCompact ? DesignSystem.Spacing.sm : DesignSystem.Spacing.md) {
                Text("Select a Playlist")
                    .font(isCompact ? DesignSystem.Typography.title2 : DesignSystem.Typography.title)
                    .fontWeight(.bold)
                    .foregroundStyle(titleGradient)

                Text("Choose a playlist from the sidebar to view its tracks")
                    .font(isCompact ? DesignSystem.Typography.callout : DesignSystem.Typography.headline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .opacity(0.8)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            animationTrigger = true
        }
    }

    @ViewBuilder
    private func compactSidebar() -> some View {
        PlaylistSidebar(
            playlistManager: playlistManager,
            showingAddPlaylistPopup: $showingAddPlaylistPopup,
            newPlaylistName: $newPlaylistName,
            showingEditPlaylistPopup: $showingEditPlaylistPopup,
            editPlaylistName: $editPlaylistName,
            selectedPlaylistForEdit: $selectedPlaylistForEdit,
            showingImportPopup: $showingImportPopup,
            selectedPlaylistForImport: $selectedPlaylistForImport,
            showingPlaylistNamePopup: $showingPlaylistNamePopup,
            playlistNameForFiles: $playlistNameForFiles,
            pendingFiles: $pendingFiles,
            isSearchFieldFocused: $isSearchFieldFocused,
            isCompact: true
        )
        .frame(height: 180)
    }

    @ViewBuilder
    private func desktopSidebar() -> some View {
        PlaylistSidebar(
            playlistManager: playlistManager,
            showingAddPlaylistPopup: $showingAddPlaylistPopup,
            newPlaylistName: $newPlaylistName,
            showingEditPlaylistPopup: $showingEditPlaylistPopup,
            editPlaylistName: $editPlaylistName,
            selectedPlaylistForEdit: $selectedPlaylistForEdit,
            showingImportPopup: $showingImportPopup,
            selectedPlaylistForImport: $selectedPlaylistForImport,
            showingPlaylistNamePopup: $showingPlaylistNamePopup,
            playlistNameForFiles: $playlistNameForFiles,
            pendingFiles: $pendingFiles,
            isSearchFieldFocused: $isSearchFieldFocused,
            isCompact: false
        )
    }

    // MARK: - Helper Views
    @ViewBuilder
    private var backgroundView: some View {
        ZStack {
            themedColors.background
            colorTheme.backgroundTint
        }
    }

    private func setupToastCallback() {
        playlistManager.onImportSuccess = { message in
            toastMessage = message
            toastType = .success
            showingToast = true
        }
    }

    @ViewBuilder
    private var addPlaylistPopupOverlay: some View {
        Group {
            if showingAddPlaylistPopup {
                AddPlaylistPopup(
                    isPresented: $showingAddPlaylistPopup,
                    playlistName: $newPlaylistName,
                    onSave: {
                        if !newPlaylistName.isEmpty {
                            _ = playlistManager.createPlaylist(name: newPlaylistName)
                            newPlaylistName = ""
                            showingAddPlaylistPopup = false

                            // Show success toast
                            toastMessage = "Playlist created successfully"
                            toastType = .success
                            showingToast = true
                        }
                    }
                )
            }
        }
    }

    @ViewBuilder
    private var editPlaylistPopupOverlay: some View {
        Group {
            if showingEditPlaylistPopup, let selectedPlaylist = selectedPlaylistForEdit {
                EditPlaylistPopup(
                    isPresented: $showingEditPlaylistPopup,
                    playlistName: $editPlaylistName,
                    playlist: selectedPlaylist,
                    onSave: {
                        if !editPlaylistName.isEmpty {
                            playlistManager.renamePlaylist(selectedPlaylist, to: editPlaylistName)
                            editPlaylistName = ""
                            selectedPlaylistForEdit = nil
                            showingEditPlaylistPopup = false

                            // Show success toast
                            toastMessage = "Playlist renamed successfully"
                            toastType = .success
                            showingToast = true
                        }
                    }
                )
            }
        }
    }

    @ViewBuilder
    private var importPopupOverlay: some View {
        Group {
            if showingImportPopup, let selectedPlaylist = selectedPlaylistForImport {
                ImportPopup(
                    isPresented: $showingImportPopup,
                    playlist: selectedPlaylist,
                    playlistManager: playlistManager
                )
            }
        }
    }

    @ViewBuilder
    private var playlistNamePopupOverlay: some View {
        Group {
            if showingPlaylistNamePopup {
                PlaylistNamePopup(
                    isPresented: $showingPlaylistNamePopup,
                    playlistName: $playlistNameForFiles,
                    pendingFiles: pendingFiles,
                    onSave: playlistNamePopupSaveAction
                )
            }
        }
    }

    @ViewBuilder
    private var aboutPopupOverlay: some View {
        Group {
            if preferencesManager.showAbout {
                AboutView(isPresented: $preferencesManager.showAbout)
            }
        }
    }

    @ViewBuilder
    private var preferencesPopupOverlay: some View {
        Group {
            if preferencesManager.showPreferences {
                PreferencesView(preferencesManager: preferencesManager)
            }
        }
    }

    private func playlistNamePopupSaveAction() {
        guard !playlistNameForFiles.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }

        let newPlaylist = playlistManager.createPlaylist(name: playlistNameForFiles.trimmingCharacters(in: .whitespacesAndNewlines))
        playlistManager.selectPlaylist(newPlaylist)

        // Add all pending files to the new playlist
        for fileUrl in pendingFiles {
            let track = Track(url: fileUrl)
            newPlaylist.addTrack(track)
        }

        // Save the playlists to persist the changes
        playlistManager.savePlaylists()

        // Show success toast
        let fileCount = pendingFiles.count
        toastMessage = fileCount == 1 ? "1 file imported successfully" : "\(fileCount) files imported successfully"
        toastType = .success
        showingToast = true

        // Clear state and close popup
        pendingFiles = []
        showingPlaylistNamePopup = false
        playlistNameForFiles = ""
    }
}

#Preview {
    ContentView()
}
