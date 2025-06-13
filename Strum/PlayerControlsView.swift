//
//  PlayerControlsView.swift
//  Strum
//
//  Created by leongo on 13/6/25.
//

import SwiftUI

struct PlayerControlsView: View {
    @ObservedObject var musicPlayer: MusicPlayerManager
    
    var body: some View {
        VStack(spacing: 0) {
            Divider()
            
            HStack(spacing: 16) {
                // Track Info
                HStack(spacing: 12) {
                    // Album Art
                    Group {
                        if let artwork = musicPlayer.currentTrack?.artwork {
                            Image(nsImage: artwork)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 50, height: 50)
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                        } else {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.secondary.opacity(0.3))
                                .frame(width: 50, height: 50)
                                .overlay(
                                    Image(systemName: "music.note")
                                        .foregroundColor(.secondary)
                                )
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(musicPlayer.currentTrack?.title ?? "No track selected")
                            .font(.system(size: 14, weight: .medium))
                            .lineLimit(1)
                        
                        Text(musicPlayer.currentTrack?.artist ?? "")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                    .frame(width: 200, alignment: .leading)
                }
                
                Spacer()
                
                // Playback Controls
                VStack(spacing: 8) {
                    HStack(spacing: 20) {
                        Button(action: {
                            musicPlayer.previousTrack()
                        }) {
                            Image(systemName: "backward.fill")
                                .font(.system(size: 16))
                        }
                        .buttonStyle(PlainButtonStyle())
                        .disabled(musicPlayer.currentTrack == nil)
                        
                        Button(action: {
                            switch musicPlayer.playerState {
                            case .playing:
                                musicPlayer.pause()
                            case .paused:
                                musicPlayer.resume()
                            case .stopped:
                                break
                            }
                        }) {
                            Image(systemName: musicPlayer.playerState == .playing ? "pause.circle.fill" : "play.circle.fill")
                                .font(.system(size: 32))
                        }
                        .buttonStyle(PlainButtonStyle())
                        .disabled(musicPlayer.currentTrack == nil)
                        
                        Button(action: {
                            musicPlayer.nextTrack()
                        }) {
                            Image(systemName: "forward.fill")
                                .font(.system(size: 16))
                        }
                        .buttonStyle(PlainButtonStyle())
                        .disabled(musicPlayer.currentTrack == nil)
                    }
                    
                    // Progress Bar
                    VStack(spacing: 4) {
                        HStack {
                            Slider(
                                value: Binding(
                                    get: { musicPlayer.currentTime },
                                    set: { musicPlayer.seek(to: $0) }
                                ),
                                in: 0...(musicPlayer.currentTrack?.duration ?? 1)
                            )
                            .disabled(musicPlayer.currentTrack == nil)
                        }
                        .frame(width: 400)
                        
                        HStack {
                            Text(formatTime(musicPlayer.currentTime))
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            Text(formatTime(musicPlayer.currentTrack?.duration ?? 0))
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        }
                        .frame(width: 400)
                    }
                }
                
                Spacer()
                
                // Volume Control
                HStack(spacing: 8) {
                    Image(systemName: musicPlayer.volume == 0 ? "speaker.slash.fill" : "speaker.wave.2.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                    
                    Slider(
                        value: Binding(
                            get: { musicPlayer.volume },
                            set: { musicPlayer.setVolume($0) }
                        ),
                        in: 0...1
                    )
                    .frame(width: 100)
                }
                .frame(width: 200, alignment: .trailing)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 20)
            .background(Color(NSColor.controlBackgroundColor))
        }
        .frame(height: 96)
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

#Preview {
    PlayerControlsView(musicPlayer: MusicPlayerManager())
        .frame(width: 800)
}
