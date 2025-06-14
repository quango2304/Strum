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

    // Progress tracking for imports
    @Published var isImporting: Bool = false
    @Published var importProgress: Double = 0.0
    @Published var importCurrentFile: String = ""
    @Published var importTotalFiles: Int = 0
    @Published var importProcessedFiles: Int = 0

    // Callback for showing toast notifications
    var onImportSuccess: ((String) -> Void)?

    private let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    private var playlistsURL: URL {
        documentsURL.appendingPathComponent("Strum_Playlists.json")
    }

    // Debouncing for save operations to improve performance
    private var saveWorkItem: DispatchWorkItem?
    private let saveQueue = DispatchQueue(label: "playlist.save", qos: .utility)
    
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

    func renamePlaylist(_ playlist: Playlist, to newName: String) {
        playlist.name = newName
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
            let urls = openPanel.urls
            guard let playlist = selectedPlaylist else { return }

            // Start progress tracking with immediate total count
            DispatchQueue.main.async {
                self.isImporting = true
                self.importProgress = 0.0
                self.importTotalFiles = urls.count
                self.importProcessedFiles = 0
                self.importCurrentFile = urls.count == 1 ? "Importing 1 file..." : "Importing \(urls.count) files..."
            }

            // Process files in background
            DispatchQueue.global(qos: .userInitiated).async {
                var successfulTracks: [Track] = []
                let totalFiles = urls.count

                for (index, url) in urls.enumerated() {
                    let currentIndex = index + 1

                    // Update current file on main thread
                    DispatchQueue.main.async {
                        self.importCurrentFile = url.lastPathComponent
                        self.importProcessedFiles = currentIndex
                        self.importProgress = Double(currentIndex) / Double(totalFiles)
                    }

                    // Create security-scoped bookmark
                    guard url.startAccessingSecurityScopedResource() else {
                        print("Failed to access security scoped resource: \(url)")
                        continue
                    }
                    defer { url.stopAccessingSecurityScopedResource() }

                    let track = Track(url: url)
                    successfulTracks.append(track)
                }

                // Add tracks to playlist on main thread
                DispatchQueue.main.async {
                    for track in successfulTracks {
                        playlist.addTrack(track)
                    }
                    self.savePlaylists()

                    // Complete progress and show success
                    self.importProgress = 1.0
                    self.importCurrentFile = "Import complete"

                    // Hide progress after a brief delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                        self.isImporting = false

                        // Show success toast
                        let message = successfulTracks.count == 1 ? "1 file imported successfully" : "\(successfulTracks.count) files imported successfully"
                        self.onImportSuccess?(message)
                    }
                }
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

            importFolderWithProgress(folderURL)
        }
    }

    func importFolderAtURL(_ folderURL: URL) {
        print("importFolderAtURL called with: \(folderURL)")
        // For drag and drop, we don't need security scoped access
        // The system grants temporary access to dragged files
        importFolderWithProgress(folderURL)
    }

    private func importFolderWithProgress(_ folderURL: URL) {
        guard let playlist = selectedPlaylist else { return }

        // Start progress tracking
        DispatchQueue.main.async {
            self.isImporting = true
            self.importProgress = 0.0
            self.importCurrentFile = "Scanning folder..."
            self.importTotalFiles = 0
            self.importProcessedFiles = 0
        }

        // Process folder in background
        DispatchQueue.global(qos: .userInitiated).async {
            // First, quickly count files to show total
            let fileCount = self.countAudioFiles(in: folderURL)

            // Update UI with total count immediately
            DispatchQueue.main.async {
                self.importTotalFiles = fileCount
                self.importCurrentFile = fileCount > 0 ? "Found \(fileCount) audio files..." : "No audio files found"
            }

            guard fileCount > 0 else {
                DispatchQueue.main.async {
                    self.isImporting = false
                }
                return
            }

            // Now process files with progress
            let tracks = self.findAudioFilesWithProgress(in: folderURL)
            print("Found \(tracks.count) audio files")

            guard !tracks.isEmpty else {
                DispatchQueue.main.async {
                    self.isImporting = false
                }
                return
            }

            // Update status for adding tracks
            DispatchQueue.main.async {
                self.importCurrentFile = "Adding tracks to playlist..."
                self.importProgress = 0.0
                self.importProcessedFiles = 0
            }

            // Add tracks to playlist in batches to avoid blocking UI
            let batchSize = 10
            let batches = tracks.chunked(into: batchSize)

            for (batchIndex, batch) in batches.enumerated() {
                DispatchQueue.main.async {
                    let startIndex = batchIndex * batchSize

                    for (index, track) in batch.enumerated() {
                        playlist.addTrack(track)
                        let currentCount = startIndex + index + 1
                        self.importProcessedFiles = currentCount
                        self.importProgress = Double(currentCount) / Double(tracks.count)

                        // Update current file display for the last track in batch
                        if index == batch.count - 1 {
                            self.importCurrentFile = track.title
                        }
                    }

                    // If this is the last batch, complete the import
                    if batchIndex == batches.count - 1 {
                        self.savePlaylists()

                        // Complete progress
                        self.importCurrentFile = "Import complete"
                        self.importProgress = 1.0

                        // Hide progress after a brief delay
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                            self.isImporting = false

                            // Show success toast
                            let message = tracks.count == 1 ? "1 file imported successfully" : "\(tracks.count) files imported successfully"
                            self.onImportSuccess?(message)
                        }
                    }
                }

                // Small delay between batches to keep UI responsive
                Thread.sleep(forTimeInterval: 0.01)
            }
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

    private func findAudioFilesWithProgress(in directory: URL) -> [Track] {
        var tracks: [Track] = []
        let fileManager = FileManager.default
        let audioExtensions = ["mp3", "wav", "aiff", "m4a", "flac", "aac"]

        guard let enumerator = fileManager.enumerator(at: directory, includingPropertiesForKeys: [.isRegularFileKey], options: [.skipsHiddenFiles]) else {
            return tracks
        }

        var fileURLs: [URL] = []

        // First pass: collect all audio file URLs (we already know the count)
        for case let fileURL as URL in enumerator {
            guard let resourceValues = try? fileURL.resourceValues(forKeys: [.isRegularFileKey]),
                  resourceValues.isRegularFile == true else {
                continue
            }

            let fileExtension = fileURL.pathExtension.lowercased()
            if audioExtensions.contains(fileExtension) {
                fileURLs.append(fileURL)
            }
        }

        // Second pass: create tracks with progress updates
        let totalFiles = fileURLs.count
        for (index, fileURL) in fileURLs.enumerated() {
            // Update UI every 5 files or on last file for better responsiveness
            if index % 5 == 0 || index == totalFiles - 1 {
                DispatchQueue.main.async {
                    self.importCurrentFile = "Processing: \(fileURL.lastPathComponent)"
                    self.importProgress = Double(index + 1) / Double(totalFiles)
                    self.importProcessedFiles = index + 1
                }
            }

            let track = Track(url: fileURL)
            tracks.append(track)
        }

        return tracks.sorted { $0.title < $1.title }
    }

    private func countAudioFiles(in directory: URL) -> Int {
        let fileManager = FileManager.default
        let audioExtensions = ["mp3", "wav", "aiff", "m4a", "flac", "aac"]
        var count = 0

        guard let enumerator = fileManager.enumerator(at: directory, includingPropertiesForKeys: [.isRegularFileKey], options: [.skipsHiddenFiles]) else {
            return 0
        }

        for case let fileURL as URL in enumerator {
            guard let resourceValues = try? fileURL.resourceValues(forKeys: [.isRegularFileKey]),
                  resourceValues.isRegularFile == true else {
                continue
            }

            let fileExtension = fileURL.pathExtension.lowercased()
            if audioExtensions.contains(fileExtension) {
                count += 1
            }
        }

        return count
    }

    func savePlaylists() {
        // Cancel any pending save operation
        saveWorkItem?.cancel()

        // Create a new debounced save operation
        let workItem = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            self.performSave()
        }

        saveWorkItem = workItem

        // Execute after a short delay to debounce rapid changes
        saveQueue.asyncAfter(deadline: .now() + 0.1, execute: workItem)
    }

    private func performSave() {
        do {
            let data = try JSONEncoder().encode(playlists)
            try data.write(to: playlistsURL)
        } catch {
            print("Failed to save playlists: \(error)")
        }
    }

    // Force immediate save (useful for app termination)
    func savePlaylistsImmediately() {
        saveWorkItem?.cancel()
        performSave()
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

// MARK: - Array Extension for Batching
extension Array {
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}
