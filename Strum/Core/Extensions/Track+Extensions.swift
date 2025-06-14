//
//  Track+Extensions.swift
//  Strum
//
//  Created by leongo on 14/6/25.
//  Refactored on 14/6/25 for better code organization
//

import Foundation

// MARK: - Track Extensions

/**
 * Extensions to the Track model providing additional functionality.
 * 
 * These extensions add utility methods and computed properties
 * that enhance the Track model without cluttering the main
 * model definition.
 */
extension Track {
    
    // MARK: - Formatting Utilities
    
    /**
     * Returns a formatted duration string in MM:SS or HH:MM:SS format.
     * 
     * Automatically chooses the appropriate format based on duration:
     * - Tracks under 1 hour: "MM:SS" (e.g., "3:45")
     * - Tracks 1 hour or longer: "H:MM:SS" (e.g., "1:23:45")
     * 
     * - Returns: A formatted duration string
     */
    var formattedDuration: String {
        let totalSeconds = Int(duration)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }
    
    /**
     * Returns a formatted file size string if available.
     * 
     * Attempts to get the file size from the track's URL and
     * formats it in a human-readable format (KB, MB, GB).
     * 
     * - Returns: A formatted file size string, or "Unknown" if unavailable
     */
    var formattedFileSize: String {
        guard let resolvedURL = resolveURL() else {
            return "Unknown"
        }
        
        do {
            let resourceValues = try resolvedURL.resourceValues(forKeys: [.fileSizeKey])
            if let fileSize = resourceValues.fileSize {
                return ByteCountFormatter.string(fromByteCount: Int64(fileSize), countStyle: .file)
            }
        } catch {
            // Silently fail and return unknown
        }
        
        return "Unknown"
    }
    
    /**
     * Returns a comprehensive info string combining quality and file size.
     * 
     * Combines the quality string (format + bitrate) with file size
     * information for display in detailed views.
     * 
     * Example: "FLAC • 1411k • 45.2 MB"
     * 
     * - Returns: A formatted info string with quality and size details
     */
    var detailedInfo: String {
        let quality = qualityString
        let size = formattedFileSize
        
        if size != "Unknown" {
            return "\(quality) • \(size)"
        } else {
            return quality
        }
    }
    
    // MARK: - Display Utilities
    
    /**
     * Returns the display title for the track.
     * 
     * Uses the track title, falling back to the filename if no title
     * metadata is available.
     * 
     * - Returns: The best available title for display
     */
    var displayTitle: String {
        return title.isEmpty ? url.deletingPathExtension().lastPathComponent : title
    }
    
    /**
     * Returns the display artist for the track.
     * 
     * Uses the track artist, falling back to "Unknown Artist" if no
     * artist metadata is available.
     * 
     * - Returns: The artist name or a fallback string
     */
    var displayArtist: String {
        return artist?.isEmpty == false ? artist! : "Unknown Artist"
    }
    
    /**
     * Returns the display album for the track.
     * 
     * Uses the track album, falling back to "Unknown Album" if no
     * album metadata is available.
     * 
     * - Returns: The album name or a fallback string
     */
    var displayAlbum: String {
        return album?.isEmpty == false ? album! : "Unknown Album"
    }
    
    // MARK: - Search and Filtering
    
    /**
     * Checks if the track matches a search query.
     * 
     * Performs case-insensitive matching against the track's title,
     * artist, and album fields. Returns true if any field contains
     * the search query.
     * 
     * - Parameter query: The search query string
     * - Returns: true if the track matches the query, false otherwise
     */
    func matches(searchQuery query: String) -> Bool {
        guard !query.isEmpty else { return true }
        
        let lowercaseQuery = query.lowercased()
        
        // Check title
        if title.lowercased().contains(lowercaseQuery) {
            return true
        }
        
        // Check artist
        if let artist = artist, artist.lowercased().contains(lowercaseQuery) {
            return true
        }
        
        // Check album
        if let album = album, album.lowercased().contains(lowercaseQuery) {
            return true
        }
        
        return false
    }
    
    // MARK: - Validation
    
    /**
     * Checks if the track's file still exists and is accessible.
     * 
     * Attempts to resolve the track's URL and verify that the file
     * exists at that location. Useful for detecting moved or deleted files.
     * 
     * - Returns: true if the file exists and is accessible, false otherwise
     */
    var isFileAccessible: Bool {
        guard let resolvedURL = resolveURL() else {
            return false
        }
        
        // Start accessing security-scoped resource if needed
        let wasAccessingResource = startAccessingSecurityScopedResource()
        defer {
            if wasAccessingResource {
                stopAccessingSecurityScopedResource()
            }
        }
        
        return FileManager.default.fileExists(atPath: resolvedURL.path)
    }
    
    /**
     * Validates that the track has minimum required metadata.
     * 
     * Checks that the track has at least a title and a valid duration.
     * Useful for filtering out corrupted or incomplete track data.
     * 
     * - Returns: true if the track has valid metadata, false otherwise
     */
    var hasValidMetadata: Bool {
        return !title.isEmpty && duration > 0
    }
}
