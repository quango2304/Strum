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
    @Binding var showingImportPopup: Bool
    @Binding var selectedPlaylistForImport: Playlist?
    @Binding var showingPlaylistNamePopup: Bool
    @Binding var playlistNameForFiles: String
    @Binding var pendingFiles: [URL]
    let isCompact: Bool
    @State private var isDragOver = false
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
                // Beautiful empty state
                VStack(spacing: 20) {
                    Spacer()

                    Image(systemName: "music.note.list")
                        .font(.system(size: 64, weight: .light))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue.opacity(0.7), .cyan.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    VStack(spacing: 12) {
                        Text("No Playlists")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)

                        Text("Create your first playlist to get started")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }

                    Button(action: {
                        showingAddPlaylistPopup = true
                        newPlaylistName = ""
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "plus.circle.fill")
                            Text("Create Playlist")
                        }
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(
                            LinearGradient(
                                colors: [.blue, .cyan],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(PlainButtonStyle())

                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.horizontal, 20)
            } else {
                List(playlistManager.playlists, id: \.id) { playlist in
                    PlaylistRow(
                        playlist: playlist,
                        isSelected: playlistManager.selectedPlaylist?.id == playlist.id,
                        playlistManager: playlistManager,
                        showingImportPopup: $showingImportPopup,
                        selectedPlaylistForImport: $selectedPlaylistForImport
                    )
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                }
                .listStyle(PlainListStyle())
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

                        // Content with beautiful styling
                        VStack(spacing: 20) {
                            // Dynamic icon based on content type
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 72, weight: .medium))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.blue, .cyan],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)

                            VStack(spacing: 12) {
                                Text("Drop Here")
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [.primary, .blue],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )

                                Text("Create new playlist with your content")
                                    .font(.headline)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                    .opacity(0.8)
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
                DesignSystem.colors(for: colorTheme).sidebarBackground
                colorTheme.backgroundTint.opacity(0.3)
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
    @Binding var showingImportPopup: Bool
    @Binding var selectedPlaylistForImport: Playlist?
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
                HStack(spacing: 4) {
                    // Add content button
                    Button(action: {
                        selectedPlaylistForImport = playlist
                        showingImportPopup = true
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.accentColor)
                            .font(.system(size: 12))
                    }
                    .buttonStyle(PlainButtonStyle())
                    .help("Add Music")

                    // Delete button
                    Button(action: {
                        playlistManager.deletePlaylist(playlist)
                    }) {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                            .font(.system(size: 12))
                    }
                    .buttonStyle(PlainButtonStyle())
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
            playlistManager.selectPlaylist(playlist)
        }
        .background(
            Group {
                if isSelected {
                    // Subtle selection background
                    ZStack {
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                            .fill(.ultraThinMaterial)
                            .opacity(0.6)

                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                            .fill(colorTheme.primaryColor)
                            .opacity(0.25)
                    }
                } else if isHovered {
                    // Subtle hover state
                    ZStack {
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                            .fill(.ultraThinMaterial)
                            .opacity(0.4)

                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                            .fill(Color.primary)
                            .opacity(0.1)
                    }
                } else {
                    // Transparent
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                        .fill(Color.clear)
                }
            }
            .animation(.easeInOut(duration: 0.15), value: isHovered)
            .animation(.easeInOut(duration: 0.15), value: isSelected)
        )

    }
}



#Preview {
    PlaylistSidebar(
        playlistManager: PlaylistManager(),
        showingAddPlaylistPopup: .constant(false),
        newPlaylistName: .constant(""),
        showingImportPopup: .constant(false),
        selectedPlaylistForImport: .constant(nil),
        showingPlaylistNamePopup: .constant(false),
        playlistNameForFiles: .constant(""),
        pendingFiles: .constant([]),
        isCompact: false
    )
    .frame(width: 250, height: 400)
}
