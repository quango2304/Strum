//
//  PlaylistManager.swift
//  Strum
//
//  Created by leongo on 13/6/25.
//

import Foundation
import AppKit
import UniformTypeIdentifiers

// MARK: - UTType Extensions for FLAC support
extension UTType {
    static var flac: UTType {
        UTType(filenameExtension: "flac") ?? UTType.audio
    }
}

class PlaylistManager: ObservableObject {
    @Published var playlists: [Playlist] = []
    @Published var selectedPlaylist: Playlist?
    
    private let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    private var playlistsURL: URL {
        documentsURL.appendingPathComponent("Strum_Playlists.json")
    }
    
    init() {
        loadPlaylists()
        if playlists.isEmpty {
            createDefaultPlaylist()
        }
        selectedPlaylist = playlists.first
    }
    
    private func createDefaultPlaylist() {
        let defaultPlaylist = Playlist(name: "My Music")
        playlists.append(defaultPlaylist)
        savePlaylists()
    }
    
    func createPlaylist(name: String) -> Playlist {
        let newPlaylist = Playlist(name: name)
        playlists.append(newPlaylist)
        savePlaylists()
        return newPlaylist
    }
    
    func deletePlaylist(_ playlist: Playlist) {
        playlists.removeAll { $0.id == playlist.id }

        // If we deleted the selected playlist, select another one
        if selectedPlaylist?.id == playlist.id {
            selectedPlaylist = playlists.first
        }

        savePlaylists()
    }
    
    func selectPlaylist(_ playlist: Playlist) {
        selectedPlaylist = playlist
    }
    
    func importFiles() {
        let openPanel = NSOpenPanel()
        openPanel.allowsMultipleSelection = true
        openPanel.canChooseDirectories = false
        openPanel.canChooseFiles = true
        openPanel.allowedContentTypes = [.audio, .mp3, .wav, .aiff, .mpeg4Audio, .flac]
        
        if openPanel.runModal() == .OK {
            let tracks = openPanel.urls.compactMap { url -> Track? in
                // Create security-scoped bookmark
                guard url.startAccessingSecurityScopedResource() else {
                    print("Failed to access security scoped resource: \(url)")
                    return nil
                }
                defer { url.stopAccessingSecurityScopedResource() }
                
                return Track(url: url)
            }
            
            guard let playlist = selectedPlaylist else { return }
            
            DispatchQueue.main.async {
                for track in tracks {
                    playlist.addTrack(track)
                }
                self.savePlaylists()
            }
        }
    }
    
    func importFolder() {
        let openPanel = NSOpenPanel()
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseDirectories = true
        openPanel.canChooseFiles = false
        
        if openPanel.runModal() == .OK {
            guard let folderURL = openPanel.urls.first else { return }
            
            // Create security-scoped bookmark
            guard folderURL.startAccessingSecurityScopedResource() else {
                print("Failed to access security scoped resource: \(folderURL)")
                return
            }
            defer { folderURL.stopAccessingSecurityScopedResource() }
            
            let tracks = findAudioFiles(in: folderURL)
            
            guard let playlist = selectedPlaylist else { return }
            
            DispatchQueue.main.async {
                for track in tracks {
                    playlist.addTrack(track)
                }
                self.savePlaylists()
            }
        }
    }

    func importFolderAtURL(_ folderURL: URL) {
        print("importFolderAtURL called with: \(folderURL)")

        // For drag and drop, we don't need security scoped access
        // The system grants temporary access to dragged files
        let tracks = findAudioFiles(in: folderURL)
        print("Found \(tracks.count) audio files")

        guard let playlist = selectedPlaylist else {
            print("No selected playlist")
            return
        }

        print("Adding tracks to playlist: \(playlist.name)")
        DispatchQueue.main.async {
            for track in tracks {
                print("Adding track: \(track.title)")
                playlist.addTrack(track)
            }
            print("Saving playlists")
            self.savePlaylists()
        }
    }

    private func findAudioFiles(in directory: URL) -> [Track] {
        var tracks: [Track] = []
        let fileManager = FileManager.default
        let audioExtensions = ["mp3", "wav", "aiff", "m4a", "flac", "aac"]
        
        guard let enumerator = fileManager.enumerator(at: directory, includingPropertiesForKeys: [.isRegularFileKey], options: [.skipsHiddenFiles]) else {
            return tracks
        }
        
        for case let fileURL as URL in enumerator {
            guard let resourceValues = try? fileURL.resourceValues(forKeys: [.isRegularFileKey]),
                  resourceValues.isRegularFile == true else {
                continue
            }
            
            let fileExtension = fileURL.pathExtension.lowercased()
            if audioExtensions.contains(fileExtension) {
                let track = Track(url: fileURL)
                tracks.append(track)
            }
        }
        
        return tracks.sorted { $0.title < $1.title }
    }
    
    func savePlaylists() {
        do {
            let data = try JSONEncoder().encode(playlists)
            try data.write(to: playlistsURL)
        } catch {
            print("Failed to save playlists: \(error)")
        }
    }
    
    private func loadPlaylists() {
        guard FileManager.default.fileExists(atPath: playlistsURL.path) else { return }
        
        do {
            let data = try Data(contentsOf: playlistsURL)
            playlists = try JSONDecoder().decode([Playlist].self, from: data)
        } catch {
            print("Failed to load playlists: \(error)")
        }
    }
}
