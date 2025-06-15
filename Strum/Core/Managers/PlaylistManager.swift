//
//  PlaylistManager.swift
//  Strum
//
//  Created by leongo on 13/6/25.
//  Refactored on 14/6/25 for better code organization
//

import Foundation
import AppKit
import UniformTypeIdentifiers

// MARK: - UTType Extensions for FLAC support

/**
 * Extension to add FLAC file type support to UTType.
 *
 * This extension ensures that FLAC files are properly recognized
 * as audio files in file selection dialogs and drag-and-drop operations.
 */
extension UTType {
    /// FLAC audio file type identifier
    static var flac: UTType {
        UTType(filenameExtension: "flac") ?? UTType.audio
    }
}

// MARK: - Playlist Manager

/**
 * Manages playlist creation, modification, and audio file importing.
 *
 * This class handles:
 * - Playlist CRUD operations (create, read, update, delete)
 * - Audio file importing from files and folders
 * - Progress tracking for long-running import operations
 * - Persistent storage of playlist data
 * - Security-scoped resource management for sandboxed file access
 *
 * The PlaylistManager uses debounced saving to improve performance
 * during rapid changes and provides progress callbacks for UI updates.
 */
class PlaylistManager: ObservableObject {
    // MARK: - Published Properties

    /// Array of all playlists managed by this instance
    @Published var playlists: [Playlist] = []

    /// Currently selected playlist for display and operations
    @Published var selectedPlaylist: Playlist?

    // MARK: - Import Progress Tracking

    /// Indicates whether an import operation is currently in progress
    @Published var isImporting: Bool = false

    /// Progress value from 0.0 to 1.0 for the current import operation
    @Published var importProgress: Double = 0.0

    /// Name of the file currently being processed during import
    @Published var importCurrentFile: String = ""

    /// Total number of files to be imported in the current operation
    @Published var importTotalFiles: Int = 0

    /// Number of files that have been processed so far
    @Published var importProcessedFiles: Int = 0

    // MARK: - Callbacks

    /// Callback function to display success toast notifications
    var onImportSuccess: ((String) -> Void)?

    // MARK: - Private Properties

    /// Documents directory URL for storing playlist data
    private let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!

    /// URL for the playlist storage file
    private var playlistsURL: URL {
        documentsURL.appendingPathComponent("Strum_Playlists.json")
    }

    /// Work item for debounced save operations to improve performance
    private var saveWorkItem: DispatchWorkItem?

    /// Background queue for save operations to avoid blocking the main thread
    private let saveQueue = DispatchQueue(label: "playlist.save", qos: .utility)

    // MARK: - Initialization

    /**
     * Initializes the playlist manager.
     *
     * Loads existing playlists from storage, creates a default playlist
     * if none exist, and selects the first playlist.
     */
    init() {
        loadPlaylists()
        if playlists.isEmpty {
            createDefaultPlaylist()
        }
        selectedPlaylist = playlists.first
    }

    // MARK: - Playlist Management

    /**
     * Creates a default "My Music" playlist.
     *
     * This method is called during initialization if no playlists exist,
     * ensuring the user always has at least one playlist to work with.
     */
    private func createDefaultPlaylist() {
        let defaultPlaylist = Playlist(name: "My Music")
        playlists.append(defaultPlaylist)
        savePlaylists()
    }

    /**
     * Creates a new playlist with the specified name.
     *
     * The newly created playlist is automatically selected as the current playlist.
     *
     * - Parameter name: The name for the new playlist
     * - Returns: The newly created playlist
     */
    func createPlaylist(name: String) -> Playlist {
        let newPlaylist = Playlist(name: name)
        playlists.append(newPlaylist)
        selectedPlaylist = newPlaylist
        savePlaylists()
        return newPlaylist
    }

    /**
     * Deletes the specified playlist.
     *
     * If the deleted playlist was currently selected, automatically
     * selects the first available playlist.
     *
     * - Parameter playlist: The playlist to delete
     */
    func deletePlaylist(_ playlist: Playlist) {
        playlists.removeAll { $0.id == playlist.id }

        // If we deleted the selected playlist, select another one
        if selectedPlaylist?.id == playlist.id {
            selectedPlaylist = playlists.first
        }

        savePlaylists()
    }

    /**
     * Renames an existing playlist.
     *
     * - Parameters:
     *   - playlist: The playlist to rename
     *   - newName: The new name for the playlist
     */
    func renamePlaylist(_ playlist: Playlist, to newName: String) {
        playlist.name = newName
        savePlaylists()
    }

    /**
     * Selects a playlist as the currently active playlist.
     *
     * - Parameter playlist: The playlist to select
     */
    func selectPlaylist(_ playlist: Playlist) {
        selectedPlaylist = playlist
    }

    // MARK: - File Import Operations

    /**
     * Presents a file selection dialog and imports selected audio files.
     *
     * This method:
     * - Shows an NSOpenPanel configured for audio file selection
     * - Supports multiple file selection
     * - Processes files in the background with progress tracking
     * - Handles security-scoped resource access for sandboxed apps
     * - Updates the UI with import progress
     * - Shows success notifications upon completion
     */
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

            // Process files in background to avoid blocking the UI
            DispatchQueue.global(qos: .userInitiated).async {
                var successfulTracks: [Track] = []
                let totalFiles = urls.count

                for (index, url) in urls.enumerated() {
                    let currentIndex = index + 1

                    // Update current file on main thread for UI responsiveness
                    DispatchQueue.main.async {
                        self.importCurrentFile = url.lastPathComponent
                        self.importProcessedFiles = currentIndex
                        self.importProgress = Double(currentIndex) / Double(totalFiles)
                    }

                    // Create security-scoped bookmark for sandboxed file access
                    guard url.startAccessingSecurityScopedResource() else {
                        print("Failed to access security scoped resource: \(url)")
                        continue
                    }
                    defer { url.stopAccessingSecurityScopedResource() }

                    // Create track with metadata extraction
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

                        // Show success toast notification
                        let message = successfulTracks.count == 1 ? "1 file imported successfully" : "\(successfulTracks.count) files imported successfully"
                        self.onImportSuccess?(message)
                    }
                }
            }
        }
    }

    /**
     * Presents a folder selection dialog and imports all audio files from the selected folder.
     *
     * This method recursively scans the selected folder for audio files
     * and imports them with progress tracking. It handles security-scoped
     * resource access for sandboxed applications.
     */
    func importFolder() {
        let openPanel = NSOpenPanel()
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseDirectories = true
        openPanel.canChooseFiles = false

        if openPanel.runModal() == .OK {
            guard let folderURL = openPanel.urls.first else { return }

            // Create security-scoped bookmark for folder access
            guard folderURL.startAccessingSecurityScopedResource() else {
                print("Failed to access security scoped resource: \(folderURL)")
                return
            }
            defer { folderURL.stopAccessingSecurityScopedResource() }

            importFolderWithProgress(folderURL)
        }
    }

    /**
     * Imports audio files from a folder URL (typically from drag-and-drop operations).
     *
     * This method is used when a folder is dragged into the application.
     * For drag-and-drop operations, the system grants temporary access
     * to the files, so security-scoped resource access is not required.
     *
     * - Parameter folderURL: The URL of the folder to import from
     */
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

    // MARK: - Persistence Operations

    /**
     * Saves playlists to persistent storage with debouncing.
     *
     * This method implements debouncing to prevent excessive disk writes
     * during rapid changes (e.g., when importing many files). The actual
     * save operation is delayed by 0.1 seconds and any pending saves are
     * cancelled when a new save is requested.
     */
    func savePlaylists() {
        // Cancel any pending save operation to implement debouncing
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

    /**
     * Performs the actual save operation to disk.
     *
     * Encodes the playlists array to JSON and writes it to the
     * designated storage file in the user's Documents directory.
     */
    private func performSave() {
        do {
            let data = try JSONEncoder().encode(playlists)
            try data.write(to: playlistsURL)
        } catch {
            print("Failed to save playlists: \(error)")
        }
    }

    /**
     * Forces an immediate save operation without debouncing.
     *
     * This method is useful for critical save operations such as
     * app termination where we need to ensure data is persisted
     * immediately.
     */
    func savePlaylistsImmediately() {
        saveWorkItem?.cancel()
        performSave()
    }

    /**
     * Loads playlists from persistent storage.
     *
     * Attempts to read and decode playlist data from the storage file.
     * If the file doesn't exist or cannot be decoded, the operation
     * fails silently and the playlists array remains empty.
     */
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

/**
 * Extension to Array that provides batching functionality.
 *
 * This extension is used to split large arrays into smaller chunks
 * for processing, which helps maintain UI responsiveness during
 * long-running operations like importing many files.
 */
extension Array {
    /**
     * Splits the array into chunks of the specified size.
     *
     * - Parameter size: The maximum size of each chunk
     * - Returns: An array of arrays, where each sub-array contains at most `size` elements
     */
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}
