//
//  ContentView.swift
//  Strum
//
//  Created by leongo on 13/6/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var playlistManager = PlaylistManager()
    @StateObject private var musicPlayer = MusicPlayerManager()
    @EnvironmentObject private var preferencesManager: PreferencesManager
    @Environment(\.colorTheme) private var colorTheme
    @State private var showingAddPlaylistPopup = false
    @State private var newPlaylistName = ""
    @State private var showingImportPopup = false
    @State private var selectedPlaylistForImport: Playlist?
    @State private var showingPlaylistNamePopup = false
    @State private var playlistNameForFiles = ""
    @State private var pendingFiles: [URL] = []
    @State private var showingToast = false
    @State private var toastMessage = ""
    @State private var toastType: ToastView.ToastType = .success

    // Responsive breakpoint - switch to vertical layout when width < 1000
    private let responsiveBreakpoint: CGFloat = 1000

    var body: some View {
        GeometryReader { geometry in
            let isCompact = geometry.size.width < responsiveBreakpoint

            VStack(spacing: 0) {
                // Main Content Area - Responsive Layout
                if isCompact {
                    // Compact Layout: Vertical stack (track list on top, player controls in middle, playlist at bottom)
                    VStack(spacing: 0) {
                        // Main Content (Track List) - takes available space above player controls
                        if let selectedPlaylist = playlistManager.selectedPlaylist {
                            TrackListView(playlist: selectedPlaylist, musicPlayer: musicPlayer)
                                .environmentObject(playlistManager)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        } else {
                            VStack {
                                Image(systemName: "music.note.list")
                                    .font(.system(size: 48))
                                    .foregroundColor(.secondary)

                                Text("Select a playlist to view tracks")
                                    .font(.headline)
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        }

                        // Player Controls - Always visible and not cut off
                        PlayerControlsView(musicPlayer: musicPlayer, isCompact: isCompact)

                        // Playlist Sidebar (at bottom in compact mode)
                        PlaylistSidebar(
                            playlistManager: playlistManager,
                            showingAddPlaylistPopup: $showingAddPlaylistPopup,
                            newPlaylistName: $newPlaylistName,
                            showingImportPopup: $showingImportPopup,
                            selectedPlaylistForImport: $selectedPlaylistForImport,
                            showingPlaylistNamePopup: $showingPlaylistNamePopup,
                            playlistNameForFiles: $playlistNameForFiles,
                            pendingFiles: $pendingFiles,
                            isCompact: true
                        )
                        .frame(height: 180) // Reduced height for compact playlist view
                    }
                } else {
                    // Desktop Layout: Horizontal stack (sidebar on left, track list on right)
                    HStack(spacing: 0) {
                        // Sidebar
                        PlaylistSidebar(
                            playlistManager: playlistManager,
                            showingAddPlaylistPopup: $showingAddPlaylistPopup,
                            newPlaylistName: $newPlaylistName,
                            showingImportPopup: $showingImportPopup,
                            selectedPlaylistForImport: $selectedPlaylistForImport,
                            showingPlaylistNamePopup: $showingPlaylistNamePopup,
                            playlistNameForFiles: $playlistNameForFiles,
                            pendingFiles: $pendingFiles,
                            isCompact: false
                        )

                        Divider()

                        // Main Content
                        if let selectedPlaylist = playlistManager.selectedPlaylist {
                            TrackListView(playlist: selectedPlaylist, musicPlayer: musicPlayer)
                                .environmentObject(playlistManager)
                        } else {
                            VStack {
                                Image(systemName: "music.note.list")
                                    .font(.system(size: 48))
                                    .foregroundColor(.secondary)

                                Text("Select a playlist to view tracks")
                                    .font(.headline)
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        }
                    }
                }

                // Player Controls - Only for desktop layout (compact has its own)
                if !isCompact {
                    PlayerControlsView(musicPlayer: musicPlayer, isCompact: isCompact)
                }
            }
        }
        .frame(minWidth: 600, minHeight: 500) // Reduced minimum size for better responsiveness
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
        .sheet(isPresented: $preferencesManager.showPreferences) {
            PreferencesView(preferencesManager: preferencesManager)
        }
        .overlay(
            // Add Playlist Popup - Centered in entire app window
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
        )
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
            // Background overlay with blur
            DesignSystem.colors(for: colorTheme).overlay
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
            .cardStyle(padding: DesignSystem.Spacing.xxxl, cornerRadius: DesignSystem.CornerRadius.xl)
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

// MARK: - Import Popup
struct ImportPopup: View {
    @Binding var isPresented: Bool
    let playlist: Playlist
    let playlistManager: PlaylistManager

    var body: some View {
        ZStack {
            // Background overlay with blur effect
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    isPresented = false
                }

            // Popup content
            VStack(spacing: 24) {
                // Icon and Title
                VStack(spacing: 16) {
                    // Music icon
                    Image(systemName: "music.note.list")
                        .font(.system(size: 48))
                        .foregroundStyle(.blue.gradient)

                    // Title
                    Text("Add Music")
                        .font(.title)
                        .fontWeight(.bold)

                    // Subtitle
                    Text("to \"\(playlist.name)\"")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }

                // Action buttons
                VStack(spacing: 16) {
                    // Import Files button
                    Button(action: {
                        playlistManager.selectPlaylist(playlist)
                        playlistManager.importFiles()
                        isPresented = false
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "doc.badge.plus")
                                .font(.system(size: 18))

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Import Files")
                                    .font(.headline)
                                Text("Select individual music files")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.blue.opacity(0.1))
                                .stroke(Color.blue.opacity(0.3), lineWidth: 1)
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
                        HStack(spacing: 12) {
                            Image(systemName: "folder.badge.plus")
                                .font(.system(size: 18))

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Import Folder")
                                    .font(.headline)
                                Text("Select an entire music folder")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.green.opacity(0.1))
                                .stroke(Color.green.opacity(0.3), lineWidth: 1)
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
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(.regularMaterial)
                    .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
            )
            .frame(width: 380)
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

    var body: some View {
        ZStack {
            // Background blur
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .onTapGesture {
                    isPresented = false
                }

            // Popup content
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 12) {
                    Image(systemName: "music.note.list")
                        .font(.system(size: 48, weight: .medium))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue, .cyan],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    Text("Create New Playlist")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)

                    Text("Enter a name for your new playlist")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                // Text field
                VStack(alignment: .leading, spacing: 8) {
                    TextField("Playlist name", text: $playlistName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .font(.system(size: 16))
                        .frame(width: 280)
                        .focused($isTextFieldFocused)
                        .onSubmit {
                            onSave()
                        }

                    Text("\(pendingFiles.count) file\(pendingFiles.count == 1 ? "" : "s") ready to import")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                // Buttons
                HStack(spacing: 12) {
                    Button("Cancel") {
                        isPresented = false
                    }
                    .buttonStyle(.bordered)
                    .keyboardShortcut(.escape)

                    Button("Create") {
                        onSave()
                    }
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut(.return)
                    .disabled(playlistName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .padding(32)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10)
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
