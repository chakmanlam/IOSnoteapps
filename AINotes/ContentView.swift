//
//  ContentView.swift
//  AINotes
//
//  Created by Chak Man Lam on 5/22/25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
        NoteListView()
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Note.self, inMemory: true)
}
