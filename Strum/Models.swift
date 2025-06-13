//
//  Models.swift
//  Strum
//
//  Created by leongo on 13/6/25.
//

import Foundation
import AVFoundation
import AppKit
import CoreGraphics

// MARK: - Track Model
struct Track: Identifiable, Codable, Hashable {
    let id = UUID()
    let url: URL
    let title: String
    let artist: String?
    let album: String?
    let duration: TimeInterval
    let trackNumber: Int?
    let artworkData: Data?
    let bookmarkData: Data?
    
    init(url: URL) {
        self.url = url

        // Create security-scoped bookmark for persistent file access
        do {
            self.bookmarkData = try url.bookmarkData(options: [.withSecurityScope, .securityScopeAllowOnlyReadAccess], includingResourceValuesForKeys: nil, relativeTo: nil)
        } catch {
            print("Failed to create bookmark for \(url): \(error)")
            self.bookmarkData = nil
        }

        // Extract metadata from the audio file
        let asset = AVURLAsset(url: url)

        // Try to extract metadata first
        var extractedTitle: String?
        var extractedArtist: String?
        var extractedAlbum: String?
        var extractedTrackNumber: Int?
        var extractedArtworkData: Data?

        // Extract metadata using AVFoundation
        print("🎵 Processing file: \(url.lastPathComponent)")

        // Try multiple metadata sources
        let allMetadata = asset.metadata
        print("🎵 Found \(allMetadata.count) total metadata items")

        // First, try to extract from all available metadata
        for item in allMetadata {
            print("🎵 Checking item with identifier: \(item.identifier?.rawValue ?? "unknown")")
            print("🎵 Common key: \(item.commonKey?.rawValue ?? "none")")

            // Try common key first
            if let key = item.commonKey {
                switch key {
                case .commonKeyTitle:
                    if extractedTitle == nil {
                        extractedTitle = item.stringValue
                        print("🎵 Found title: \(extractedTitle ?? "nil")")
                    }
                case .commonKeyArtist:
                    if extractedArtist == nil {
                        extractedArtist = item.stringValue
                        print("🎵 Found artist: \(extractedArtist ?? "nil")")
                    }
                case .commonKeyAlbumName:
                    if extractedAlbum == nil {
                        extractedAlbum = item.stringValue
                        print("🎵 Found album: \(extractedAlbum ?? "nil")")
                    }
                case .commonKeyArtwork:
                    if extractedArtworkData == nil {
                        extractedArtworkData = item.dataValue
                        print("🎵 Found artwork data: \(extractedArtworkData?.count ?? 0) bytes")
                    }
                default:
                    break
                }
            }

            // Also check by identifier for FLAC-specific tags
            if let identifier = item.identifier {
                switch identifier.rawValue {
                case "org.xiph.flac.TITLE":
                    if extractedTitle == nil {
                        extractedTitle = item.stringValue
                        print("🎵 Found FLAC title: \(extractedTitle ?? "nil")")
                    }
                case "org.xiph.flac.ARTIST":
                    if extractedArtist == nil {
                        extractedArtist = item.stringValue
                        print("🎵 Found FLAC artist: \(extractedArtist ?? "nil")")
                    }
                case "org.xiph.flac.ALBUM":
                    if extractedAlbum == nil {
                        extractedAlbum = item.stringValue
                        print("🎵 Found FLAC album: \(extractedAlbum ?? "nil")")
                    }
                case "org.xiph.flac.TRACKNUMBER":
                    if extractedTrackNumber == nil {
                        if let number = item.numberValue {
                            extractedTrackNumber = number.intValue
                            print("🎵 Found FLAC track number: \(extractedTrackNumber ?? 0)")
                        }
                    }
                default:
                    break
                }
            }
        }

        // Special handling for artwork in FLAC files
        // FLAC artwork is often stored as attached pictures (video streams)
        if extractedArtworkData == nil {
            let tracks = asset.tracks
            for track in tracks {
                if track.mediaType == .video {
                    print("🎵 Found video track (likely artwork), attempting to extract...")

                    // Use AVAssetImageGenerator to extract the artwork
                    let imageGenerator = AVAssetImageGenerator(asset: asset)
                    imageGenerator.appliesPreferredTrackTransform = true
                    imageGenerator.maximumSize = CGSize(width: 500, height: 500) // Reasonable size limit

                    do {
                        let cgImage = try imageGenerator.copyCGImage(at: CMTime.zero, actualTime: nil)
                        let nsImage = NSImage(cgImage: cgImage, size: NSSize(width: cgImage.width, height: cgImage.height))

                        // Convert NSImage to Data
                        if let tiffData = nsImage.tiffRepresentation,
                           let bitmapRep = NSBitmapImageRep(data: tiffData),
                           let jpegData = bitmapRep.representation(using: .jpeg, properties: [.compressionFactor: 0.8]) {
                            extractedArtworkData = jpegData
                            print("🎵 Successfully extracted artwork: \(jpegData.count) bytes")
                        }
                    } catch {
                        print("🎵 Failed to extract artwork: \(error)")
                    }
                    break
                }
            }
        }

        // Parse filename if metadata is not available
        let filename = url.deletingPathExtension().lastPathComponent

        if extractedTitle == nil || extractedArtist == nil {
            let parsedInfo = Self.parseFilename(filename)
            if extractedTitle == nil {
                extractedTitle = parsedInfo.title
            }
            if extractedArtist == nil {
                extractedArtist = parsedInfo.artist
            }
        }

        // Set final values
        self.title = extractedTitle ?? filename
        self.artist = extractedArtist
        self.album = extractedAlbum
        self.trackNumber = extractedTrackNumber
        self.artworkData = extractedArtworkData

        // Get duration
        let duration = asset.duration
        self.duration = duration.seconds.isFinite ? duration.seconds : 0
    }

    // Helper method to parse filename for artist and title
    private static func parseFilename(_ filename: String) -> (title: String, artist: String?) {
        // Check for "Artist - Title" pattern
        if filename.contains(" - ") {
            let components = filename.components(separatedBy: " - ")
            if components.count >= 2 {
                let artist = components[0].trimmingCharacters(in: .whitespacesAndNewlines)
                let title = components[1].trimmingCharacters(in: .whitespacesAndNewlines)

                if !artist.isEmpty && !title.isEmpty {
                    return (title: title, artist: artist)
                }
            }
        }

        // Check for "by" pattern
        if filename.lowercased().contains(" by ") {
            let components = filename.components(separatedBy: " by ")
            if components.count == 2 {
                let title = components[0].trimmingCharacters(in: .whitespacesAndNewlines)
                let artist = components[1].trimmingCharacters(in: .whitespacesAndNewlines)

                if !title.isEmpty && !artist.isEmpty {
                    return (title: title, artist: artist)
                }
            }
        }

        // If no pattern matches, return the whole filename as title
        return (title: filename, artist: nil)
    }

    // Helper method to get NSImage from artwork data
    var artwork: NSImage? {
        guard let artworkData = artworkData else {
            print("🎵 No artwork data for: \(title)")
            return nil
        }

        let image = NSImage(data: artworkData)
        print("🎵 Created NSImage for \(title): \(image != nil ? "SUCCESS" : "FAILED") from \(artworkData.count) bytes")
        return image
    }

    // Helper method to resolve URL from security-scoped bookmark
    func resolveURL() -> URL? {
        guard let bookmarkData = bookmarkData else {
            // Fallback to original URL if no bookmark data
            return url
        }

        do {
            var isStale = false
            let resolvedURL = try URL(resolvingBookmarkData: bookmarkData, options: [.withSecurityScope], relativeTo: nil, bookmarkDataIsStale: &isStale)

            if isStale {
                print("Bookmark is stale for track: \(title)")
                // Could potentially refresh the bookmark here if needed
            }

            return resolvedURL
        } catch {
            print("Failed to resolve bookmark for track \(title): \(error)")
            // Fallback to original URL
            return url
        }
    }

    // Helper method to start accessing security-scoped resource
    func startAccessingSecurityScopedResource() -> Bool {
        guard let resolvedURL = resolveURL() else { return false }
        return resolvedURL.startAccessingSecurityScopedResource()
    }

    // Helper method to stop accessing security-scoped resource
    func stopAccessingSecurityScopedResource() {
        guard let resolvedURL = resolveURL() else { return }
        resolvedURL.stopAccessingSecurityScopedResource()
    }
}

// MARK: - Playlist Model
class Playlist: ObservableObject, Identifiable, Codable, Equatable {
    let id: UUID
    @Published var name: String
    @Published var tracks: [Track]
    let createdAt: Date

    init(name: String, tracks: [Track] = []) {
        self.id = UUID()
        self.name = name
        self.tracks = tracks
        self.createdAt = Date()
    }

    // MARK: - Codable Implementation
    enum CodingKeys: String, CodingKey {
        case id, name, tracks, createdAt
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        tracks = try container.decode([Track].self, forKey: .tracks)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(tracks, forKey: .tracks)
        try container.encode(createdAt, forKey: .createdAt)
    }
    
    func addTrack(_ track: Track) {
        tracks.append(track)
    }
    
    func removeTrack(at index: Int) {
        guard index < tracks.count else { return }
        tracks.remove(at: index)
    }
    
    func moveTrack(from source: IndexSet, to destination: Int) {
        tracks.move(fromOffsets: source, toOffset: destination)
    }

    // MARK: - Equatable
    static func == (lhs: Playlist, rhs: Playlist) -> Bool {
        return lhs.id == rhs.id
    }
}

// MARK: - Player State
enum PlayerState {
    case stopped
    case playing
    case paused
}

// MARK: - Shuffle Mode
enum ShuffleMode {
    case off
    case tracks
}

// MARK: - Repeat Mode
enum RepeatMode {
    case off
    case playlist
    case track
}

// MARK: - Music Player Manager
class MusicPlayerManager: ObservableObject {
    @Published var currentTrack: Track?
    @Published var currentPlaylist: Playlist?
    @Published var playerState: PlayerState = .stopped
    @Published var currentTime: TimeInterval = 0
    @Published var volume: Float = 0.5
    @Published var shuffleMode: ShuffleMode = .off
    @Published var repeatMode: RepeatMode = .off

    private var audioPlayer: AVAudioPlayer?
    private var timer: Timer?
    private var shuffledIndices: [Int] = []
    private var currentShuffleIndex: Int = 0
    
    init() {
        // No audio session setup needed on macOS
    }
    
    func play(track: Track, in playlist: Playlist) {
        currentTrack = track
        currentPlaylist = playlist

        // Update shuffle indices if needed
        if shuffleMode == .tracks && (shuffledIndices.isEmpty || currentPlaylist != playlist) {
            generateShuffledIndices()
        }

        // Update current shuffle index
        if shuffleMode == .tracks, let currentIndex = playlist.tracks.firstIndex(of: track) {
            currentShuffleIndex = shuffledIndices.firstIndex(of: currentIndex) ?? 0
        }

        // Start accessing security-scoped resource
        guard track.startAccessingSecurityScopedResource() else {
            print("Failed to access security-scoped resource for track: \(track.title)")
            return
        }

        defer {
            track.stopAccessingSecurityScopedResource()
        }

        do {
            guard let resolvedURL = track.resolveURL() else {
                print("Failed to resolve URL for track: \(track.title)")
                return
            }

            audioPlayer = try AVAudioPlayer(contentsOf: resolvedURL)
            audioPlayer?.volume = volume
            audioPlayer?.play()
            playerState = .playing
            startTimer()
        } catch {
            print("Failed to play track: \(error)")
            print("Track URL: \(track.url)")
            if let resolvedURL = track.resolveURL() {
                print("Resolved URL: \(resolvedURL)")
            }
        }
    }
    
    func pause() {
        audioPlayer?.pause()
        playerState = .paused
        stopTimer()
    }
    
    func resume() {
        audioPlayer?.play()
        playerState = .playing
        startTimer()
    }
    
    func stop() {
        audioPlayer?.stop()
        audioPlayer = nil
        playerState = .stopped
        currentTime = 0
        stopTimer()
    }
    
    func seek(to time: TimeInterval) {
        audioPlayer?.currentTime = time
        currentTime = time
    }
    
    func setVolume(_ newVolume: Float) {
        volume = newVolume
        audioPlayer?.volume = newVolume
    }

    func toggleShuffle() {
        shuffleMode = shuffleMode == .off ? .tracks : .off
        if shuffleMode == .tracks {
            generateShuffledIndices()
        } else {
            shuffledIndices.removeAll()
            currentShuffleIndex = 0
        }
    }

    func toggleRepeat() {
        switch repeatMode {
        case .off:
            repeatMode = .playlist
        case .playlist:
            repeatMode = .track
        case .track:
            repeatMode = .off
        }
    }

    private func generateShuffledIndices() {
        guard let playlist = currentPlaylist else { return }
        shuffledIndices = Array(0..<playlist.tracks.count).shuffled()

        // Find current track in shuffled indices
        if let currentTrack = currentTrack,
           let currentIndex = playlist.tracks.firstIndex(of: currentTrack),
           let shuffleIndex = shuffledIndices.firstIndex(of: currentIndex) {
            currentShuffleIndex = shuffleIndex
        }
    }
    
    func nextTrack() {
        guard let playlist = currentPlaylist else { return }

        // Handle repeat track mode
        if repeatMode == .track, let currentTrack = currentTrack {
            play(track: currentTrack, in: playlist)
            return
        }

        var nextTrack: Track?

        if shuffleMode == .tracks && !shuffledIndices.isEmpty {
            // Shuffle mode
            currentShuffleIndex += 1
            if currentShuffleIndex >= shuffledIndices.count {
                if repeatMode == .playlist {
                    currentShuffleIndex = 0
                } else {
                    return // End of shuffled playlist
                }
            }
            let nextIndex = shuffledIndices[currentShuffleIndex]
            nextTrack = playlist.tracks[nextIndex]
        } else {
            // Normal sequential mode
            guard let currentTrack = currentTrack,
                  let currentIndex = playlist.tracks.firstIndex(of: currentTrack) else { return }

            let nextIndex = currentIndex + 1
            if nextIndex < playlist.tracks.count {
                nextTrack = playlist.tracks[nextIndex]
            } else if repeatMode == .playlist {
                nextTrack = playlist.tracks.first
            }
        }

        if let track = nextTrack {
            play(track: track, in: playlist)
        }
    }
    
    func previousTrack() {
        guard let playlist = currentPlaylist else { return }

        // Handle repeat track mode
        if repeatMode == .track, let currentTrack = currentTrack {
            play(track: currentTrack, in: playlist)
            return
        }

        var previousTrack: Track?

        if shuffleMode == .tracks && !shuffledIndices.isEmpty {
            // Shuffle mode
            currentShuffleIndex -= 1
            if currentShuffleIndex < 0 {
                if repeatMode == .playlist {
                    currentShuffleIndex = shuffledIndices.count - 1
                } else {
                    return // Beginning of shuffled playlist
                }
            }
            let previousIndex = shuffledIndices[currentShuffleIndex]
            previousTrack = playlist.tracks[previousIndex]
        } else {
            // Normal sequential mode
            guard let currentTrack = currentTrack,
                  let currentIndex = playlist.tracks.firstIndex(of: currentTrack) else { return }

            let previousIndex = currentIndex - 1
            if previousIndex >= 0 {
                previousTrack = playlist.tracks[previousIndex]
            } else if repeatMode == .playlist {
                previousTrack = playlist.tracks.last
            }
        }

        if let track = previousTrack {
            play(track: track, in: playlist)
        }
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            if let player = self.audioPlayer {
                self.currentTime = player.currentTime
                
                // Check if track finished
                if !player.isPlaying && self.playerState == .playing {
                    self.nextTrack()
                }
            }
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
}
