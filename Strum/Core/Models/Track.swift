//
//  Track.swift
//  Strum
//
//  Created by leongo on 13/6/25.
//  Refactored on 14/6/25 for better code organization
//

import Foundation
import AVFoundation
import AppKit
import CoreGraphics
import FLACMetadataKit

// MARK: - Track Model

/**
 * Represents a music track with metadata and file information.
 * 
 * This model handles:
 * - Audio file metadata extraction from various formats (MP3, FLAC, M4A, etc.)
 * - Security-scoped bookmark creation for persistent file access
 * - Artwork extraction and caching
 * - File format and quality information
 * 
 * The Track model uses both FLACMetadataKit and AVFoundation for comprehensive
 * metadata extraction, with special handling for FLAC files to extract embedded artwork.
 */
struct Track: Identifiable, Codable, Hashable {
    // MARK: - Properties
    
    /// Unique identifier for the track
    let id = UUID()
    
    /// Original file URL (may become stale due to sandboxing)
    let url: URL
    
    /// Track title (extracted from metadata or filename)
    let title: String
    
    /// Artist name (optional, extracted from metadata)
    let artist: String?
    
    /// Album name (optional, extracted from metadata)
    let album: String?
    
    /// Track duration in seconds
    let duration: TimeInterval
    
    /// Track number within album (optional)
    let trackNumber: Int?
    
    /// Embedded artwork data (JPEG/PNG format)
    let artworkData: Data?
    
    /// Security-scoped bookmark for persistent file access
    let bookmarkData: Data?
    
    /// File format (e.g., "MP3", "FLAC", "M4A")
    let fileFormat: String
    
    /// Audio bitrate in kbps (optional)
    let bitrate: Int?
    
    // MARK: - Initialization
    
    /**
     * Creates a new Track instance from an audio file URL.
     * 
     * This initializer performs comprehensive metadata extraction:
     * 1. Creates security-scoped bookmarks for file access
     * 2. Extracts metadata using FLACMetadataKit (for FLAC) and AVFoundation
     * 3. Extracts embedded artwork with special FLAC handling
     * 4. Parses filename if metadata is unavailable
     * 5. Determines file format and audio quality
     * 
     * - Parameter url: The URL of the audio file to process
     */
    init(url: URL) {
        self.url = url

        // Create security-scoped bookmark for persistent file access
        // This allows the app to access files even after restart
        do {
            self.bookmarkData = try url.bookmarkData(
                options: [.withSecurityScope, .securityScopeAllowOnlyReadAccess],
                includingResourceValuesForKeys: nil,
                relativeTo: nil
            )
        } catch {
            print("Failed to create bookmark for \(url): \(error)")
            self.bookmarkData = nil
        }

        // Extract metadata from the audio file
        let fileExtension = url.pathExtension.uppercased()
        print("🎵 Processing file: \(url.lastPathComponent) (.\(fileExtension))")

        // Initialize metadata variables
        var extractedTitle: String?
        var extractedArtist: String?
        var extractedAlbum: String?
        var extractedTrackNumber: Int?
        var extractedArtworkData: Data?

        // Try FLACMetadataKit first for FLAC files (better artwork extraction)
        if fileExtension == "FLAC" {
            print("🎵 Using FLACMetadataKit for FLAC artwork extraction")
            do {
                let flacData = try Data(contentsOf: url)
                let parser = FLACParser(data: flacData)
                let metadata = try parser.parse()
                print("🎵 FLACMetadataKit successfully parsed file")

                // Extract artwork using FLACMetadataKit
                if let picture = metadata.picture {
                    extractedArtworkData = picture.data
                    print("🎵 ✅ FLACMetadataKit extracted artwork: \(picture.data.count) bytes, MIME: \(picture.mimeType)")
                } else {
                    print("🎵 ❌ FLACMetadataKit found no picture in FLAC file")
                }

            } catch {
                print("🎵 ❌ FLACMetadataKit failed: \(error), falling back to AVFoundation")
            }
        }

        // Use AVFoundation for missing metadata or non-FLAC files
        let asset = AVURLAsset(url: url)
        if extractedArtworkData == nil || extractedTitle == nil || extractedArtist == nil || extractedAlbum == nil {
            print("🎵 Using AVFoundation for missing metadata or artwork")
            let allMetadata = asset.metadata
            print("🎵 Found \(allMetadata.count) total metadata items via AVFoundation")

            // Extract from all available metadata
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

            // Special handling for artwork in FLAC files via video tracks
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
                                print("🎵 ✅ Successfully extracted artwork via AVFoundation: \(jpegData.count) bytes")
                            }
                        } catch {
                            print("🎵 ❌ Failed to extract artwork via AVFoundation: \(error)")
                        }
                        break
                    }
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

        // Extract file format and quality information
        self.fileFormat = fileExtension

        // Extract bitrate and duration using AVFoundation (always needed)
        var extractedBitrate: Int?
        let audioTracks = asset.tracks(withMediaType: .audio)
        if let audioTrack = audioTracks.first {
            let bitrate = audioTrack.estimatedDataRate
            if bitrate > 0 {
                extractedBitrate = Int(bitrate / 1000) // Convert to kbps
            }
        }
        self.bitrate = extractedBitrate

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

    // MARK: - Helper Methods

    /**
     * Parses a filename to extract artist and title information.
     *
     * Supports common filename patterns:
     * - "Artist - Title"
     * - "Title by Artist"
     *
     * - Parameter filename: The filename to parse (without extension)
     * - Returns: A tuple containing the parsed title and optional artist
     */
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

    // MARK: - Artwork Management

    /// Static cache for artwork images to prevent repeated NSImage creation
    /// Use URL as cache key since it's stable across track recreations
    private static var artworkCache: [URL: NSImage] = [:]
    private static let cacheQueue = DispatchQueue(label: "artwork.cache", qos: .userInitiated, attributes: .concurrent)

    /// Maximum number of cached artwork images to prevent memory growth
    private static let maxCacheSize = 100

    /// Memory pressure source for automatic cache cleanup
    private static var memoryPressureSource: DispatchSourceMemoryPressure?

    /**
     * Gets the NSImage representation of the track's artwork with thread-safe caching.
     *
     * This property provides efficient access to artwork by:
     * - Caching NSImage instances to avoid repeated creation
     * - Using concurrent queues for thread-safe access
     * - Automatically handling data-to-image conversion
     * - Managing cache size to prevent memory growth
     *
     * - Returns: The artwork as NSImage, or nil if no artwork is available
     */
    var artwork: NSImage? {
        guard let artworkData = artworkData else {
            return nil
        }

        // Thread-safe cache access
        return Self.cacheQueue.sync {
            // Check if we have a cached image for this track's URL
            if let cachedImage = Self.artworkCache[url] {
                return cachedImage
            }

            // Create new image and cache it
            if let image = NSImage(data: artworkData) {
                Self.cacheQueue.async(flags: .barrier) {
                    // Check cache size and clean up if needed
                    if Self.artworkCache.count >= Self.maxCacheSize {
                        // Remove oldest entries (simple FIFO approach)
                        let keysToRemove = Array(Self.artworkCache.keys.prefix(Self.maxCacheSize / 2))
                        for key in keysToRemove {
                            Self.artworkCache.removeValue(forKey: key)
                        }
                        print("🎵 Artwork cache cleaned up, removed \(keysToRemove.count) entries")
                    }

                    Self.artworkCache[url] = image
                }
                print("🎵 Created and cached NSImage for \(title): SUCCESS from \(artworkData.count) bytes")
                return image
            } else {
                print("🎵 Failed to create NSImage for \(title) from \(artworkData.count) bytes")
                return nil
            }
        }
    }

    /**
     * Clears the artwork cache to free memory.
     *
     * This method should be called when memory pressure is detected
     * or when the app is backgrounded.
     */
    static func clearArtworkCache() {
        cacheQueue.async(flags: .barrier) {
            let removedCount = artworkCache.count
            artworkCache.removeAll()
            print("🎵 Artwork cache cleared, removed \(removedCount) entries")
        }
    }

    /**
     * Sets up memory pressure monitoring to automatically clear cache when needed.
     * This should be called once during app initialization.
     */
    static func setupMemoryPressureMonitoring() {
        guard memoryPressureSource == nil else { return } // Prevent multiple setups

        let source = DispatchSource.makeMemoryPressureSource(eventMask: .warning, queue: .global(qos: .utility))
        source.setEventHandler {
            print("🎵 Memory pressure detected, clearing artwork cache")
            clearArtworkCache()
        }
        source.resume()
        memoryPressureSource = source // Retain the source
    }

    // MARK: - Quality Information

    /**
     * Returns a formatted string describing the track's audio quality.
     *
     * Combines file format and bitrate information into a user-friendly string.
     * Example: "FLAC • 1411k" or "MP3 • 320k"
     *
     * - Returns: A formatted quality string
     */
    var qualityString: String {
        var components: [String] = []

        // Add file format
        components.append(fileFormat)

        // Add bitrate if available
        if let bitrate = bitrate {
            components.append("\(bitrate)k")
        }

        return components.joined(separator: " • ")
    }

    // MARK: - Security-Scoped Resource Management

    /**
     * Resolves the track's URL from its security-scoped bookmark.
     *
     * This method is essential for accessing files in a sandboxed environment.
     * It attempts to resolve the bookmark data to get a valid URL that can
     * be used to access the file.
     *
     * - Returns: The resolved URL, or the original URL as fallback
     */
    func resolveURL() -> URL? {
        guard let bookmarkData = bookmarkData else {
            // Fallback to original URL if no bookmark data
            return url
        }

        do {
            var isStale = false
            let resolvedURL = try URL(
                resolvingBookmarkData: bookmarkData,
                options: [.withSecurityScope],
                relativeTo: nil,
                bookmarkDataIsStale: &isStale
            )

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

    /**
     * Starts accessing the security-scoped resource for this track.
     *
     * This method must be called before attempting to read the audio file
     * in a sandboxed environment. Always pair with stopAccessingSecurityScopedResource().
     *
     * - Returns: true if access was granted, false otherwise
     */
    func startAccessingSecurityScopedResource() -> Bool {
        guard let resolvedURL = resolveURL() else { return false }
        return resolvedURL.startAccessingSecurityScopedResource()
    }

    /**
     * Stops accessing the security-scoped resource for this track.
     *
     * This method should be called after finishing file operations
     * to properly release the security-scoped resource.
     */
    func stopAccessingSecurityScopedResource() {
        guard let resolvedURL = resolveURL() else { return }
        resolvedURL.stopAccessingSecurityScopedResource()
    }
}
