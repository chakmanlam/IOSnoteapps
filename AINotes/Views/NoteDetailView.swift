//
//  NoteDetailView.swift
//  AINotes
//
//  Created by Chak Man Lam on 5/22/25.
//

import SwiftUI
import SwiftData

struct NoteDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isTextFieldFocused: Bool
    
    var note: Note
    private var isNewNote: Bool
    
    init(note: Note? = nil) {
        if let note = note {
            self.note = note
            self.isNewNote = false
        } else {
            self.note = Note()
            self.isNewNote = true
        }
    }
    
    var body: some View {
        VStack {
            TextEditor(text: $note.content)
                .focused($isTextFieldFocused)
                .padding()
                .onChange(of: note.content) { _, _ in
                    note.updateTitle()
                    note.modifiedAt = Date()
                }
            
            HStack {
                Spacer()
                Text("\(note.content.count) characters")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.trailing)
            }
        }
        .navigationTitle(note.title.isEmpty ? "New Note" : note.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") {
                    if isNewNote && !note.content.isEmpty {
                        modelContext.insert(note)
                    }
                    dismiss()
                }
            }
        }
        .onAppear {
            if isNewNote {
                isTextFieldFocused = true
            }
        }
    }
}

#Preview {
    NavigationView {
        NoteDetailView(note: Note(content: "Sample note content for preview"))
    }
    .modelContainer(for: Note.self, inMemory: true)
} 