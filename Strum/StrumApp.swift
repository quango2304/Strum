//
//  StrumApp.swift
//  Strum
//
//  Created by leongo on 12/6/25.
//

import SwiftUI

@main
struct StrumApp: App {
    @StateObject private var preferencesManager = PreferencesManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(preferencesManager)
                .environment(\.colorTheme, preferencesManager.colorTheme)
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified)
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

        // Preferences Window
        WindowGroup("Preferences", id: "preferences") {
            PreferencesView(preferencesManager: preferencesManager)
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .defaultPosition(.center)
    }
}
