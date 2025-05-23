//
//  AddTaskView.swift
//  Brain Dump
//
//  Created by AI Assistant on 5/23/25.
//

import SwiftUI
import SwiftData

struct AddTaskView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var taskDescription = ""
    
    var body: some View {
        NavigationStack {
            VStack(spacing: BrainDumpTheme.standardPadding) {
                TextField("Task description...", text: $taskDescription, axis: .vertical)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .lineLimit(3...6)
                
                Spacer()
            }
            .padding(BrainDumpTheme.standardPadding)
            .background(BrainDumpTheme.backgroundColor)
            .navigationTitle("Add Task")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(BrainDumpTheme.textColor.opacity(0.7))
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        // Add task logic here
                        dismiss()
                    }
                    .foregroundColor(BrainDumpTheme.actionColor)
                    .disabled(taskDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}

#Preview {
    AddTaskView()
} 