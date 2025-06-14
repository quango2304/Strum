//
//  ContentView.swift
//  Strum
//
//  Created by leongo on 13/6/25.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var playlistManager: PlaylistManager
    @StateObject private var musicPlayer = MusicPlayerManager()
    @EnvironmentObject private var preferencesManager: PreferencesManager
    @Environment(\.colorTheme) private var colorTheme
    @State private var showingAddPlaylistPopup = false
    @State private var newPlaylistName = ""
    @State private var showingEditPlaylistPopup = false
    @State private var editPlaylistName = ""
    @State private var selectedPlaylistForEdit: Playlist?
    @State private var showingImportPopup = false
    @State private var selectedPlaylistForImport: Playlist?
    @State private var showingPlaylistNamePopup = false
    @State private var playlistNameForFiles = ""
    @State private var pendingFiles: [URL] = []
    @State private var showingToast = false
    @State private var toastMessage = ""
    @State private var toastType: ToastView.ToastType = .success
    @State private var animationTrigger = false
    @FocusState private var isSearchFieldFocused: Bool

    // Responsive breakpoint - switch to vertical layout when width < 1000
    private let responsiveBreakpoint: CGFloat = 1000

    // MARK: - Computed Properties
    private var titleGradient: LinearGradient {
        LinearGradient(
            colors: colorTheme.gradientColors,
            startPoint: .leading,
            endPoint: .trailing
        )
    }

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
        .toast(isShowing: $showingToast, message: toastMessage, type: toastType)
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
        .toast(isShowing: $showingToast, message: toastMessage, type: toastType)
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

// MARK: - Add Playlist Popup
struct AddPlaylistPopup: View {
    @Binding var isPresented: Bool
    @Binding var playlistName: String
    let onSave: () -> Void
    @FocusState private var isTextFieldFocused: Bool
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
        .transition(.asymmetric(
            insertion: .scale(scale: 0.9).combined(with: .opacity),
            removal: .scale(scale: 1.1).combined(with: .opacity)
        ))
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isPresented)
    }
}

// MARK: - Edit Playlist Popup
struct EditPlaylistPopup: View {
    @Binding var isPresented: Bool
    @Binding var playlistName: String
    let playlist: Playlist
    let onSave: () -> Void
    @FocusState private var isTextFieldFocused: Bool
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

            // Popup content
            VStack(spacing: DesignSystem.Spacing.xl) {
                // Header with theme styling
                VStack(spacing: DesignSystem.Spacing.md) {
                    ZStack {
                        // Background circle with theme color
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

// MARK: - Import Popup
struct ImportPopup: View {
    @Binding var isPresented: Bool
    let playlist: Playlist
    let playlistManager: PlaylistManager
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

                    // Subtitle
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

// MARK: - Playlist Name Popup for Files
struct PlaylistNamePopup: View {
    @Binding var isPresented: Bool
    @Binding var playlistName: String
    let pendingFiles: [URL]
    let onSave: () -> Void
    @FocusState private var isTextFieldFocused: Bool
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

#Preview {
    ContentView()
}
