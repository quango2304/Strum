//
//  MusicPlayerManager.swift
//  Strum
//
//  Created by leongo on 13/6/25.
//  Refactored on 14/6/25 for better code organization
//

import Foundation
import AVFoundation
import MediaPlayer
import AppKit

// MARK: - Music Player Manager

/**
 * Manages audio playback functionality for the Strum music player.
 * 
 * This class handles:
 * - Audio playback using AVAudioPlayer
 * - Playlist navigation (next/previous tracks)
 * - Shuffle and repeat modes
 * - Volume control and seeking
 * - Media remote control integration
 * - Now Playing information updates
 * 
 * The MusicPlayerManager integrates with macOS media controls and provides
 * a comprehensive audio playback experience with support for various playback modes.
 */
class MusicPlayerManager: ObservableObject {
    // MARK: - Published Properties
    
    /// Currently playing track
    @Published var currentTrack: Track?
    
    /// Current playlist being played
    @Published var currentPlaylist: Playlist?
    
    /// Current playback state (stopped, playing, paused)
    @Published var playerState: PlayerState = .stopped
    
    /// Current playback position in seconds
    @Published var currentTime: TimeInterval = 0
    
    /// Audio volume (0.0 to 1.0)
    @Published var volume: Float = 0.5
    
    /// Current shuffle mode
    @Published var shuffleMode: ShuffleMode = .off
    
    /// Current repeat mode
    @Published var repeatMode: RepeatMode = .off

    // MARK: - Private Properties
    
    /// The underlying audio player instance
    private var audioPlayer: AVAudioPlayer?
    
    /// Timer for updating playback progress
    private var timer: Timer?

    /// Tracks the last time we updated Now Playing info to ensure 1-second intervals
    private var lastNowPlayingUpdate: TimeInterval = 0
    
    /// Array of shuffled track indices for shuffle mode
    private var shuffledIndices: [Int] = []
    
    /// Current position in the shuffled indices array
    private var currentShuffleIndex: Int = 0
    
    // MARK: - Initialization
    
    /**
     * Initializes the music player manager.
     * 
     * Sets up media remote control integration and app termination handling.
     * Note: No audio session setup is needed on macOS.
     */
    init() {
        setupRemoteCommandCenter()
        setupAppTerminationHandling()
    }
    
    // MARK: - Playback Control
    
    /**
     * Plays a specific track from a playlist.
     *
     * This method:
     * - Sets the current track and playlist
     * - Updates shuffle indices if needed
     * - Handles security-scoped resource access
     * - Initializes and starts the audio player
     * - Updates Now Playing information
     *
     * - Parameters:
     *   - track: The track to play
     *   - playlist: The playlist containing the track
     */
    func play(track: Track, in playlist: Playlist) {
        // Stop current playback and clean up resources first
        stop()

        // Load artwork for the track before setting as current
        var trackWithArtwork = track
        trackWithArtwork.loadArtwork()

        // Update the track in the playlist with the loaded artwork
        if let trackIndex = playlist.tracks.firstIndex(where: { $0.id == track.id }) {
            playlist.tracks[trackIndex] = trackWithArtwork
        }

        currentTrack = trackWithArtwork
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
            updateNowPlayingInfo()
        } catch {
            print("Failed to play track: \(error)")
            print("Track URL: \(track.url)")
            if let resolvedURL = track.resolveURL() {
                print("Resolved URL: \(resolvedURL)")
            }
        }
    }

    /**
     * Plays the first track in a playlist.
     * 
     * Respects shuffle mode when selecting the first track to play.
     * 
     * - Parameter playlist: The playlist to start playing
     */
    func playFirstTrack(in playlist: Playlist) {
        guard !playlist.tracks.isEmpty else { return }

        let firstTrack: Track
        if shuffleMode == .tracks {
            // Generate shuffled indices for the new playlist
            currentPlaylist = playlist
            generateShuffledIndices()
            currentShuffleIndex = 0
            firstTrack = playlist.tracks[shuffledIndices[0]]
        } else {
            firstTrack = playlist.tracks[0]
        }

        play(track: firstTrack, in: playlist)
    }
    
    /**
     * Pauses the current playback.
     * 
     * Stops the progress timer and updates Now Playing information.
     */
    func pause() {
        audioPlayer?.pause()
        playerState = .paused
        stopTimer()
        updateNowPlayingInfo()
    }
    
    /**
     * Resumes paused playback.
     * 
     * Restarts the progress timer and updates Now Playing information.
     */
    func resume() {
        audioPlayer?.play()
        playerState = .playing
        startTimer()
        updateNowPlayingInfo()
    }
    
    /**
     * Stops playback completely.
     *
     * Clears the current track, resets playback position, and clears Now Playing info.
     */
    func stop() {
        // Stop timer first to prevent any callbacks
        stopTimer()

        // Stop and clean up audio player
        audioPlayer?.stop()
        audioPlayer = nil

        // Reset state
        playerState = .stopped
        currentTime = 0

        // Clear Now Playing info
        clearNowPlayingInfo()
    }
    
    /**
     * Seeks to a specific time position in the current track.
     * 
     * - Parameter time: The target time position in seconds
     */
    func seek(to time: TimeInterval) {
        audioPlayer?.currentTime = time
        currentTime = time
        updateNowPlayingInfo()
    }
    
    /**
     * Sets the audio volume.
     * 
     * - Parameter newVolume: The new volume level (0.0 to 1.0)
     */
    func setVolume(_ newVolume: Float) {
        volume = newVolume
        audioPlayer?.volume = newVolume
    }

    // MARK: - Playback Mode Control
    
    /**
     * Toggles shuffle mode between off and tracks.
     * 
     * When enabling shuffle, generates new shuffled indices.
     * When disabling, clears shuffled indices.
     */
    func toggleShuffle() {
        shuffleMode = shuffleMode == .off ? .tracks : .off
        if shuffleMode == .tracks {
            generateShuffledIndices()
        } else {
            shuffledIndices.removeAll()
            currentShuffleIndex = 0
        }
    }

    /**
     * Cycles through repeat modes: off → playlist → track → off.
     */
    func toggleRepeat() {
        repeatMode = repeatMode.next
    }

    // MARK: - Private Helper Methods

    /**
     * Generates shuffled indices for the current playlist.
     *
     * Creates a randomized array of track indices and updates the current
     * shuffle index to match the currently playing track.
     */
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

    // MARK: - Track Navigation

    /**
     * Advances to the next track in the playlist.
     *
     * Behavior depends on current playback modes:
     * - Repeat track: Replays the current track
     * - Shuffle mode: Plays next track in shuffled order
     * - Normal mode: Plays next track in playlist order
     * - Repeat playlist: Wraps to beginning when reaching end
     */
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

    /**
     * Goes back to the previous track in the playlist.
     *
     * Behavior depends on current playback modes:
     * - Repeat track: Replays the current track
     * - Shuffle mode: Plays previous track in shuffled order
     * - Normal mode: Plays previous track in playlist order
     * - Repeat playlist: Wraps to end when reaching beginning
     */
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

    // MARK: - Timer Management

    /**
     * Starts the playback progress timer.
     *
     * The timer frequency is dynamically adjusted based on track duration:
     * - Shorter tracks get more frequent updates for smoother progress
     * - Longer tracks get less frequent updates to save CPU
     * - Minimum 100 updates per track, maximum every 0.1 seconds
     */
    private func startTimer() {
        // Always stop existing timer first to prevent multiple timers
        stopTimer()

        // Calculate optimal update interval based on track duration
        let trackDuration = currentTrack?.duration ?? 180 // Default to 3 minutes if unknown
        let targetUpdatesPerTrack = 100.0 // Aim for 100 updates across the entire track
        let calculatedInterval = trackDuration / targetUpdatesPerTrack

        // Clamp between 0.1 and 1.0 seconds for reasonable performance
        let updateInterval = max(0.1, min(1.0, calculatedInterval))

        timer = Timer.scheduledTimer(withTimeInterval: updateInterval, repeats: true) { [weak self] _ in
            guard let self = self else { return }

            if let player = self.audioPlayer {
                self.currentTime = player.currentTime

                // Update Now Playing info every second (regardless of timer frequency)
                let timeSinceLastUpdate = self.currentTime - self.lastNowPlayingUpdate
                if timeSinceLastUpdate >= 1.0 {
                    self.updateNowPlayingInfo()
                    self.lastNowPlayingUpdate = self.currentTime
                }

                // Check if track finished
                if !player.isPlaying && self.playerState == .playing {
                    self.nextTrack()
                }
            }
        }
    }

    /**
     * Stops and invalidates the playback progress timer.
     */
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    // MARK: - Media Remote Control Integration

    /**
     * Sets up integration with macOS media remote controls.
     *
     * This method configures the MPRemoteCommandCenter to handle:
     * - Play/pause commands
     * - Next/previous track commands
     * - Playback position changes
     *
     * These commands can be triggered from:
     * - Touch Bar media controls
     * - Bluetooth headphones/speakers
     * - Control Center
     * - Lock screen controls
     */
    private func setupRemoteCommandCenter() {
        let commandCenter = MPRemoteCommandCenter.shared()

        // Play command
        commandCenter.playCommand.addTarget { [weak self] _ in
            self?.resume()
            return .success
        }

        // Pause command
        commandCenter.pauseCommand.addTarget { [weak self] _ in
            self?.pause()
            return .success
        }

        // Toggle play/pause command
        commandCenter.togglePlayPauseCommand.addTarget { [weak self] _ in
            guard let self = self else { return .commandFailed }
            switch self.playerState {
            case .playing:
                self.pause()
            case .paused:
                self.resume()
            case .stopped:
                if let selectedPlaylist = self.currentPlaylist {
                    self.playFirstTrack(in: selectedPlaylist)
                }
            }
            return .success
        }

        // Next track command
        commandCenter.nextTrackCommand.addTarget { [weak self] _ in
            self?.nextTrack()
            return .success
        }

        // Previous track command
        commandCenter.previousTrackCommand.addTarget { [weak self] _ in
            self?.previousTrack()
            return .success
        }

        // Change playback position command
        commandCenter.changePlaybackPositionCommand.addTarget { [weak self] event in
            guard let self = self,
                  let positionEvent = event as? MPChangePlaybackPositionCommandEvent else {
                return .commandFailed
            }
            self.seek(to: positionEvent.positionTime)
            return .success
        }
    }

    // MARK: - Now Playing Information

    /**
     * Updates the system's Now Playing information.
     *
     * This method populates the Now Playing info center with current track
     * metadata, including title, artist, album, duration, artwork, and
     * playback position. This information appears in:
     * - Control Center
     * - Lock screen
     * - Bluetooth device displays
     * - Touch Bar
     */
    private func updateNowPlayingInfo() {
        var nowPlayingInfo = [String: Any]()

        if let track = currentTrack {
            nowPlayingInfo[MPMediaItemPropertyTitle] = track.title
            nowPlayingInfo[MPMediaItemPropertyArtist] = track.artist ?? ""
            nowPlayingInfo[MPMediaItemPropertyAlbumTitle] = track.album ?? ""
            nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = track.duration
            nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = currentTime
            nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = playerState == .playing ? 1.0 : 0.0

            // Add artwork if available
            if let artwork = track.artwork {
                let mpArtwork = MPMediaItemArtwork(boundsSize: artwork.size) { _ in
                    return artwork
                }
                nowPlayingInfo[MPMediaItemPropertyArtwork] = mpArtwork
            }
        }

        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }

    /**
     * Clears the system's Now Playing information.
     *
     * This method should be called when playback stops or the app
     * is no longer the active audio source.
     */
    private func clearNowPlayingInfo() {
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
    }

    // MARK: - App Lifecycle Management

    /**
     * Sets up observers for app termination and state changes.
     *
     * This method ensures proper cleanup of Now Playing information
     * when the app terminates or becomes inactive.
     */
    private func setupAppTerminationHandling() {
        // Listen for app termination notifications
        NotificationCenter.default.addObserver(
            forName: NSApplication.willTerminateNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.clearNowPlayingInfo()
        }

        // Also listen for when the app becomes inactive (like when switching apps)
        NotificationCenter.default.addObserver(
            forName: NSApplication.didResignActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            // Only clear if we're actually stopped
            if self?.playerState == .stopped {
                self?.clearNowPlayingInfo()
            }
        }
    }

    /**
     * Cleanup method called when the music player is deallocated.
     *
     * Ensures proper cleanup of Now Playing information, timers, audio player, and notification observers.
     */
    deinit {
        // Stop timer and audio player
        stopTimer()
        audioPlayer?.stop()
        audioPlayer = nil

        // Clear Now Playing info and remove observers
        clearNowPlayingInfo()
        NotificationCenter.default.removeObserver(self)
    }
}
