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

    var body: some View {
        VStack(spacing: 0) {
            // Main Content Area
            HStack(spacing: 0) {
                // Sidebar
                PlaylistSidebar(playlistManager: playlistManager)

                Divider()

                // Main Content
                if let selectedPlaylist = playlistManager.selectedPlaylist {
                    TrackListView(playlist: selectedPlaylist, musicPlayer: musicPlayer)
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

            // Player Controls
            PlayerControlsView(musicPlayer: musicPlayer)
        }
        .frame(minWidth: 800, minHeight: 600)
    }
}

#Preview {
    ContentView()
}
