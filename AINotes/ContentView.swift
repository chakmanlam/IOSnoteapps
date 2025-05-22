//
//  ContentView.swift
//  AINotes
//
//  Created by Chak Man Lam on 5/22/25.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        // This will be our NoteListView once it's implemented
        // For now, creating a placeholder to keep the app compiling
        NavigationView {
            VStack {
                Text("Welcome to AINotes!")
                    .font(.title)
                Text("We'll implement the NoteListView here soon")
                    .foregroundColor(.secondary)
            }
            .navigationTitle("AINotes")
        }
    }
}

#Preview {
    ContentView()
}
