//
//  PlayerControlsView.swift
//  Strum
//
//  Created by leongo on 13/6/25.
//

import SwiftUI
import AppKit

struct PlayerControlsView: View {
    @ObservedObject var musicPlayer: MusicPlayerManager
    @ObservedObject var playlistManager: PlaylistManager
    @FocusState.Binding var isSearchFieldFocused: Bool
    let isCompact: Bool
    @Environment(\.colorTheme) private var colorTheme

    var body: some View {
        VStack(spacing: 0) {
            Group {
                if isCompact {
                    // Compact Layout: Vertical stack for smaller screens
                    VStack(spacing: 12) {
                    // Top row: Track info and themed volume control
                    HStack(spacing: 12) {
                        // Track Info (compact)
                        HStack(spacing: 8) {
                            // Rotating CD Album Art (bigger, only for current track)
                            if musicPlayer.currentTrack != nil {
                                RotatingCDArt(
                                    artwork: musicPlayer.currentTrack?.artwork,
                                    isPlaying: musicPlayer.playerState == .playing,
                                    size: 60
                                )
                            } else {
                                // Placeholder when no track
                                Circle()
                                    .fill(Color.secondary.opacity(0.15))
                                    .frame(width: 60, height: 60)
                                    .overlay(
                                        Image(systemName: "music.note")
                                            .font(.system(size: 20, weight: .medium))
                                            .foregroundColor(.secondary)
                                            .opacity(0.6)
                                    )
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
                                isSearchFieldFocused = false
                                musicPlayer.toggleShuffle()
                            }) {
                                Image(systemName: "shuffle")
                                    .foregroundColor(musicPlayer.shuffleMode == .tracks ? .white : .secondary)
                            }
                            .buttonStyle(ThemedIconButtonStyle(size: 28, isActive: musicPlayer.shuffleMode == .tracks, theme: colorTheme))
                            .keyboardShortcut("s", modifiers: .command)

                            // Main playback controls (center)
                            HStack(spacing: 16) {
                                Button(action: {
                                    isSearchFieldFocused = false
                                    musicPlayer.previousTrack()
                                }) {
                                    Image(systemName: "backward.fill")
                                        .foregroundColor(.primary)
                                }
                                .buttonStyle(ThemedIconButtonStyle(size: 32, theme: colorTheme))
                                .disabled(musicPlayer.currentTrack == nil)
                                .keyboardShortcut(.leftArrow, modifiers: .command)

                                Button(action: {
                                    isSearchFieldFocused = false
                                    switch musicPlayer.playerState {
                                    case .playing:
                                        musicPlayer.pause()
                                    case .paused:
                                        musicPlayer.resume()
                                    case .stopped:
                                        // If no current track, play first track from selected playlist
                                        if let selectedPlaylist = playlistManager.selectedPlaylist {
                                            musicPlayer.playFirstTrack(in: selectedPlaylist)
                                        }
                                    }
                                }) {
                                    AnimatedPlayPauseIcon(
                                        isPlaying: musicPlayer.playerState == .playing,
                                        size: 22
                                    )
                                    .foregroundColor(.white)
                                }
                                .buttonStyle(ThemedIconButtonStyle(size: 44, isActive: true, theme: colorTheme, useGradient: true))
                                .disabled(musicPlayer.currentTrack == nil && playlistManager.selectedPlaylist?.tracks.isEmpty != false)
                                .keyboardShortcut(.space, modifiers: [])

                                Button(action: {
                                    isSearchFieldFocused = false
                                    musicPlayer.nextTrack()
                                }) {
                                    Image(systemName: "forward.fill")
                                        .foregroundColor(.primary)
                                }
                                .buttonStyle(ThemedIconButtonStyle(size: 32, theme: colorTheme))
                                .disabled(musicPlayer.currentTrack == nil)
                                .keyboardShortcut(.rightArrow, modifiers: .command)
                            }

                            // Repeat button (right)
                            Button(action: {
                                isSearchFieldFocused = false
                                musicPlayer.toggleRepeat()
                            }) {
                                Image(systemName: repeatIcon(for: musicPlayer.repeatMode))
                                    .foregroundColor(musicPlayer.repeatMode != .off ? .white : .secondary)
                            }
                            .buttonStyle(ThemedIconButtonStyle(size: 28, isActive: musicPlayer.repeatMode != .off, theme: colorTheme))
                            .keyboardShortcut("r", modifiers: .command)
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
                            // Rotating CD Album Art (bigger, only for current track)
                            if musicPlayer.currentTrack != nil {
                                RotatingCDArt(
                                    artwork: musicPlayer.currentTrack?.artwork,
                                    isPlaying: musicPlayer.playerState == .playing,
                                    size: 70
                                )
                            } else {
                                // Placeholder when no track
                                Circle()
                                    .fill(Color.secondary.opacity(0.15))
                                    .frame(width: 70, height: 70)
                                    .overlay(
                                        Image(systemName: "music.note")
                                            .font(.system(size: 24, weight: .medium))
                                            .foregroundColor(.secondary)
                                            .opacity(0.6)
                                    )
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
                                    isSearchFieldFocused = false
                                    musicPlayer.toggleShuffle()
                                }) {
                                    Image(systemName: "shuffle")
                                        .foregroundColor(musicPlayer.shuffleMode == .tracks ? .white : .secondary)
                                }
                                .buttonStyle(ThemedIconButtonStyle(size: 32, isActive: musicPlayer.shuffleMode == .tracks, theme: colorTheme))
                                .keyboardShortcut("s", modifiers: .command)

                                // Main playback controls (center)
                                HStack(spacing: 20) {
                                    Button(action: {
                                        isSearchFieldFocused = false
                                        musicPlayer.previousTrack()
                                    }) {
                                        Image(systemName: "backward.fill")
                                            .foregroundColor(.primary)
                                    }
                                    .buttonStyle(ThemedIconButtonStyle(size: 36, theme: colorTheme))
                                    .disabled(musicPlayer.currentTrack == nil)
                                    .keyboardShortcut(.leftArrow, modifiers: .command)

                                    Button(action: {
                                        isSearchFieldFocused = false
                                        switch musicPlayer.playerState {
                                        case .playing:
                                            musicPlayer.pause()
                                        case .paused:
                                            musicPlayer.resume()
                                        case .stopped:
                                            // If no current track, play first track from selected playlist
                                            if let selectedPlaylist = playlistManager.selectedPlaylist {
                                                musicPlayer.playFirstTrack(in: selectedPlaylist)
                                            }
                                        }
                                    }) {
                                        AnimatedPlayPauseIcon(
                                            isPlaying: musicPlayer.playerState == .playing,
                                            size: 26
                                        )
                                        .foregroundColor(.white)
                                    }
                                    .buttonStyle(ThemedIconButtonStyle(size: 52, isActive: true, theme: colorTheme, useGradient: true))
                                    .disabled(musicPlayer.currentTrack == nil && playlistManager.selectedPlaylist?.tracks.isEmpty != false)
                                    .keyboardShortcut(.space, modifiers: [])

                                    Button(action: {
                                        isSearchFieldFocused = false
                                        musicPlayer.nextTrack()
                                    }) {
                                        Image(systemName: "forward.fill")
                                            .foregroundColor(.primary)
                                    }
                                    .buttonStyle(ThemedIconButtonStyle(size: 36, theme: colorTheme))
                                    .disabled(musicPlayer.currentTrack == nil)
                                    .keyboardShortcut(.rightArrow, modifiers: .command)
                                }

                                // Repeat button (right)
                                Button(action: {
                                    isSearchFieldFocused = false
                                    musicPlayer.toggleRepeat()
                                }) {
                                    Image(systemName: repeatIcon(for: musicPlayer.repeatMode))
                                        .foregroundColor(musicPlayer.repeatMode != .off ? .white : .secondary)
                                }
                                .buttonStyle(ThemedIconButtonStyle(size: 32, isActive: musicPlayer.repeatMode != .off, theme: colorTheme))
                                .keyboardShortcut("r", modifiers: .command)
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
            .padding(.vertical, isCompact ? DesignSystem.Spacing.lg : DesignSystem.Spacing.xl)
            .background(
                ZStack {
                    // Base background
                    Color(NSColor.controlBackgroundColor)

                    // Consistent themed gradient overlay
                    DesignSystem.colors(for: colorTheme).sectionBackground
                }
                .shadow(color: DesignSystem.Shadow.light, radius: 4, x: 0, y: -1)
            )
        }
        .frame(height: isCompact ? 180 : 140) // Increased height to accommodate larger rotating CD
    }

    // MARK: - Helper Views

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
        VStack(spacing: 8) {
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

// MARK: - Rotating CD Art Component
struct RotatingCDArt: View {
    let artwork: NSImage?
    let isPlaying: Bool
    let size: CGFloat

    @State private var isRotating: Bool = false

    // Create a unique identifier for the artwork to prevent animation between different images
    private var artworkID: String {
        if let artwork = artwork {
            return "\(artwork.hash)"
        } else {
            return "no-artwork"
        }
    }

    var body: some View {
        ZStack {
            // CD Base (dark circle with hole in center)
            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [
                            Color.black.opacity(0.8),
                            Color.black.opacity(0.6),
                            Color.black.opacity(0.9)
                        ]),
                        center: .center,
                        startRadius: size * 0.1,
                        endRadius: size * 0.5
                    )
                )
                .frame(width: size, height: size)

            // Album artwork (if available) - with unique ID to prevent cross-fade animation
            if let artwork = artwork {
                Image(nsImage: artwork)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: size * 0.85, height: size * 0.85)
                    .clipShape(Circle())
                    .id(artworkID) // Unique ID prevents animation between different artworks
            } else {
                // Default music note for no artwork
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: size * 0.85, height: size * 0.85)
                    .overlay(
                        Image(systemName: "music.note")
                            .font(.system(size: size * 0.3, weight: .medium))
                            .foregroundColor(.secondary)
                    )
                    .id("no-artwork") // Consistent ID for no artwork state
            }

            // Center hole (small dark circle)
            Circle()
                .fill(Color.black.opacity(0.9))
                .frame(width: size * 0.15, height: size * 0.15)

            // Subtle highlight lines for CD effect
            Circle()
                .stroke(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.white.opacity(0.3),
                            Color.clear,
                            Color.white.opacity(0.1)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
                .frame(width: size * 0.9, height: size * 0.9)
        }
        .rotationEffect(.degrees(isRotating ? 360 : 0))
        .animation(
            isRotating ?
            .linear(duration: 8.0).repeatForever(autoreverses: false) :
            .linear(duration: 0.5),
            value: isRotating
        )
        .shadow(color: Color.black.opacity(0.3), radius: 4, x: 0, y: 2)
        .onAppear {
            isRotating = isPlaying
        }
        .onChange(of: isPlaying) { _, newValue in
            isRotating = newValue
        }
        .onChange(of: artworkID) { _, _ in
            // Reset rotation when artwork changes to prevent animation between different images
            let wasRotating = isRotating
            isRotating = false
            // Small delay to ensure the animation stops before restarting
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isRotating = wasRotating && isPlaying
            }
        }
    }


}

// MARK: - Animated Play/Pause Icon Component
struct AnimatedPlayPauseIcon: View {
    let isPlaying: Bool
    let size: CGFloat

    var body: some View {
        ZStack {
            // Play icon
            Image(systemName: "play.fill")
                .font(.system(size: size, weight: .medium))
                .opacity(isPlaying ? 0 : 1)
                .scaleEffect(isPlaying ? 0.7 : 1.0)
                .rotationEffect(.degrees(isPlaying ? 90 : 0))

            // Pause icon
            Image(systemName: "pause.fill")
                .font(.system(size: size, weight: .medium))
                .opacity(isPlaying ? 1 : 0)
                .scaleEffect(isPlaying ? 1.0 : 0.7)
                .rotationEffect(.degrees(isPlaying ? 0 : -90))
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8, blendDuration: 0), value: isPlaying)
    }
}

#Preview {
    struct PreviewWrapper: View {
        @FocusState private var isSearchFieldFocused: Bool

        var body: some View {
            PlayerControlsView(musicPlayer: MusicPlayerManager(), playlistManager: PlaylistManager(), isSearchFieldFocused: $isSearchFieldFocused, isCompact: false)
                .frame(width: 800)
        }
    }

    return PreviewWrapper()
}
