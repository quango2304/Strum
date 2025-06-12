//
//  Models.swift
//  Strum
//
//  Created by leongo on 13/6/25.
//

import Foundation
import AVFoundation

// MARK: - Track Model
struct Track: Identifiable, Codable, Hashable {
    let id = UUID()
    let url: URL
    let title: String
    let artist: String?
    let album: String?
    let duration: TimeInterval
    let trackNumber: Int?
    
    init(url: URL) {
        self.url = url

        // Extract metadata from the audio file
        let asset = AVURLAsset(url: url)

        // Get title (fallback to filename)
        self.title = url.deletingPathExtension().lastPathComponent

        // For now, set basic values - we can enhance metadata extraction later
        self.artist = nil
        self.album = nil
        self.trackNumber = nil

        // Get duration
        let duration = asset.duration
        self.duration = duration.seconds.isFinite ? duration.seconds : 0
    }
}

// MARK: - Playlist Model
class Playlist: ObservableObject, Identifiable, Codable {
    let id = UUID()
    @Published var name: String
    @Published var tracks: [Track]
    let createdAt: Date
    
    init(name: String, tracks: [Track] = []) {
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
}

// MARK: - Player State
enum PlayerState {
    case stopped
    case playing
    case paused
}

// MARK: - Music Player Manager
class MusicPlayerManager: ObservableObject {
    @Published var currentTrack: Track?
    @Published var currentPlaylist: Playlist?
    @Published var playerState: PlayerState = .stopped
    @Published var currentTime: TimeInterval = 0
    @Published var volume: Float = 0.5
    
    private var audioPlayer: AVAudioPlayer?
    private var timer: Timer?
    
    init() {
        // No audio session setup needed on macOS
    }
    
    func play(track: Track, in playlist: Playlist) {
        currentTrack = track
        currentPlaylist = playlist
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: track.url)
            audioPlayer?.volume = volume
            audioPlayer?.play()
            playerState = .playing
            startTimer()
        } catch {
            print("Failed to play track: \(error)")
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
    
    func nextTrack() {
        guard let playlist = currentPlaylist,
              let currentTrack = currentTrack,
              let currentIndex = playlist.tracks.firstIndex(of: currentTrack),
              currentIndex < playlist.tracks.count - 1 else { return }
        
        let nextTrack = playlist.tracks[currentIndex + 1]
        play(track: nextTrack, in: playlist)
    }
    
    func previousTrack() {
        guard let playlist = currentPlaylist,
              let currentTrack = currentTrack,
              let currentIndex = playlist.tracks.firstIndex(of: currentTrack),
              currentIndex > 0 else { return }
        
        let previousTrack = playlist.tracks[currentIndex - 1]
        play(track: previousTrack, in: playlist)
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
