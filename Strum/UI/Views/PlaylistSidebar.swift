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
    @State private var animationTrigger = false
    @State private var draggedItem: String?
    @State private var dropTargetIndex: Int?
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
                playlistListView
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

        .background(
            ZStack {
                // Base background
                Color(NSColor.controlBackgroundColor)

                // Consistent themed gradient overlay
                DesignSystem.colors(for: colorTheme).sectionBackground
            }
        )
    }

    @ViewBuilder
    private var playlistListView: some View {
        List {
            ForEach(Array(playlistManager.playlists.enumerated()), id: \.element.id) { index, playlist in
                VStack(spacing: 0) {
                    // Drop zone above each item
                    Rectangle()
                        .fill(Color.clear)
                        .frame(height: 4)
                        .overlay(
                            Rectangle()
                                .fill(Color.accentColor)
                                .frame(height: dropTargetIndex == index ? 2 : 0)
                                .padding(.horizontal, 8)
                        )
                        .onDrop(of: [.text], delegate: DropZoneDelegate(
                            targetIndex: index,
                            playlistManager: playlistManager,
                            draggedItem: $draggedItem,
                            dropTargetIndex: $dropTargetIndex
                        ))

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
                    .onDrag {
                        draggedItem = "\(index)"
                        if let playlistIndex = playlistManager.playlists.firstIndex(where: { $0.id == playlist.id }) {
                            return NSItemProvider(object: "\(playlistIndex)" as NSString)
                        }
                        return NSItemProvider()
                    }
                    .onDrop(of: [.text], delegate: PlaylistDropDelegate(
                        playlist: playlist,
                        playlistManager: playlistManager,
                        draggedItem: $draggedItem,
                        dropTargetIndex: $dropTargetIndex
                    ))

                    // Drop zone below the last item
                    if index == playlistManager.playlists.count - 1 {
                        Rectangle()
                            .fill(Color.clear)
                            .frame(height: 4)
                            .overlay(
                                Rectangle()
                                    .fill(Color.accentColor)
                                    .frame(height: dropTargetIndex == playlistManager.playlists.count ? 2 : 0)
                                    .padding(.horizontal, 8)
                            )
                            .onDrop(of: [.text], delegate: DropZoneDelegate(
                                targetIndex: playlistManager.playlists.count,
                                playlistManager: playlistManager,
                                draggedItem: $draggedItem,
                                dropTargetIndex: $dropTargetIndex
                            ))
                    }
                }
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .deleteDisabled(false)
            }
        }
        .listStyle(PlainListStyle())
        .environment(\.defaultMinListRowHeight, 0)

        .safeAreaInset(edge: .bottom) {
            // Add bottom padding to ensure last playlist is fully visible
            Color.clear.frame(height: DesignSystem.Spacing.lg)
        }
        .scrollContentBackground(.hidden)
    }

    private func handlePlaylistMove(source: IndexSet, destination: Int) {
        playlistManager.movePlaylist(from: source, to: destination)
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
        HStack(spacing: DesignSystem.Spacing.sm) {
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

            // Action buttons on hover
            if isHovered {
                PlaylistActionButtons(
                    playlist: playlist,
                    playlistManager: playlistManager,
                    showingEditPlaylistPopup: $showingEditPlaylistPopup,
                    editPlaylistName: $editPlaylistName,
                    selectedPlaylistForEdit: $selectedPlaylistForEdit,
                    showingImportPopup: $showingImportPopup,
                    selectedPlaylistForImport: $selectedPlaylistForImport,
                    isSearchFieldFocused: $isSearchFieldFocused
                )
            }
        }
        .padding(.horizontal, DesignSystem.Spacing.sm)
        .padding(.vertical, DesignSystem.Spacing.xs)
        .contentShape(Rectangle())
        .background(
            PlaylistRowBackground(isSelected: isSelected, isHovered: isHovered, colorTheme: colorTheme)
        )
        .onHover { hovering in
            isHovered = hovering
        }
        .onTapGesture {
            isSearchFieldFocused = false
            playlistManager.selectPlaylist(playlist)
        }
        .contextMenu {
            Button("Add Music") {
                isSearchFieldFocused = false
                selectedPlaylistForImport = playlist
                showingImportPopup = true
            }

            Button("Edit Playlist") {
                isSearchFieldFocused = false
                selectedPlaylistForEdit = playlist
                editPlaylistName = playlist.name
                showingEditPlaylistPopup = true
            }

            Divider()

            Button("Delete Playlist", role: .destructive) {
                isSearchFieldFocused = false
                playlistManager.deletePlaylist(playlist)
            }
        }
    }
}

struct PlaylistDropDelegate: DropDelegate {
    let playlist: Playlist
    let playlistManager: PlaylistManager
    @Binding var draggedItem: String?
    @Binding var dropTargetIndex: Int?

    func performDrop(info: DropInfo) -> Bool {
        defer {
            draggedItem = nil
            dropTargetIndex = nil
        }

        guard let item = info.itemProviders(for: [.text]).first else { return false }

        item.loadItem(forTypeIdentifier: "public.text", options: nil) { (data, error) in
            guard let data = data as? Data,
                  let sourceIndexString = String(data: data, encoding: .utf8),
                  let sourceIndex = Int(sourceIndexString) else { return }

            DispatchQueue.main.async {
                guard let destinationIndex = self.playlistManager.playlists.firstIndex(where: { $0.id == self.playlist.id }) else { return }

                if sourceIndex != destinationIndex {
                    self.playlistManager.movePlaylist(from: IndexSet([sourceIndex]), to: destinationIndex > sourceIndex ? destinationIndex + 1 : destinationIndex)
                }
            }
        }

        return true
    }

    func dropEntered(info: DropInfo) {
        guard let destinationIndex = playlistManager.playlists.firstIndex(where: { $0.id == playlist.id }) else { return }

        // Determine if we should show indicator above or below based on drop location
        let dropLocation = info.location
        let itemHeight: CGFloat = 50 // Approximate height of playlist row
        let shouldDropBelow = dropLocation.y > itemHeight / 2

        dropTargetIndex = shouldDropBelow ? destinationIndex + 1 : destinationIndex
    }

    func dropExited(info: DropInfo) {
        dropTargetIndex = nil
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        // Update drop position based on cursor location
        guard let destinationIndex = playlistManager.playlists.firstIndex(where: { $0.id == playlist.id }) else {
            return DropProposal(operation: .move)
        }

        let dropLocation = info.location
        let itemHeight: CGFloat = 50
        let shouldDropBelow = dropLocation.y > itemHeight / 2

        dropTargetIndex = shouldDropBelow ? destinationIndex + 1 : destinationIndex

        return DropProposal(operation: .move)
    }
}

struct DropZoneDelegate: DropDelegate {
    let targetIndex: Int
    let playlistManager: PlaylistManager
    @Binding var draggedItem: String?
    @Binding var dropTargetIndex: Int?

    func performDrop(info: DropInfo) -> Bool {
        defer {
            draggedItem = nil
            dropTargetIndex = nil
        }

        guard let item = info.itemProviders(for: [.text]).first else { return false }

        item.loadItem(forTypeIdentifier: "public.text", options: nil) { (data, error) in
            guard let data = data as? Data,
                  let sourceIndexString = String(data: data, encoding: .utf8),
                  let sourceIndex = Int(sourceIndexString) else { return }

            DispatchQueue.main.async {
                if sourceIndex != self.targetIndex {
                    self.playlistManager.movePlaylist(from: IndexSet([sourceIndex]), to: self.targetIndex > sourceIndex ? self.targetIndex : self.targetIndex)
                }
            }
        }

        return true
    }

    func dropEntered(info: DropInfo) {
        dropTargetIndex = targetIndex
    }

    func dropExited(info: DropInfo) {
        dropTargetIndex = nil
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        dropTargetIndex = targetIndex
        return DropProposal(operation: .move)
    }
}

// MARK: - Reusable Components

struct PlaylistActionButtons: View {
    let playlist: Playlist
    let playlistManager: PlaylistManager
    @Binding var showingEditPlaylistPopup: Bool
    @Binding var editPlaylistName: String
    @Binding var selectedPlaylistForEdit: Playlist?
    @Binding var showingImportPopup: Bool
    @Binding var selectedPlaylistForImport: Playlist?
    @FocusState.Binding var isSearchFieldFocused: Bool

    var body: some View {
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
    }
}

struct PlaylistRowBackground: View {
    let isSelected: Bool
    let isHovered: Bool
    let colorTheme: ColorTheme

    var body: some View {
        Group {
            if isSelected {
                // Selection background
                ZStack {
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                        .fill(.ultraThinMaterial)
                        .opacity(0.6)

                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                        .fill(colorTheme.primaryColor)
                        .opacity(0.25)
                }
            } else if isHovered {
                // Hover background
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
