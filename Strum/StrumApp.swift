//
//  StrumApp.swift
//  Strum
//
//  Created by leongo on 12/6/25.
//

import SwiftUI

@main
struct StrumApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
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
        }
    }
}
