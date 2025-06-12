//
//  PlaylistSidebar.swift
//  Strum
//
//  Created by leongo on 13/6/25.
//

import SwiftUI

struct PlaylistSidebar: View {
    @ObservedObject var playlistManager: PlaylistManager
    @State private var showingNewPlaylistAlert = false
    @State private var newPlaylistName = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Text("Playlists")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Menu {
                    Button("Import Files...") {
                        playlistManager.importFiles()
                    }
                    
                    Button("Import Folder...") {
                        playlistManager.importFolder()
                    }
                    
                    Divider()
                    
                    Button("New Playlist...") {
                        showingNewPlaylistAlert = true
                    }
                } label: {
                    Image(systemName: "plus")
                        .foregroundColor(.secondary)
                }
                .menuStyle(BorderlessButtonMenuStyle())
                .frame(width: 20, height: 20)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(NSColor.controlBackgroundColor))
            
            Divider()
            
            // Playlist List
            List(playlistManager.playlists, id: \.id, selection: Binding(
                get: { playlistManager.selectedPlaylist?.id },
                set: { selectedId in
                    if let selectedId = selectedId,
                       let playlist = playlistManager.playlists.first(where: { $0.id == selectedId }) {
                        playlistManager.selectPlaylist(playlist)
                    }
                }
            )) { playlist in
                PlaylistRow(playlist: playlist, playlistManager: playlistManager)
                    .tag(playlist.id)
            }
            .listStyle(SidebarListStyle())
        }
        .frame(minWidth: 200, maxWidth: 300)
        .alert("New Playlist", isPresented: $showingNewPlaylistAlert) {
            TextField("Playlist Name", text: $newPlaylistName)
            Button("Cancel") {
                newPlaylistName = ""
            }
            Button("Create") {
                if !newPlaylistName.isEmpty {
                    playlistManager.createPlaylist(name: newPlaylistName)
                    newPlaylistName = ""
                }
            }
        } message: {
            Text("Enter a name for the new playlist")
        }
    }
}

struct PlaylistRow: View {
    @ObservedObject var playlist: Playlist
    let playlistManager: PlaylistManager
    @State private var isHovered = false
    
    var body: some View {
        HStack {
            Image(systemName: "music.note.list")
                .foregroundColor(.secondary)
                .frame(width: 16, height: 16)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(playlist.name)
                    .font(.system(size: 13))
                    .lineLimit(1)
                
                Text("\(playlist.tracks.count) songs")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if isHovered && playlist.name != "My Music" {
                Button(action: {
                    playlistManager.deletePlaylist(playlist)
                }) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                        .font(.system(size: 11))
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onHover { hovering in
            isHovered = hovering
        }
        .contextMenu {
            if playlist.name != "My Music" {
                Button("Delete Playlist") {
                    playlistManager.deletePlaylist(playlist)
                }
            }
            
            Button("Import Files...") {
                playlistManager.selectPlaylist(playlist)
                playlistManager.importFiles()
            }
            
            Button("Import Folder...") {
                playlistManager.selectPlaylist(playlist)
                playlistManager.importFolder()
            }
        }
    }
}

#Preview {
    PlaylistSidebar(playlistManager: PlaylistManager())
        .frame(width: 250, height: 400)
}
