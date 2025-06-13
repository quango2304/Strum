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
    @Environment(\.colorTheme) private var colorTheme

    var body: some View {
        VStack(spacing: 0) {
            Divider()

            Group {
                if isCompact {
                    // Compact Layout: Vertical stack for smaller screens
                    VStack(spacing: 12) {
                    // Top row: Track info and themed volume control
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

                        // Themed Volume Control (compact - top right)
                        ThemedVolumeControl(
                            volume: Binding(
                                get: { musicPlayer.volume },
                                set: { musicPlayer.setVolume($0) }
                            ),
                            theme: colorTheme
                        )
                        .frame(width: 160)
                    }

                    // Bottom row: Playback controls and progress
                    VStack(spacing: 12) {
                        // All playback controls in one centered row
                        HStack(spacing: 16) {
                            // Shuffle button (left)
                            Button(action: {
                                musicPlayer.toggleShuffle()
                            }) {
                                Image(systemName: "shuffle")
                                    .foregroundColor(musicPlayer.shuffleMode == .tracks ? .white : .secondary)
                            }
                            .buttonStyle(ThemedIconButtonStyle(size: 28, isActive: musicPlayer.shuffleMode == .tracks, theme: colorTheme))

                            // Main playback controls (center)
                            HStack(spacing: 16) {
                                Button(action: {
                                    musicPlayer.previousTrack()
                                }) {
                                    Image(systemName: "backward.fill")
                                        .foregroundColor(.primary)
                                }
                                .buttonStyle(ThemedIconButtonStyle(size: 32, theme: colorTheme))
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
                                .buttonStyle(ThemedIconButtonStyle(size: 44, isActive: true, theme: colorTheme))
                                .disabled(musicPlayer.currentTrack == nil)

                                Button(action: {
                                    musicPlayer.nextTrack()
                                }) {
                                    Image(systemName: "forward.fill")
                                        .foregroundColor(.primary)
                                }
                                .buttonStyle(ThemedIconButtonStyle(size: 32, theme: colorTheme))
                                .disabled(musicPlayer.currentTrack == nil)
                            }

                            // Repeat button (right)
                            Button(action: {
                                musicPlayer.toggleRepeat()
                            }) {
                                Image(systemName: repeatIcon(for: musicPlayer.repeatMode))
                                    .foregroundColor(musicPlayer.repeatMode != .off ? .white : .secondary)
                            }
                            .buttonStyle(ThemedIconButtonStyle(size: 28, isActive: musicPlayer.repeatMode != .off, theme: colorTheme))
                        }

                        // Progress Bar (full width in compact mode)
                        ThemedProgressControl(
                            currentTime: Binding(
                                get: { musicPlayer.currentTime },
                                set: { musicPlayer.seek(to: $0) }
                            ),
                            duration: musicPlayer.currentTrack?.duration ?? 0,
                            onSeek: { musicPlayer.seek(to: $0) },
                            theme: colorTheme
                        )
                    }
                }
                } else {
                    // Desktop Layout: Single row with track info, controls, and volume
                    VStack(spacing: 12) {
                        // Main row: Track info + Controls + Volume
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

                            // Centered Controls: Shuffle + Primary Controls + Repeat
                            HStack(spacing: 20) {
                                // Shuffle button (left)
                                Button(action: {
                                    musicPlayer.toggleShuffle()
                                }) {
                                    Image(systemName: "shuffle")
                                        .foregroundColor(musicPlayer.shuffleMode == .tracks ? .white : .secondary)
                                }
                                .buttonStyle(ThemedIconButtonStyle(size: 32, isActive: musicPlayer.shuffleMode == .tracks, theme: colorTheme))

                                // Main playback controls (center)
                                HStack(spacing: 20) {
                                    Button(action: {
                                        musicPlayer.previousTrack()
                                    }) {
                                        Image(systemName: "backward.fill")
                                            .foregroundColor(.primary)
                                    }
                                    .buttonStyle(ThemedIconButtonStyle(size: 36, theme: colorTheme))
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
                                    .buttonStyle(ThemedIconButtonStyle(size: 52, isActive: true, theme: colorTheme))
                                    .disabled(musicPlayer.currentTrack == nil)

                                    Button(action: {
                                        musicPlayer.nextTrack()
                                    }) {
                                        Image(systemName: "forward.fill")
                                            .foregroundColor(.primary)
                                    }
                                    .buttonStyle(ThemedIconButtonStyle(size: 36, theme: colorTheme))
                                    .disabled(musicPlayer.currentTrack == nil)
                                }

                                // Repeat button (right)
                                Button(action: {
                                    musicPlayer.toggleRepeat()
                                }) {
                                    Image(systemName: repeatIcon(for: musicPlayer.repeatMode))
                                        .foregroundColor(musicPlayer.repeatMode != .off ? .white : .secondary)
                                }
                                .buttonStyle(ThemedIconButtonStyle(size: 32, isActive: musicPlayer.repeatMode != .off, theme: colorTheme))
                            }

                            Spacer()

                            // Volume Control
                            ThemedVolumeControl(
                                volume: Binding(
                                    get: { musicPlayer.volume },
                                    set: { musicPlayer.setVolume($0) }
                                ),
                                theme: colorTheme
                            )
                            .frame(width: 200, alignment: .trailing)
                        }

                        // Progress Bar (full width below everything)
                        ThemedProgressControl(
                            currentTime: Binding(
                                get: { musicPlayer.currentTime },
                                set: { musicPlayer.seek(to: $0) }
                            ),
                            duration: musicPlayer.currentTrack?.duration ?? 0,
                            onSeek: { musicPlayer.seek(to: $0) },
                            theme: colorTheme
                        )
                    }
                }
            }
            .padding(.horizontal, DesignSystem.Spacing.xl)
            .padding(.vertical, isCompact ? DesignSystem.Spacing.md : DesignSystem.Spacing.xl)
            .background(
                ZStack {
                    // Subtle transparent background that works with global blur
                    Rectangle()
                        .fill(.thinMaterial)
                        .opacity(0.5)

                    // Very subtle themed overlay
                    Rectangle()
                        .fill(colorTheme.surfaceTint)
                        .opacity(0.1)

                    // Subtle shadow for depth
                    Rectangle()
                        .fill(Color.clear)
                        .shadow(color: DesignSystem.Shadow.light, radius: 4, x: 0, y: -1)
                }
            )
        }
        .frame(height: isCompact ? 160 : 120) // Standard height for single row layout
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

// MARK: - Themed Volume Control
struct ThemedVolumeControl: View {
    @Binding var volume: Float
    let theme: ColorTheme

    var body: some View {
        HStack(spacing: 12) {
            // Speaker icon
            Button(action: {
                volume = volume > 0 ? 0 : 0.7
            }) {
                Image(systemName: volumeIcon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.secondary)
                    .frame(width: 20, height: 20)
            }
            .buttonStyle(PlainButtonStyle())
            .help(volume > 0 ? "Mute" : "Unmute")

            // Custom themed slider
            ThemedSlider(
                value: Binding(
                    get: { Double(volume) },
                    set: { volume = Float($0) }
                ),
                range: 0...1,
                theme: theme,
                trackHeight: 20, // Same height as thumb
                thumbSize: 20
            )
            .frame(width: 120)
        }
    }

    private var volumeIcon: String {
        if volume == 0 {
            return "speaker.slash.fill"
        } else if volume < 0.33 {
            return "speaker.wave.1.fill"
        } else if volume < 0.66 {
            return "speaker.wave.2.fill"
        } else {
            return "speaker.wave.3.fill"
        }
    }
}

// MARK: - Themed Progress Control
struct ThemedProgressControl: View {
    @Binding var currentTime: TimeInterval
    let duration: TimeInterval
    let onSeek: (TimeInterval) -> Void
    let theme: ColorTheme

    var body: some View {
        VStack(spacing: 6) {
            // Custom themed slider
            ThemedSlider(
                value: Binding(
                    get: { currentTime },
                    set: { onSeek($0) }
                ),
                range: 0...max(duration, 1),
                theme: theme,
                trackHeight: 20, // Same height as thumb
                thumbSize: 20
            )

            // Time labels
            HStack {
                Text(formatTime(currentTime))
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
                    .monospacedDigit()

                Spacer()

                Text(formatTime(duration))
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
                    .monospacedDigit()
            }
        }
    }

    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Custom Themed Slider
struct ThemedSlider: View {
    @Binding var value: Double
    let range: ClosedRange<Double>
    let theme: ColorTheme
    let trackHeight: CGFloat
    let thumbSize: CGFloat

    @State private var isDragging = false
    @State private var dragOffset: CGFloat = 0

    var body: some View {
        GeometryReader { geometry in
            let trackWidth = geometry.size.width
            let progress = (value - range.lowerBound) / (range.upperBound - range.lowerBound)
            let thumbPosition = (trackWidth - thumbSize) * progress

            ZStack(alignment: .leading) {
                // Background track (full height, rounded like a pill)
                RoundedRectangle(cornerRadius: trackHeight / 2)
                    .fill(Color.primary.opacity(0.15))
                    .frame(height: trackHeight)

                // Progress track (full height, rounded like a pill)
                RoundedRectangle(cornerRadius: trackHeight / 2)
                    .fill(
                        LinearGradient(
                            colors: theme.gradientColors,
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: max(thumbPosition + thumbSize, trackHeight), height: trackHeight)

                // Thumb (white circle, same size as track height)
                Circle()
                    .fill(Color.white)
                    .frame(width: thumbSize, height: thumbSize)
                    .shadow(color: Color.black.opacity(0.25), radius: 3, x: 0, y: 1)
                    .scaleEffect(isDragging ? 1.1 : 1.0)
                    .offset(x: thumbPosition)
                    .gesture(
                        DragGesture()
                            .onChanged { gesture in
                                if !isDragging {
                                    isDragging = true
                                }

                                let newPosition = max(0, min(trackWidth - thumbSize, gesture.location.x))
                                let newProgress = newPosition / (trackWidth - thumbSize)
                                let newValue = range.lowerBound + (range.upperBound - range.lowerBound) * newProgress
                                value = newValue
                            }
                            .onEnded { _ in
                                isDragging = false
                            }
                    )
                    .onTapGesture { }
            }
            .contentShape(Rectangle())
            .onTapGesture { location in
                let newPosition = max(0, min(trackWidth - thumbSize, location.x))
                let newProgress = newPosition / (trackWidth - thumbSize)
                let newValue = range.lowerBound + (range.upperBound - range.lowerBound) * newProgress
                value = newValue
            }
        }
        .frame(height: max(trackHeight, thumbSize))
        .animation(.easeInOut(duration: 0.15), value: isDragging)
    }
}

#Preview {
    PlayerControlsView(musicPlayer: MusicPlayerManager(), isCompact: false)
        .frame(width: 800)
}
