//
//  TrackListView.swift
//  Strum
//
//  Created by leongo on 13/6/25.
//

import SwiftUI
import UniformTypeIdentifiers

struct TrackListView: View {
    @ObservedObject var playlist: Playlist
    @ObservedObject var musicPlayer: MusicPlayerManager
    @FocusState.Binding var isSearchFieldFocused: Bool
    @State private var selectedTrack: Track?
    @State private var isDragOver = false
    @State private var animationTrigger = false
    @State private var searchText = ""

    // We need access to PlaylistManager to save changes
    @EnvironmentObject var playlistManager: PlaylistManager
    @Environment(\.colorTheme) private var colorTheme

    // Helper function to normalize text for search (remove diacritics, special chars, lowercase)
    private func normalizeForSearch(_ text: String) -> String {
        return text
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: nil)
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .joined()
            .lowercased()
    }

    // Computed property to filter tracks based on search text
    private var filteredTracks: [Track] {
        if searchText.isEmpty {
            return playlist.tracks
        } else {
            let normalizedSearch = normalizeForSearch(searchText)
            return playlist.tracks.filter { track in
                normalizeForSearch(track.title).contains(normalizedSearch) ||
                normalizeForSearch(track.artist ?? "").contains(normalizedSearch) ||
                normalizeForSearch(track.album ?? "").contains(normalizedSearch)
            }
        }
    }

    // Helper function to get track number
    private func getTrackNumber(for track: Track) -> Int {
        return (playlist.tracks.firstIndex(where: { $0.id == track.id }) ?? 0) + 1
    }

    var body: some View {
        GeometryReader { geometry in
            let isCompact = geometry.size.width < 1000

            VStack(spacing: 0) {
                headerView(isCompact: isCompact)
                Divider()
                trackListHeaderView(isCompact: isCompact)
                Divider()
                trackListContentView(isCompact: isCompact)
            }
            .background(backgroundView)
            .overlay(dragOverlayView)
            .onDrop(of: [.fileURL], isTargeted: $isDragOver) { providers in
                return handleDrop(providers: providers)
            }
        }
    }

    // MARK: - View Components

    @ViewBuilder
    private func headerView(isCompact: Bool) -> some View {
        HStack(spacing: DesignSystem.Spacing.lg) {
            // Left side: Beautiful artistic playlist title
            Text(playlist.name)
                .font(.custom("Brush Script MT", size: 32))
                .fontWeight(.medium)
                .foregroundStyle(
                    LinearGradient(
                        colors: colorTheme.gradientColors,
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )

            Spacer()

            // Right side: Beautiful search field with improved visibility
            searchFieldView
        }
        .padding(.horizontal, DesignSystem.Spacing.xl)
        .padding(.vertical, DesignSystem.Spacing.lg)
    }

    @ViewBuilder
    private var searchFieldView: some View {
        HStack(spacing: DesignSystem.Spacing.sm) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(DesignSystem.colors(for: colorTheme).gradient)
                .font(.system(size: 16, weight: .medium))

            TextField("Search tracks, artists, albums...", text: $searchText)
                .textFieldStyle(PlainTextFieldStyle())
                .font(DesignSystem.Typography.body)
                .foregroundColor(.primary)
                .focused($isSearchFieldFocused)

            if !searchText.isEmpty {
                Button(action: {
                    searchText = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                        .font(.system(size: 14))
                }
                .buttonStyle(PlainButtonStyle())
                .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(.horizontal, DesignSystem.Spacing.md)
        .padding(.vertical, DesignSystem.Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                .fill(.regularMaterial)
                .opacity(0.9)
                .overlay(
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                        .stroke(
                            searchText.isEmpty ?
                            DesignSystem.colors(for: colorTheme).primary.opacity(0.2) :
                            DesignSystem.colors(for: colorTheme).primary.opacity(0.5),
                            lineWidth: 1.5
                        )
                )
        )
        .animation(.easeInOut(duration: 0.2), value: searchText.isEmpty)
    }

    @ViewBuilder
    private func trackListHeaderView(isCompact: Bool) -> some View {
        HStack {
            Text("#")
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 30, alignment: .center)

            Text("Title")
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            if !isCompact {
                Text("Artist")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(width: 150, alignment: .leading)

                Text("Album")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(width: 150, alignment: .leading)

                Text("Quality")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(width: 100, alignment: .leading)
            } else {
                Text("Artist")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(width: 120, alignment: .leading)

                Text("Quality")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(width: 80, alignment: .leading)
            }

            Text("Duration")
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 60, alignment: .trailing)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
    }

    @ViewBuilder
    private func trackListContentView(isCompact: Bool) -> some View {
        if playlist.tracks.isEmpty {
            emptyStateView
        } else {
            ZStack {
                if filteredTracks.isEmpty {
                    noResultsView
                } else {
                    trackListView(isCompact: isCompact)
                }
            }
        }
    }

    @ViewBuilder
    private var emptyStateView: some View {
        VStack(spacing: DesignSystem.Spacing.xl) {
            Spacer()

            // Animated music icon with theme-aware gradient
            Image(systemName: "music.note")
                .font(.system(size: 64, weight: .light))
                .foregroundStyle(DesignSystem.colors(for: colorTheme).gradient)
                .shadow(color: DesignSystem.colors(for: colorTheme).primary.opacity(0.3), radius: 8, x: 0, y: 4)
                .scaleEffect(animationTrigger ? 1.05 : 1.0)
                .animation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true), value: animationTrigger)

            VStack(spacing: DesignSystem.Spacing.md) {
                Text("No Songs in \"\(playlist.name)\"")
                    .font(DesignSystem.Typography.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(
                        LinearGradient(
                            colors: colorTheme.gradientColors,
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .multilineTextAlignment(.center)

                Text("Drag and drop music files or folders here to add them to this playlist")
                    .font(DesignSystem.Typography.callout)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .opacity(0.8)
                    .padding(.horizontal, DesignSystem.Spacing.xl)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
        .onTapGesture {
            isSearchFieldFocused = false
        }
        .onAppear {
            animationTrigger = true
        }
    }

    @ViewBuilder
    private var noResultsView: some View {
        VStack(spacing: DesignSystem.Spacing.xl) {
            Spacer()

            // Animated search icon with theme-aware gradient
            Image(systemName: "magnifyingglass")
                .font(.system(size: 64, weight: .light))
                .foregroundStyle(DesignSystem.colors(for: colorTheme).gradient)
                .shadow(color: DesignSystem.colors(for: colorTheme).primary.opacity(0.3), radius: 8, x: 0, y: 4)
                .scaleEffect(animationTrigger ? 1.05 : 1.0)
                .animation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true), value: animationTrigger)

            VStack(spacing: DesignSystem.Spacing.md) {
                Text("No Results Found")
                    .font(DesignSystem.Typography.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(
                        LinearGradient(
                            colors: colorTheme.gradientColors,
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .multilineTextAlignment(.center)

                Text("No tracks match \"\(searchText)\"")
                    .font(DesignSystem.Typography.callout)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .opacity(0.8)
                    .padding(.horizontal, DesignSystem.Spacing.xl)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
        .onTapGesture {
            isSearchFieldFocused = false
        }
    }

    @ViewBuilder
    private func trackListView(isCompact: Bool) -> some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(filteredTracks, id: \.id) { track in
                    trackRowView(track: track, isCompact: isCompact)
                        .id(track.id)
                }

                // Add padding at the bottom to ensure last track is fully visible
                Color.clear
                    .frame(height: DesignSystem.Spacing.xl)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            isSearchFieldFocused = false
        }
    }

    @ViewBuilder
    private func trackRowView(track: Track, isCompact: Bool) -> some View {
        TrackRow(
            track: track,
            trackNumber: getTrackNumber(for: track),
            isPlaying: musicPlayer.currentTrack?.id == track.id && musicPlayer.playerState == .playing,
            isPaused: musicPlayer.currentTrack?.id == track.id && musicPlayer.playerState == .paused,
            colorTheme: colorTheme,
            isCompact: isCompact,
            onPlay: {
                // Clear search field and unfocus it when playing a track
                searchText = ""
                isSearchFieldFocused = false
                musicPlayer.play(track: track, in: playlist)
            },
            isSearchFieldFocused: $isSearchFieldFocused
        )
    }

    private func handleMove(source: IndexSet, destination: Int) {
        // Only allow move operations when not filtering
        if searchText.isEmpty {
            playlist.moveTrack(from: source, to: destination)
            // Save the playlists to persist the changes
            playlistManager.savePlaylists()
        }
    }

    private func handleDelete(indexSet: IndexSet) {
        // Handle deletion with filtered tracks
        for index in indexSet {
            let trackToDelete = filteredTracks[index]
            if let originalIndex = playlist.tracks.firstIndex(where: { $0.id == trackToDelete.id }) {
                playlist.removeTrack(at: originalIndex)
            }
        }
        // Save the playlists to persist the changes
        playlistManager.savePlaylists()
    }

    @ViewBuilder
    private var backgroundView: some View {
        ZStack {
            // Base background
            Color(NSColor.controlBackgroundColor)

            // Consistent themed gradient overlay
            DesignSystem.colors(for: colorTheme).sectionBackground
        }
    }

    @ViewBuilder
    private var dragOverlayView: some View {
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
                        endRadius: 300
                    )
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 0))

                    // Content with beautiful themed styling
                    VStack(spacing: DesignSystem.Spacing.xl) {
                        // Animated themed music icon
                        Image(systemName: "music.note.list")
                            .font(.system(size: 72, weight: .medium))
                            .foregroundStyle(DesignSystem.colors(for: colorTheme).gradient)
                            .shadow(color: DesignSystem.colors(for: colorTheme).primary.opacity(0.4), radius: 12, x: 0, y: 6)
                            .scaleEffect(isDragOver ? 1.1 : 1.0)
                            .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: isDragOver)

                        VStack(spacing: DesignSystem.Spacing.md) {
                            Text("Drop Music Here")
                                .font(DesignSystem.Typography.title)
                                .fontWeight(.bold)
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: colorTheme.gradientColors,
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )

                            Text("Add files or folders to \"\(playlist.name)\"")
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
                            self.handleFileOrFolderDrop(url: url)
                        }
                    }
                }
            }
        }

        return hasValidProvider
    }

    private func handleFileOrFolderDrop(url: URL) {
        // Check if it's a directory
        var isDirectory: ObjCBool = false
        let fileExists = FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory)

        if fileExists && isDirectory.boolValue {
            // It's a folder - use PlaylistManager's progress system
            playlistManager.selectPlaylist(playlist)
            playlistManager.importFolderAtURL(url)
        } else if fileExists {
            // It's a file - check if it's an audio file and import it
            importSingleFile(url: url)
        }
    }

    private func importSingleFile(url: URL) {
        // Check if it's an audio file
        let audioExtensions = ["mp3", "m4a", "wav", "flac", "aac", "ogg", "wma"]
        let fileExtension = url.pathExtension.lowercased()

        guard audioExtensions.contains(fileExtension) else {
            return // Not an audio file
        }

        // For single files, we can import directly without progress popup
        // since it's fast enough
        let track = Track(url: url)

        DispatchQueue.main.async {
            playlist.addTrack(track)
            // Save the playlists to persist the changes
            playlistManager.savePlaylists()
        }
    }

    private func findAudioFiles(in directory: URL) -> [Track] {
        var tracks: [Track] = []
        let audioExtensions = ["mp3", "m4a", "wav", "flac", "aac", "ogg", "wma"]

        guard let enumerator = FileManager.default.enumerator(
            at: directory,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles, .skipsPackageDescendants]
        ) else {
            return tracks
        }

        for case let fileURL as URL in enumerator {
            let fileExtension = fileURL.pathExtension.lowercased()
            if audioExtensions.contains(fileExtension) {
                let track = Track(url: fileURL)
                tracks.append(track)
            }
        }

        return tracks
    }
}

struct TrackRow: View {
    let track: Track
    let trackNumber: Int
    let isPlaying: Bool
    let isPaused: Bool
    let colorTheme: ColorTheme
    let isCompact: Bool
    let onPlay: () -> Void
    @FocusState.Binding var isSearchFieldFocused: Bool

    @State private var isHovered = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Music note icon with round background
            ZStack {
                Circle()
                    .fill(Color.secondary.opacity(0.15))
                    .frame(width: 28, height: 28)

                Image(systemName: "music.note")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
                    .opacity(0.8)
            }

            // Track Number / Play Button
            ZStack {
                if isHovered {
                    Button(action: onPlay) {
                        Image(systemName: "play.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.primary)
                    }
                    .buttonStyle(PlainButtonStyle())
                } else if isPlaying {
                    Image(systemName: "speaker.wave.2.fill")
                        .font(.system(size: 12))
                        .foregroundColor(colorTheme.primaryColor)
                } else if isPaused {
                    Image(systemName: "pause.fill")
                        .font(.system(size: 12))
                        .foregroundColor(colorTheme.primaryColor)
                } else {
                    Text("\(trackNumber)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .frame(width: 30, alignment: .center)
            
            // Title
            Text(track.title)
                .font(DesignSystem.Typography.trackTitle)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)
                .foregroundColor(isPlaying || isPaused ? colorTheme.primaryColor : .primary)

            if !isCompact {
                // Full size mode: Artist, Album, Quality, Duration
                Text(track.artist ?? "Unknown Artist")
                    .font(DesignSystem.Typography.trackSubtitle)
                    .lineLimit(1)
                    .frame(width: 150, alignment: .leading)
                    .foregroundColor(.secondary)

                Text(track.album ?? "Unknown Album")
                    .font(DesignSystem.Typography.trackSubtitle)
                    .lineLimit(1)
                    .frame(width: 150, alignment: .leading)
                    .foregroundColor(.secondary)

                Text(track.qualityString)
                    .font(DesignSystem.Typography.trackSubtitle)
                    .lineLimit(1)
                    .frame(width: 100, alignment: .leading)
                    .foregroundColor(.secondary)
            } else {
                // Compact mode: Artist, Quality
                Text(track.artist ?? "Unknown Artist")
                    .font(DesignSystem.Typography.trackSubtitle)
                    .lineLimit(1)
                    .frame(width: 120, alignment: .leading)
                    .foregroundColor(.secondary)

                Text(track.qualityString)
                    .font(DesignSystem.Typography.trackSubtitle)
                    .lineLimit(1)
                    .frame(width: 80, alignment: .leading)
                    .foregroundColor(.secondary)
            }

            // Duration
            Text(formatDuration(track.duration))
                .font(DesignSystem.Typography.trackSubtitle)
                .frame(width: 60, alignment: .trailing)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, DesignSystem.Spacing.xl)
        .padding(.vertical, DesignSystem.Spacing.sm)
        .contentShape(Rectangle())
        .onHover { hovering in
            isHovered = hovering
        }
        .onTapGesture {
            onPlay()
        }
        .background(
            Group {
                if isPlaying || isPaused {
                    // Subtle active track background with margins
                    ZStack {
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                            .fill(.ultraThinMaterial)
                            .opacity(0.5)

                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                            .fill(colorTheme.primaryColor)
                            .opacity(0.2)
                    }
                    .padding(.horizontal, DesignSystem.Spacing.md)
                } else if isHovered {
                    // Subtle hover state with margins
                    ZStack {
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                            .fill(.ultraThinMaterial)
                            .opacity(0.3)

                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.lg)
                            .fill(Color.primary)
                            .opacity(0.08)
                    }
                    .padding(.horizontal, DesignSystem.Spacing.md)
                } else {
                    // Transparent
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                        .fill(Color.clear)
                }
            }
            .animation(.easeInOut(duration: 0.15), value: isHovered)
            .animation(.easeInOut(duration: 0.15), value: isPlaying)
            .animation(.easeInOut(duration: 0.15), value: isPaused)
        )
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}



#Preview {
    struct PreviewWrapper: View {
        @FocusState private var isSearchFieldFocused: Bool
        let playlist = Playlist(name: "Test Playlist")
        let musicPlayer = MusicPlayerManager()

        var body: some View {
            TrackListView(playlist: playlist, musicPlayer: musicPlayer, isSearchFieldFocused: $isSearchFieldFocused)
                .frame(width: 800, height: 600)
        }
    }

    return PreviewWrapper()
}
