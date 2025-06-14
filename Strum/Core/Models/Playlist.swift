//
//  Playlist.swift
//  Strum
//
//  Created by leongo on 13/6/25.
//  Refactored on 14/6/25 for better code organization
//

import Foundation

// MARK: - Playlist Model

/**
 * Represents a music playlist containing a collection of tracks.
 * 
 * This class manages:
 * - Track collection and ordering
 * - Playlist metadata (name, creation date)
 * - Persistence through Codable conformance
 * - Observable changes for UI updates
 * 
 * The Playlist class is designed to work seamlessly with SwiftUI's
 * data binding system through ObservableObject conformance.
 */
class Playlist: ObservableObject, Identifiable, Codable, Equatable {
    // MARK: - Properties
    
    /// Unique identifier for the playlist
    let id: UUID
    
    /// User-defined name for the playlist
    @Published var name: String
    
    /// Collection of tracks in the playlist
    @Published var tracks: [Track]
    
    /// Timestamp when the playlist was created
    let createdAt: Date

    // MARK: - Initialization
    
    /**
     * Creates a new playlist with the specified name and optional tracks.
     * 
     * - Parameters:
     *   - name: The display name for the playlist
     *   - tracks: Initial tracks to add to the playlist (defaults to empty)
     */
    init(name: String, tracks: [Track] = []) {
        self.id = UUID()
        self.name = name
        self.tracks = tracks
        self.createdAt = Date()
    }

    // MARK: - Codable Implementation
    
    /// Coding keys for JSON serialization
    enum CodingKeys: String, CodingKey {
        case id, name, tracks, createdAt
    }

    /**
     * Initializes a playlist from decoded data.
     * 
     * This initializer is required for Codable conformance and handles
     * the deserialization of playlist data from JSON storage.
     * 
     * - Parameter decoder: The decoder containing the playlist data
     * - Throws: DecodingError if the data is malformed
     */
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        tracks = try container.decode([Track].self, forKey: .tracks)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
    }
    
    /**
     * Encodes the playlist to data for storage.
     * 
     * This method handles the serialization of playlist data to JSON format
     * for persistent storage.
     * 
     * - Parameter encoder: The encoder to write the playlist data to
     * - Throws: EncodingError if the data cannot be encoded
     */
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(tracks, forKey: .tracks)
        try container.encode(createdAt, forKey: .createdAt)
    }
    
    // MARK: - Track Management
    
    /**
     * Adds a track to the end of the playlist.
     * 
     * This method appends a new track to the playlist and triggers
     * UI updates through the @Published property wrapper.
     * 
     * - Parameter track: The track to add to the playlist
     */
    func addTrack(_ track: Track) {
        tracks.append(track)
    }
    
    /**
     * Removes a track at the specified index.
     * 
     * This method safely removes a track from the playlist if the
     * index is valid, preventing out-of-bounds errors.
     * 
     * - Parameter index: The index of the track to remove
     */
    func removeTrack(at index: Int) {
        guard index < tracks.count else { return }
        tracks.remove(at: index)
    }
    
    /**
     * Moves tracks from one position to another within the playlist.
     * 
     * This method enables drag-and-drop reordering functionality
     * in the user interface.
     * 
     * - Parameters:
     *   - source: The indices of tracks to move
     *   - destination: The destination index for the moved tracks
     */
    func moveTrack(from source: IndexSet, to destination: Int) {
        tracks.move(fromOffsets: source, toOffset: destination)
    }

    // MARK: - Equatable Conformance
    
    /**
     * Determines equality between two playlists based on their unique identifiers.
     * 
     * Two playlists are considered equal if they have the same UUID,
     * regardless of their content or metadata.
     * 
     * - Parameters:
     *   - lhs: The first playlist to compare
     *   - rhs: The second playlist to compare
     * - Returns: true if the playlists have the same ID, false otherwise
     */
    static func == (lhs: Playlist, rhs: Playlist) -> Bool {
        return lhs.id == rhs.id
    }
    
    // MARK: - Computed Properties
    
    /**
     * Returns the total duration of all tracks in the playlist.
     * 
     * This computed property calculates the sum of all track durations
     * and can be used to display total playlist length in the UI.
     * 
     * - Returns: Total duration in seconds
     */
    var totalDuration: TimeInterval {
        return tracks.reduce(0) { $0 + $1.duration }
    }
    
    /**
     * Returns the number of tracks in the playlist.
     * 
     * This computed property provides a convenient way to get the track count
     * for display purposes.
     * 
     * - Returns: The number of tracks in the playlist
     */
    var trackCount: Int {
        return tracks.count
    }
    
    /**
     * Returns a formatted string describing the playlist contents.
     * 
     * This property generates a user-friendly description of the playlist
     * including track count and total duration.
     * 
     * - Returns: A formatted description string (e.g., "15 tracks • 1h 23m")
     */
    var description: String {
        let trackText = trackCount == 1 ? "track" : "tracks"
        let duration = totalDuration
        let hours = Int(duration) / 3600
        let minutes = Int(duration) % 3600 / 60
        
        var components = ["\(trackCount) \(trackText)"]
        
        if hours > 0 {
            components.append("\(hours)h \(minutes)m")
        } else if minutes > 0 {
            components.append("\(minutes)m")
        }
        
        return components.joined(separator: " • ")
    }
}
