//
//  StrumApp.swift
//  Strum
//
//  Created by leongo on 12/6/25.
//

import SwiftUI
import AppKit

// MARK: - App Delegate
class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
}

@main
struct StrumApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var preferencesManager = PreferencesManager()
    @StateObject private var playlistManager = PlaylistManager()

    init() {
        // Setup memory pressure monitoring for artwork cache
        Track.setupMemoryPressureMonitoring()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(preferencesManager)
                .environmentObject(playlistManager)
                .environment(\.colorTheme, preferencesManager.colorTheme)
                .onReceive(NotificationCenter.default.publisher(for: NSApplication.willTerminateNotification)) { _ in
                    // Save playlists immediately when app is about to terminate
                    playlistManager.savePlaylistsImmediately()
                    // Clear artwork cache on termination
                    Track.clearArtworkCache()
                }
                .onReceive(NotificationCenter.default.publisher(for: NSApplication.didResignActiveNotification)) { _ in
                    // Clear artwork cache when app becomes inactive to free memory
                    Track.clearArtworkCache()
                }
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified)
        .defaultSize(width: 1200, height: 800)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("Import Files...") {
                    // This will be handled by the ContentView
                }
                .keyboardShortcut("o", modifiers: .command)

                Button("Import Folder...") {
                    // This will be handled by the ContentView
                }
                .keyboardShortcut("o", modifiers: [.command, .shift])
            }

            CommandGroup(replacing: .appInfo) {
                Button("About Strum") {
                    preferencesManager.showAbout = true
                }
            }

            CommandGroup(after: .appInfo) {
                Button("Preferences...") {
                    preferencesManager.showPreferences = true
                }
                .keyboardShortcut(",", modifiers: .command)
            }

            // Music Player Controls Menu
            CommandMenu("Playback") {
                Button("Play/Pause") {
                    // This will be handled by the PlayerControlsView
                }
                .keyboardShortcut(.space, modifiers: [])

                Button("Previous Track") {
                    // This will be handled by the PlayerControlsView
                }
                .keyboardShortcut(.leftArrow, modifiers: .command)

                Button("Next Track") {
                    // This will be handled by the PlayerControlsView
                }
                .keyboardShortcut(.rightArrow, modifiers: .command)
            }
        }
    }
}
