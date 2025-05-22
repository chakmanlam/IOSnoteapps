//
//  AINotesApp.swift
//  AINotes
//
//  Created by Chak Man Lam on 5/22/25.
//

import SwiftUI
import SwiftData

@main
struct AINotesApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [Note.self])
    }
}
