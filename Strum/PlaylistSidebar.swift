//
//  PlaylistSidebar.swift
//  Strum
//
//  Created by leongo on 13/6/25.
//

import SwiftUI
import UniformTypeIdentifiers

struct PlaylistSidebar: View {
    @ObservedObject var playlistManager: PlaylistManager
    @Binding var showingAddPlaylistPopup: Bool
    @Binding var newPlaylistName: String
    @Binding var showingEditPlaylistPopup: Bool
    @Binding var editPlaylistName: String
    @Binding var selectedPlaylistForEdit: Playlist?
    @Binding var showingImportPopup: Bool
    @Binding var selectedPlaylistForImport: Playlist?
    @Binding var showingPlaylistNamePopup: Bool
    @Binding var playlistNameForFiles: String
    @Binding var pendingFiles: [URL]
    @FocusState.Binding var isSearchFieldFocused: Bool
    let isCompact: Bool
    @State private var isDragOver = false
    @State private var animationTrigger = false
    @Environment(\.colorTheme) private var colorTheme

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Text("Playlists")
                    .font(DesignSystem.Typography.headline)
                    .foregroundColor(.primary)

                Spacer()

                Button(action: {
                    isSearchFieldFocused = false
                    showingAddPlaylistPopup = true
                    newPlaylistName = ""
                }) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.white)
                }
                .buttonStyle(ThemedIconButtonStyle(size: 28, isActive: true, theme: colorTheme))
                .help("Add Playlist")
            }
            .padding(.horizontal, DesignSystem.Spacing.md)
            .padding(.vertical, DesignSystem.Spacing.sm)
            .background(
                ZStack {
                    // Subtle transparent background
                    Rectangle()
                        .fill(.ultraThinMaterial)
                        .opacity(0.3)

                    // Very subtle color tint
                    Rectangle()
                        .fill(colorTheme.surfaceTint)
                        .opacity(0.15)
                }
            )

            Divider()

            // Playlist List or Empty State
            if playlistManager.playlists.isEmpty {
                // Beautiful themed empty state
                VStack(spacing: DesignSystem.Spacing.xl) {
                    Spacer()

                    // Animated icon with theme-aware gradient
                    Image(systemName: "music.note.list")
                        .font(.system(size: 72, weight: .light))
                        .foregroundStyle(DesignSystem.colors(for: colorTheme).gradient)
                        .shadow(color: DesignSystem.colors(for: colorTheme).primary.opacity(0.3), radius: 8, x: 0, y: 4)
                        .scaleEffect(animationTrigger ? 1.05 : 1.0)
                        .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: animationTrigger)

                    VStack(spacing: DesignSystem.Spacing.md) {
                        Text("No Playlists")
                            .font(DesignSystem.Typography.title2)
                            .fontWeight(.bold)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: colorTheme.gradientColors,
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )

                        Text("Create your first playlist to get started")
                            .font(DesignSystem.Typography.callout)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .opacity(0.8)
                    }

                    // Beautiful themed button
                    Button(action: {
                        isSearchFieldFocused = false
                        showingAddPlaylistPopup = true
                        newPlaylistName = ""
                    }) {
                        HStack(spacing: DesignSystem.Spacing.sm) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 18, weight: .medium))
                            Text("Create Playlist")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, DesignSystem.Spacing.xl)
                        .padding(.vertical, DesignSystem.Spacing.md)
                        .background(
                            ZStack {
                                // Base gradient background
                                DesignSystem.colors(for: colorTheme).gradient

                                // Subtle highlight overlay
                                LinearGradient(
                                    colors: [Color.white.opacity(0.2), Color.clear],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            }
                        )
                        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg))
                        .shadow(color: DesignSystem.colors(for: colorTheme).primary.opacity(0.4), radius: 8, x: 0, y: 4)
                    }
                    .buttonStyle(PlainButtonStyle())

                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.horizontal, DesignSystem.Spacing.xl)
                .onAppear {
                    animationTrigger = true
                }
            } else {
                List(playlistManager.playlists, id: \.id) { playlist in
                    PlaylistRow(
                        playlist: playlist,
                        isSelected: playlistManager.selectedPlaylist?.id == playlist.id,
                        playlistManager: playlistManager,
                        showingEditPlaylistPopup: $showingEditPlaylistPopup,
                        editPlaylistName: $editPlaylistName,
                        selectedPlaylistForEdit: $selectedPlaylistForEdit,
                        showingImportPopup: $showingImportPopup,
                        selectedPlaylistForImport: $selectedPlaylistForImport,
                        isSearchFieldFocused: $isSearchFieldFocused
                    )
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                }
                .listStyle(PlainListStyle())
                .safeAreaInset(edge: .bottom) {
                    // Add bottom padding to ensure last playlist is fully visible
                    Color.clear.frame(height: DesignSystem.Spacing.lg)
                }
                .scrollContentBackground(.hidden)
            }
        }
        .background(
            // Subtle transparent background that works with global blur
            ZStack {
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .opacity(0.4)

                // Very subtle themed overlay
                Rectangle()
                    .fill(colorTheme.surfaceTint)
                    .opacity(0.1)
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg))
        .frame(
            minWidth: isCompact ? nil : 200,
            maxWidth: isCompact ? .infinity : 300,
            minHeight: isCompact ? 150 : nil,
            maxHeight: isCompact ? 200 : .infinity
        )
        .overlay(
            // Beautiful blur drag overlay
            Group {
                if isDragOver {
                    ZStack {
                        // Radial blur background effect
                        RadialGradient(
                            gradient: Gradient(stops: [
                                .init(color: Color.white.opacity(0.3), location: 0.0),
                                .init(color: Color.white.opacity(0.15), location: 0.3),
                                .init(color: Color.white.opacity(0.08), location: 0.6),
                                .init(color: Color.white.opacity(0.03), location: 1.0)
                            ]),
                            center: .center,
                            startRadius: 0,
                            endRadius: 200
                        )
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 0))

                        // Content with beautiful themed styling
                        VStack(spacing: DesignSystem.Spacing.xl) {
                            // Dynamic themed icon
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 72, weight: .medium))
                                .foregroundStyle(DesignSystem.colors(for: colorTheme).gradient)
                                .shadow(color: DesignSystem.colors(for: colorTheme).primary.opacity(0.4), radius: 12, x: 0, y: 6)
                                .scaleEffect(isDragOver ? 1.1 : 1.0)
                                .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: isDragOver)

                            VStack(spacing: DesignSystem.Spacing.md) {
                                Text("Drop Here")
                                    .font(DesignSystem.Typography.title)
                                    .fontWeight(.bold)
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: colorTheme.gradientColors,
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )

                                Text("Create new playlist with your content")
                                    .font(DesignSystem.Typography.headline)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                    .opacity(0.9)
                            }
                        }
                        .padding(40)
                    }
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.8).combined(with: .opacity),
                        removal: .scale(scale: 1.1).combined(with: .opacity)
                    ))
                }
            }
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isDragOver)
        )
        .background(
            ZStack {
                // Base background
                Color(NSColor.controlBackgroundColor)

                // Consistent themed gradient overlay
                DesignSystem.colors(for: colorTheme).sectionBackground
            }
        )
        .onDrop(of: [.fileURL], isTargeted: $isDragOver) { providers in
            return handleDrop(providers: providers)
        }
    }

    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        var hasValidProvider = false

        for provider in providers {
            if provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
                hasValidProvider = true
                provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { (item, error) in
                    if let error = error {
                        print("Error loading item: \(error)")
                        return
                    }

                    if let data = item as? Data,
                       let url = URL(dataRepresentation: data, relativeTo: nil) {
                        DispatchQueue.main.async {
                            self.handleFileOrFolderDrop(urls: [url])
                        }
                    }
                }
            }
        }

        return hasValidProvider
    }

    private func handleFileOrFolderDrop(urls: [URL]) {
        for url in urls {
            var isDirectory: ObjCBool = false
            let fileExists = FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory)

            if fileExists && isDirectory.boolValue {
                // Handle folder (create playlist automatically)
                let folderName = url.lastPathComponent
                let newPlaylist = playlistManager.createPlaylist(name: folderName)
                playlistManager.selectPlaylist(newPlaylist)
                playlistManager.importFolderAtURL(url)
            } else if fileExists {
                // Check if it's an audio file
                let audioExtensions = ["mp3", "m4a", "wav", "flac", "aac", "ogg", "wma"]
                let fileExtension = url.pathExtension.lowercased()
                if audioExtensions.contains(fileExtension) {
                    // Add to pending files for popup
                    if !pendingFiles.contains(url) {
                        pendingFiles.append(url)
                    }

                    // Show popup if not already showing
                    if !showingPlaylistNamePopup {
                        playlistNameForFiles = ""
                        showingPlaylistNamePopup = true
                    }
                }
            }
        }
    }
}

struct PlaylistRow: View {
    @ObservedObject var playlist: Playlist
    let isSelected: Bool
    let playlistManager: PlaylistManager
    @Binding var showingEditPlaylistPopup: Bool
    @Binding var editPlaylistName: String
    @Binding var selectedPlaylistForEdit: Playlist?
    @Binding var showingImportPopup: Bool
    @Binding var selectedPlaylistForImport: Playlist?
    @FocusState.Binding var isSearchFieldFocused: Bool
    @State private var isHovered = false
    @Environment(\.colorTheme) private var colorTheme

    var body: some View {
        HStack {
            Image(systemName: "music.note.list")
                .foregroundColor(isSelected ? colorTheme.primaryColor : .secondary)
                .frame(width: 16, height: 16)

            VStack(alignment: .leading, spacing: 2) {
                Text(playlist.name)
                    .font(.system(size: 13))
                    .lineLimit(1)
                    .foregroundColor(isSelected ? colorTheme.primaryColor : .primary)

                Text("\(playlist.tracks.count) songs")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }

            Spacer()

            if isHovered {
                HStack(spacing: 6) {
                    // Add content button
                    Button(action: {
                        isSearchFieldFocused = false
                        selectedPlaylistForImport = playlist
                        showingImportPopup = true
                    }) {
                        Image(systemName: "plus.circle.fill")
                    }
                    .buttonStyle(ActionIconButtonStyle(size: 20, actionType: .add))
                    .help("Add Music")

                    // Edit button
                    Button(action: {
                        isSearchFieldFocused = false
                        selectedPlaylistForEdit = playlist
                        editPlaylistName = playlist.name
                        showingEditPlaylistPopup = true
                    }) {
                        Image(systemName: "pencil")
                    }
                    .buttonStyle(ActionIconButtonStyle(size: 20, actionType: .edit))
                    .help("Edit Playlist")

                    // Delete button
                    Button(action: {
                        isSearchFieldFocused = false
                        playlistManager.deletePlaylist(playlist)
                    }) {
                        Image(systemName: "trash")
                    }
                    .buttonStyle(ActionIconButtonStyle(size: 20, actionType: .delete))
                    .help("Delete Playlist")
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
        .padding(.horizontal, DesignSystem.Spacing.sm)
        .padding(.vertical, DesignSystem.Spacing.xs)
        .contentShape(Rectangle())
        .onHover { hovering in
            isHovered = hovering
        }
        .onTapGesture {
            isSearchFieldFocused = false
            playlistManager.selectPlaylist(playlist)
        }
        .background(
            Group {
                if isSelected {
                    // Subtle selection background
                    ZStack {
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                            .fill(.ultraThinMaterial)
                            .opacity(0.6)

                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                            .fill(colorTheme.primaryColor)
                            .opacity(0.25)
                    }
                } else if isHovered {
                    // Subtle hover state
                    ZStack {
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                            .fill(.ultraThinMaterial)
                            .opacity(0.4)

                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                            .fill(Color.primary)
                            .opacity(0.1)
                    }
                } else {
                    // Transparent
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                        .fill(Color.clear)
                }
            }
            .animation(.easeInOut(duration: 0.15), value: isHovered)
            .animation(.easeInOut(duration: 0.15), value: isSelected)
        )

    }
}



#Preview {
    struct PreviewWrapper: View {
        @FocusState private var isSearchFieldFocused: Bool

        var body: some View {
            PlaylistSidebar(
                playlistManager: PlaylistManager(),
                showingAddPlaylistPopup: .constant(false),
                newPlaylistName: .constant(""),
                showingEditPlaylistPopup: .constant(false),
                editPlaylistName: .constant(""),
                selectedPlaylistForEdit: .constant(nil),
                showingImportPopup: .constant(false),
                selectedPlaylistForImport: .constant(nil),
                showingPlaylistNamePopup: .constant(false),
                playlistNameForFiles: .constant(""),
                pendingFiles: .constant([]),
                isSearchFieldFocused: $isSearchFieldFocused,
                isCompact: false
            )
            .frame(width: 250, height: 400)
        }
    }

    return PreviewWrapper()
}
