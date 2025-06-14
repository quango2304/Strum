//
//  PlayerState.swift
//  Strum
//
//  Created by leongo on 13/6/25.
//  Refactored on 14/6/25 for better code organization
//

import Foundation

// MARK: - Player State Enumerations

/**
 * Represents the current state of the music player.
 * 
 * This enumeration defines the three possible states of audio playback:
 * - stopped: No audio is loaded or playing
 * - playing: Audio is currently playing
 * - paused: Audio is loaded but playback is paused
 */
enum PlayerState {
    /// No audio is loaded or playing
    case stopped
    
    /// Audio is currently playing
    case playing
    
    /// Audio is loaded but playback is paused
    case paused
}

// MARK: - Shuffle Mode

/**
 * Represents the shuffle mode for track playback.
 * 
 * This enumeration defines how tracks are selected for playback:
 * - off: Tracks play in their original order
 * - tracks: Tracks play in a randomized order
 */
enum ShuffleMode {
    /// Tracks play in their original order
    case off
    
    /// Tracks play in a randomized order
    case tracks
}

// MARK: - Repeat Mode

/**
 * Represents the repeat mode for track and playlist playback.
 * 
 * This enumeration defines how playback behaves when reaching the end:
 * - off: Playback stops at the end of the playlist
 * - playlist: The entire playlist repeats from the beginning
 * - track: The current track repeats indefinitely
 */
enum RepeatMode {
    /// Playback stops at the end of the playlist
    case off
    
    /// The entire playlist repeats from the beginning
    case playlist
    
    /// The current track repeats indefinitely
    case track
}

// MARK: - Extensions for UI Display

extension PlayerState {
    /**
     * Returns a user-friendly description of the player state.
     * 
     * This computed property provides localized strings that can be
     * displayed in the user interface for accessibility or debugging.
     * 
     * - Returns: A human-readable description of the state
     */
    var description: String {
        switch self {
        case .stopped:
            return "Stopped"
        case .playing:
            return "Playing"
        case .paused:
            return "Paused"
        }
    }
    
    /**
     * Returns the appropriate SF Symbol name for the player state.
     * 
     * This computed property provides the correct system icon name
     * for representing the current state in the user interface.
     * 
     * - Returns: SF Symbol name as a string
     */
    var iconName: String {
        switch self {
        case .stopped:
            return "stop.fill"
        case .playing:
            return "pause.fill"
        case .paused:
            return "play.fill"
        }
    }
}

extension ShuffleMode {
    /**
     * Returns a user-friendly description of the shuffle mode.
     * 
     * - Returns: A human-readable description of the shuffle mode
     */
    var description: String {
        switch self {
        case .off:
            return "Shuffle Off"
        case .tracks:
            return "Shuffle Tracks"
        }
    }
    
    /**
     * Returns the appropriate SF Symbol name for the shuffle mode.
     * 
     * - Returns: SF Symbol name as a string
     */
    var iconName: String {
        switch self {
        case .off:
            return "shuffle"
        case .tracks:
            return "shuffle"
        }
    }
    
    /**
     * Indicates whether shuffle is currently active.
     * 
     * - Returns: true if shuffle is enabled, false otherwise
     */
    var isActive: Bool {
        return self == .tracks
    }
}

extension RepeatMode {
    /**
     * Returns a user-friendly description of the repeat mode.
     * 
     * - Returns: A human-readable description of the repeat mode
     */
    var description: String {
        switch self {
        case .off:
            return "Repeat Off"
        case .playlist:
            return "Repeat Playlist"
        case .track:
            return "Repeat Track"
        }
    }
    
    /**
     * Returns the appropriate SF Symbol name for the repeat mode.
     * 
     * - Returns: SF Symbol name as a string
     */
    var iconName: String {
        switch self {
        case .off:
            return "repeat"
        case .playlist:
            return "repeat"
        case .track:
            return "repeat.1"
        }
    }
    
    /**
     * Indicates whether repeat is currently active.
     * 
     * - Returns: true if any repeat mode is enabled, false otherwise
     */
    var isActive: Bool {
        return self != .off
    }
    
    /**
     * Returns the next repeat mode in the cycle.
     * 
     * This method enables cycling through repeat modes:
     * off → playlist → track → off
     * 
     * - Returns: The next repeat mode in the sequence
     */
    var next: RepeatMode {
        switch self {
        case .off:
            return .playlist
        case .playlist:
            return .track
        case .track:
            return .off
        }
    }
}
