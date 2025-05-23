//
//  EditTaskView.swift
//  Brain Dump
//
//  Created by AI Assistant on 5/23/25.
//

import SwiftUI
import SwiftData

struct EditTaskView: View {
    @Environment(\.dismiss) private var dismiss
    let task: IvyLeeTask
    @State private var taskDescription: String
    
    init(task: IvyLeeTask) {
        self.task = task
        self._taskDescription = State(initialValue: task.taskDescription)
    }
    
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
            .navigationTitle("Edit Task")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(BrainDumpTheme.textColor.opacity(0.7))
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        // Save task changes here
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
    let sampleTask = IvyLeeTask(
        description: "Sample task",
        priority: 1,
        reasoning: "Sample reasoning"
    )
    
    EditTaskView(task: sampleTask)
} 