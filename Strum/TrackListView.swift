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
    @State private var selectedTrack: Track?
    @State private var isDragOver = false

    // We need access to PlaylistManager to save changes
    @EnvironmentObject var playlistManager: PlaylistManager
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text(playlist.name)
                    .font(DesignSystem.Typography.title2)
                    .foregroundColor(.primary)

                Spacer()

                Text("\(playlist.tracks.count) song\(playlist.tracks.count == 1 ? "" : "s")")
                    .font(DesignSystem.Typography.callout)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, DesignSystem.Spacing.xl)
            .padding(.vertical, DesignSystem.Spacing.lg)
            .background(
                Rectangle()
                    .fill(DesignSystem.Colors.surface)
                    .shadow(color: DesignSystem.Shadow.light, radius: 1, x: 0, y: 1)
            )
            
            Divider()
            
            // Track List Header
            HStack {
                Text("#")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(width: 30, alignment: .center)
                
                Text("Title")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Text("Artist")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(width: 150, alignment: .leading)
                
                Text("Album")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(width: 150, alignment: .leading)
                
                Text("Duration")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(width: 60, alignment: .trailing)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 8)
            .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
            
            Divider()
            
            // Track List
            if playlist.tracks.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "music.note")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    
                    Text("No songs in this playlist")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Text("Import music files or folders to get started")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(Array(playlist.tracks.enumerated()), id: \.element.id) { index, track in
                        TrackRow(
                            track: track,
                            trackNumber: index + 1,
                            isPlaying: musicPlayer.currentTrack?.id == track.id && musicPlayer.playerState == .playing,
                            isPaused: musicPlayer.currentTrack?.id == track.id && musicPlayer.playerState == .paused
                        ) {
                            musicPlayer.play(track: track, in: playlist)
                        }
                    }
                    .onMove { source, destination in
                        playlist.moveTrack(from: source, to: destination)
                    }
                    .onDelete { indexSet in
                        for index in indexSet {
                            playlist.removeTrack(at: index)
                        }
                    }
                }
                .listStyle(PlainListStyle())
            }
        }
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
                            endRadius: 300
                        )
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 0))

                        // Content with beautiful styling
                        VStack(spacing: 20) {
                            // Animated music icon
                            Image(systemName: "music.note.list")
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
                                Text("Drop Music Here")
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [.primary, .blue],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )

                                Text("Add files or folders to \"\(playlist.name)\"")
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
            // It's a folder - import all audio files from it
            importFolderContents(url: url)
        } else if fileExists {
            // It's a file - check if it's an audio file and import it
            importSingleFile(url: url)
        }
    }

    private func importFolderContents(url: URL) {
        let tracks = findAudioFiles(in: url)

        DispatchQueue.main.async {
            for track in tracks {
                playlist.addTrack(track)
            }
            // Save the playlists to persist the changes
            playlistManager.savePlaylists()
        }
    }

    private func importSingleFile(url: URL) {
        // Check if it's an audio file
        let audioExtensions = ["mp3", "m4a", "wav", "flac", "aac", "ogg", "wma"]
        let fileExtension = url.pathExtension.lowercased()

        guard audioExtensions.contains(fileExtension) else {
            return // Not an audio file
        }

        // Create track from file
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
    let onPlay: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Small artwork thumbnail
            Group {
                if let artwork = track.artwork {
                    Image(nsImage: artwork)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 28, height: 28)
                        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.sm))
                        .shadow(color: DesignSystem.Shadow.light, radius: 1, x: 0, y: 1)
                } else {
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.sm)
                        .fill(DesignSystem.Colors.surfaceSecondary)
                        .frame(width: 28, height: 28)
                        .overlay(
                            Image(systemName: "music.note")
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                        )
                        .shadow(color: DesignSystem.Shadow.light, radius: 1, x: 0, y: 1)
                }
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
                        .foregroundColor(.accentColor)
                } else if isPaused {
                    Image(systemName: "pause.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.accentColor)
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
                .foregroundColor(isPlaying || isPaused ? .accentColor : .primary)

            // Artist
            Text(track.artist ?? "Unknown Artist")
                .font(DesignSystem.Typography.trackSubtitle)
                .lineLimit(1)
                .frame(width: 150, alignment: .leading)
                .foregroundColor(.secondary)

            // Album
            Text(track.album ?? "Unknown Album")
                .font(DesignSystem.Typography.trackSubtitle)
                .lineLimit(1)
                .frame(width: 150, alignment: .leading)
                .foregroundColor(.secondary)

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
        .onTapGesture(count: 2) {
            onPlay()
        }
        .background(
            Rectangle()
                .fill(isHovered ? DesignSystem.Colors.hoverBackground : Color.clear)
                .animation(.easeInOut(duration: 0.15), value: isHovered)
        )
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

#Preview {
    let playlist = Playlist(name: "Test Playlist")
    let musicPlayer = MusicPlayerManager()
    
    return TrackListView(playlist: playlist, musicPlayer: musicPlayer)
        .frame(width: 800, height: 600)
}
