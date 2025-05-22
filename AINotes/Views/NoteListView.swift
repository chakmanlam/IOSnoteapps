//
//  NoteListView.swift
//  AINotes
//
//  Created by Chak Man Lam on 5/22/25.
//

import SwiftUI
import SwiftData

struct NoteListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Note.modifiedAt, order: .reverse) private var notes: [Note]
    @State private var isShowingNewNote = false
    @State private var newNote: Note?
    
    var body: some View {
        NavigationView {
            List {
                if notes.isEmpty {
                    Text("No notes yet. Tap + to create one.")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(notes) { note in
                        NavigationLink(destination: NoteDetailView(note: note)) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(note.title.isEmpty ? "Untitled" : note.title)
                                    .font(.headline)
                                Text(note.content.prefix(50))
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .lineLimit(2)
                                Text(note.modifiedAt, style: .date)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .onDelete(perform: deleteNotes)
                }
            }
            .navigationTitle("AINotes")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: createNewNote) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $isShowingNewNote) {
                if let newNote = newNote {
                    NavigationView {
                        NoteDetailView(note: newNote)
                    }
                }
            }
        }
    }
    
    private func createNewNote() {
        let note = Note()
        modelContext.insert(note)
        newNote = note
        isShowingNewNote = true
    }
    
    private func deleteNotes(at offsets: IndexSet) {
        // Will be implemented in Task 6
    }
}

#Preview {
    NoteListView()
        .modelContainer(for: Note.self, inMemory: true)
}
