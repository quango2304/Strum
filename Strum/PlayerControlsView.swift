//
//  PlayerControlsView.swift
//  Strum
//
//  Created by leongo on 13/6/25.
//

import SwiftUI

struct PlayerControlsView: View {
    @ObservedObject var musicPlayer: MusicPlayerManager
    let isCompact: Bool

    var body: some View {
        VStack(spacing: 0) {
            Divider()

            Group {
                if isCompact {
                    // Compact Layout: Vertical stack for smaller screens
                    VStack(spacing: 12) {
                    // Top row: Track info and volume
                    HStack(spacing: 12) {
                        // Track Info (compact)
                        HStack(spacing: 8) {
                            // Album Art (smaller)
                            Group {
                                if let artwork = musicPlayer.currentTrack?.artwork {
                                    Image(nsImage: artwork)
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 40, height: 40)
                                        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.sm))
                                        .shadow(color: DesignSystem.Shadow.light, radius: 2, x: 0, y: 1)
                                } else {
                                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.sm)
                                        .fill(DesignSystem.Colors.surfaceSecondary)
                                        .frame(width: 40, height: 40)
                                        .overlay(
                                            Image(systemName: "music.note")
                                                .foregroundColor(.secondary)
                                                .font(.system(size: 12))
                                        )
                                        .shadow(color: DesignSystem.Shadow.light, radius: 1, x: 0, y: 1)
                                }
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                Text(musicPlayer.currentTrack?.title ?? "No track selected")
                                    .font(DesignSystem.Typography.playerTitle)
                                    .lineLimit(1)
                                    .foregroundColor(.primary)

                                Text(musicPlayer.currentTrack?.artist ?? "")
                                    .font(DesignSystem.Typography.playerSubtitle)
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        Spacer()

                        // Volume Control (compact)
                        HStack(spacing: 6) {
                            Image(systemName: musicPlayer.volume == 0 ? "speaker.slash.fill" : "speaker.wave.2.fill")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)

                            Slider(
                                value: Binding(
                                    get: { musicPlayer.volume },
                                    set: { musicPlayer.setVolume($0) }
                                ),
                                in: 0...1
                            )
                            .frame(width: 80)
                        }
                    }

                    // Bottom row: Playback controls and progress
                    VStack(spacing: 12) {
                        // Playback Controls
                        VStack(spacing: 8) {
                            // Main playback controls
                            HStack(spacing: 16) {
                                Button(action: {
                                    musicPlayer.previousTrack()
                                }) {
                                    Image(systemName: "backward.fill")
                                        .foregroundColor(.primary)
                                }
                                .buttonStyle(IconButtonStyle(size: 32))
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
                                    Image(systemName: musicPlayer.playerState == .playing ? "pause.fill" : "play.fill")
                                        .foregroundColor(.white)
                                }
                                .buttonStyle(IconButtonStyle(size: 44, isActive: true))
                                .disabled(musicPlayer.currentTrack == nil)

                                Button(action: {
                                    musicPlayer.nextTrack()
                                }) {
                                    Image(systemName: "forward.fill")
                                        .foregroundColor(.primary)
                                }
                                .buttonStyle(IconButtonStyle(size: 32))
                                .disabled(musicPlayer.currentTrack == nil)
                            }

                            // Shuffle and Repeat controls
                            HStack(spacing: 20) {
                                Button(action: {
                                    musicPlayer.toggleShuffle()
                                }) {
                                    Image(systemName: "shuffle")
                                        .foregroundColor(musicPlayer.shuffleMode == .tracks ? .white : .secondary)
                                }
                                .buttonStyle(IconButtonStyle(size: 28, isActive: musicPlayer.shuffleMode == .tracks))

                                Button(action: {
                                    musicPlayer.toggleRepeat()
                                }) {
                                    Image(systemName: repeatIcon(for: musicPlayer.repeatMode))
                                        .foregroundColor(musicPlayer.repeatMode != .off ? .white : .secondary)
                                }
                                .buttonStyle(IconButtonStyle(size: 28, isActive: musicPlayer.repeatMode != .off))
                            }
                        }

                        // Progress Bar (full width in compact mode)
                        VStack(spacing: 6) {
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

                            HStack {
                                Text(formatTime(musicPlayer.currentTime))
                                    .font(.system(size: 10))
                                    .foregroundColor(.secondary)

                                Spacer()

                                Text(formatTime(musicPlayer.currentTrack?.duration ?? 0))
                                    .font(.system(size: 10))
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                } else {
                    // Desktop Layout: Horizontal layout for larger screens
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
                                    .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md))
                                    .shadow(color: DesignSystem.Shadow.medium, radius: 4, x: 0, y: 2)
                            } else {
                                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.md)
                                    .fill(DesignSystem.Colors.surfaceSecondary)
                                    .frame(width: 50, height: 50)
                                    .overlay(
                                        Image(systemName: "music.note")
                                            .foregroundColor(.secondary)
                                            .font(.system(size: 16))
                                    )
                                    .shadow(color: DesignSystem.Shadow.light, radius: 2, x: 0, y: 1)
                            }
                        }

                        VStack(alignment: .leading, spacing: 3) {
                            Text(musicPlayer.currentTrack?.title ?? "No track selected")
                                .font(DesignSystem.Typography.playerTitle)
                                .lineLimit(1)
                                .foregroundColor(.primary)

                            Text(musicPlayer.currentTrack?.artist ?? "")
                                .font(DesignSystem.Typography.playerSubtitle)
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
                                        .foregroundColor(.primary)
                                }
                                .buttonStyle(IconButtonStyle(size: 36))
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
                                    Image(systemName: musicPlayer.playerState == .playing ? "pause.fill" : "play.fill")
                                        .foregroundColor(.white)
                                }
                                .buttonStyle(IconButtonStyle(size: 52, isActive: true))
                                .disabled(musicPlayer.currentTrack == nil)

                                Button(action: {
                                    musicPlayer.nextTrack()
                                }) {
                                    Image(systemName: "forward.fill")
                                        .foregroundColor(.primary)
                                }
                                .buttonStyle(IconButtonStyle(size: 36))
                                .disabled(musicPlayer.currentTrack == nil)
                            }

                            // Shuffle and Repeat controls
                            HStack(spacing: 24) {
                                Button(action: {
                                    musicPlayer.toggleShuffle()
                                }) {
                                    Image(systemName: "shuffle")
                                        .foregroundColor(musicPlayer.shuffleMode == .tracks ? .white : .secondary)
                                }
                                .buttonStyle(IconButtonStyle(size: 32, isActive: musicPlayer.shuffleMode == .tracks))

                                Button(action: {
                                    musicPlayer.toggleRepeat()
                                }) {
                                    Image(systemName: repeatIcon(for: musicPlayer.repeatMode))
                                        .foregroundColor(musicPlayer.repeatMode != .off ? .white : .secondary)
                                }
                                .buttonStyle(IconButtonStyle(size: 32, isActive: musicPlayer.repeatMode != .off))
                            }
                        }

                        Spacer()

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
                }
            }
            .padding(.horizontal, DesignSystem.Spacing.xl)
            .padding(.vertical, isCompact ? DesignSystem.Spacing.md : DesignSystem.Spacing.xl)
            .background(
                Rectangle()
                    .fill(DesignSystem.Colors.surface)
                    .shadow(color: DesignSystem.Shadow.light, radius: 1, x: 0, y: -1)
            )
        }
        .frame(height: isCompact ? 160 : 120) // Increased height for shuffle/repeat controls
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    private func repeatIcon(for mode: RepeatMode) -> String {
        switch mode {
        case .off:
            return "repeat"
        case .playlist:
            return "repeat"
        case .track:
            return "repeat.1"
        }
    }
}

#Preview {
    PlayerControlsView(musicPlayer: MusicPlayerManager(), isCompact: false)
        .frame(width: 800)
}
