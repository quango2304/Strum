//
//  TrackListView.swift
//  Strum
//
//  Created by leongo on 13/6/25.
//

import SwiftUI

struct TrackListView: View {
    @ObservedObject var playlist: Playlist
    @ObservedObject var musicPlayer: MusicPlayerManager
    @State private var selectedTrack: Track?
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text(playlist.name)
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text("\(playlist.tracks.count) songs")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(Color(NSColor.controlBackgroundColor))
            
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
                .font(.system(size: 13))
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)
                .foregroundColor(isPlaying || isPaused ? .accentColor : .primary)
            
            // Artist
            Text(track.artist ?? "Unknown Artist")
                .font(.system(size: 13))
                .lineLimit(1)
                .frame(width: 150, alignment: .leading)
                .foregroundColor(.secondary)
            
            // Album
            Text(track.album ?? "Unknown Album")
                .font(.system(size: 13))
                .lineLimit(1)
                .frame(width: 150, alignment: .leading)
                .foregroundColor(.secondary)
            
            // Duration
            Text(formatDuration(track.duration))
                .font(.system(size: 13))
                .frame(width: 60, alignment: .trailing)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 6)
        .contentShape(Rectangle())
        .onHover { hovering in
            isHovered = hovering
        }
        .onTapGesture(count: 2) {
            onPlay()
        }
        .background(
            Rectangle()
                .fill(isHovered ? Color.primary.opacity(0.05) : Color.clear)
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
