//
//  TaskQueueManagementView.swift
//  Brain Dump
//
//  Created by AI Assistant on 5/23/25.
//

import SwiftUI
import SwiftData

struct TaskQueueManagementView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var dailyEntryViewModel: DailyEntryViewModel
    @StateObject private var taskViewModel = IvyLeeTaskViewModel()
    @State private var showingAddTask = false
    @State private var showSmartInsights = false
    
    init() {
        // Initialize dailyEntryViewModel - will be set properly in onAppear
        self._dailyEntryViewModel = State(wrappedValue: DailyEntryViewModel(modelContext: nil))
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Task Queue Management
                ScrollView {
                    VStack(spacing: BrainDumpTheme.largePadding) {
                        // Active Queue
                        activeQueueSection
                        
                        // Someday/Maybe
                        somedayMaybeSection
                    }
                    .padding(BrainDumpTheme.standardPadding)
                }
            }
            .background(BrainDumpTheme.backgroundColor)
            .navigationTitle("Task Queue")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(BrainDumpTheme.actionColor)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddTask = true }) {
                        Image(systemName: "plus")
                    }
                    .foregroundColor(BrainDumpTheme.actionColor)
                    .disabled(taskViewModel.activeTasks.count >= 6)
                }
            }
            .sheet(isPresented: $showingAddTask) {
                AddTaskView()
            }
            .onAppear {
                taskViewModel.setModelContext(modelContext)
                dailyEntryViewModel.setModelContext(modelContext)
                taskViewModel.setDailyEntryViewModel(dailyEntryViewModel)
            }
        }
    }
    
    // MARK: - Active Queue Section
    private var activeQueueSection: some View {
        VStack(spacing: BrainDumpTheme.standardPadding) {
            HStack {
                Text("Active Queue")
                    .font(BrainDumpTheme.subheadingFont)
                    .foregroundColor(BrainDumpTheme.textColor)
                
                Spacer()
                
                Text("\(taskViewModel.activeTasks.count)/6")
                    .font(BrainDumpTheme.bodyFont)
                    .foregroundColor(BrainDumpTheme.actionColor)
                    .fontWeight(.semibold)
            }
            
            if taskViewModel.activeTasks.isEmpty {
                VStack(spacing: BrainDumpTheme.smallPadding) {
                    Image(systemName: "tray")
                        .font(.title)
                        .foregroundColor(BrainDumpTheme.textColor.opacity(0.6))
                    
                    Text("No active tasks")
                        .font(BrainDumpTheme.headlineFont)
                        .foregroundColor(BrainDumpTheme.textColor)
                    
                    Text("Add tasks to get started with the Ivy Lee Method")
                        .font(BrainDumpTheme.bodyFont)
                        .foregroundColor(BrainDumpTheme.textColor.opacity(0.7))
                        .multilineTextAlignment(.center)
                }
                .padding(BrainDumpTheme.largePadding)
                .background(BrainDumpTheme.surfaceColor)
                .cornerRadius(BrainDumpTheme.cornerRadius)
            } else {
                LazyVStack(spacing: BrainDumpTheme.smallPadding) {
                    ForEach(taskViewModel.activeTasks.sorted(by: { $0.priority < $1.priority }), id: \.id) { task in
                        DetailedTaskRowView(
                            task: task,
                            onComplete: { taskViewModel.completeTask(task) },
                            onMoveToSomeday: { taskViewModel.moveTaskToSomeday(task) },
                            onUpdatePriority: { newPriority in
                                taskViewModel.updateTaskPriority(task, to: newPriority)
                            }
                        )
                    }
                }
            }
        }
    }
    
    // MARK: - Someday/Maybe Section
    private var somedayMaybeSection: some View {
        VStack(spacing: BrainDumpTheme.standardPadding) {
            HStack {
                Text("Someday/Maybe")
                    .font(BrainDumpTheme.subheadingFont)
                    .foregroundColor(BrainDumpTheme.textColor)
                
                Spacer()
                
                Text("\(taskViewModel.somedayTasks.count)")
                    .font(BrainDumpTheme.bodyFont)
                    .foregroundColor(BrainDumpTheme.textColor.opacity(0.6))
                    .fontWeight(.semibold)
            }
            
            if taskViewModel.somedayTasks.isEmpty {
                Text("Tasks that exceed your daily capacity will appear here")
                    .font(BrainDumpTheme.bodyFont)
                    .foregroundColor(BrainDumpTheme.textColor.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .padding(BrainDumpTheme.standardPadding)
                    .background(BrainDumpTheme.surfaceColor)
                    .cornerRadius(BrainDumpTheme.cornerRadius)
            } else {
                LazyVStack(spacing: BrainDumpTheme.smallPadding) {
                    ForEach(taskViewModel.somedayTasks, id: \.id) { task in
                        SomedayTaskRowView(
                            task: task,
                            onPromote: { taskViewModel.promoteTaskFromSomeday(task) },
                            onDelete: { taskViewModel.deleteSomedayTask(task) },
                            canPromote: taskViewModel.activeTasks.count < 6
                        )
                    }
                }
            }
        }
    }
}

// MARK: - Detailed Task Row View
struct DetailedTaskRowView: View {
    let task: IvyLeeTask
    let onComplete: () -> Void
    let onMoveToSomeday: () -> Void
    let onUpdatePriority: (Int) -> Void
    
    @State private var showingEditSheet = false
    
    var body: some View {
        VStack(spacing: BrainDumpTheme.standardPadding) {
            HStack {
                // Priority Selector
                Picker("Priority", selection: Binding(
                    get: { task.priority },
                    set: { onUpdatePriority($0) }
                )) {
                    ForEach(1...6, id: \.self) { priority in
                        Text("#\(priority)")
                            .tag(priority)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .frame(width: 60)
                
                // Task Content
                VStack(alignment: .leading, spacing: 4) {
                    Text(task.taskDescription)
                        .font(BrainDumpTheme.bodyFont)
                        .foregroundColor(BrainDumpTheme.textColor)
                    
                    HStack {
                        Text(task.formattedEstimatedDuration)
                            .font(BrainDumpTheme.captionFont)
                            .foregroundColor(BrainDumpTheme.textColor.opacity(0.6))
                        
                        if !task.whyImportantReasoning.isEmpty {
                            Text("• \(task.whyImportantReasoning)")
                                .font(BrainDumpTheme.captionFont)
                                .foregroundColor(BrainDumpTheme.textColor.opacity(0.6))
                                .lineLimit(1)
                        }
                    }
                }
                
                Spacer()
                
                // Priority Emoji
                Text(task.priorityEmoji)
                    .font(.title3)
                
                // Actions Menu
                Menu {
                    Button("Complete", action: onComplete)
                    Button("Move to Someday", action: onMoveToSomeday)
                    Button("Edit", action: { showingEditSheet = true })
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundColor(BrainDumpTheme.textColor.opacity(0.6))
                }
            }
        }
        .padding(BrainDumpTheme.standardPadding)
        .background(
            RoundedRectangle(cornerRadius: BrainDumpTheme.cornerRadius)
                .fill(task.priority == 1 ? BrainDumpTheme.actionColor.opacity(0.1) : BrainDumpTheme.surfaceColor)
                .overlay(
                    RoundedRectangle(cornerRadius: BrainDumpTheme.cornerRadius)
                        .stroke(task.priority == 1 ? BrainDumpTheme.actionColor.opacity(0.3) : Color.clear, lineWidth: 1)
                )
        )
        .sheet(isPresented: $showingEditSheet) {
            EditTaskView(task: task)
        }
    }
}

// MARK: - Someday Task Row View
struct SomedayTaskRowView: View {
    let task: SomedayMaybeTask
    let onPromote: () -> Void
    let onDelete: () -> Void
    let canPromote: Bool
    
    var body: some View {
        HStack(spacing: BrainDumpTheme.standardPadding) {
            VStack(alignment: .leading, spacing: 4) {
                Text(task.taskDescription)
                    .font(BrainDumpTheme.bodyFont)
                    .foregroundColor(BrainDumpTheme.textColor)
                
                HStack {
                    Text("Added \(task.dateAdded.formatted(.dateTime.month().day()))")
                        .font(BrainDumpTheme.captionFont)
                        .foregroundColor(BrainDumpTheme.textColor.opacity(0.6))
                    
                    if task.priority != .low {
                        Text("• \(task.priority.displayName)")
                            .font(BrainDumpTheme.captionFont)
                            .foregroundColor(BrainDumpTheme.textColor.opacity(0.6))
                    }
                }
            }
            
            Spacer()
            
            HStack(spacing: BrainDumpTheme.smallPadding) {
                Button(action: onPromote) {
                    Image(systemName: "arrow.up.circle.fill")
                        .foregroundColor(canPromote ? BrainDumpTheme.sageColor : BrainDumpTheme.textColor.opacity(0.3))
                }
                .disabled(!canPromote)
                
                Button(action: onDelete) {
                    Image(systemName: "trash.circle")
                        .foregroundColor(BrainDumpTheme.actionColor.opacity(0.6))
                }
            }
        }
        .padding(BrainDumpTheme.standardPadding)
        .background(BrainDumpTheme.surfaceColor)
        .cornerRadius(BrainDumpTheme.cornerRadius)
    }
}

#Preview {
    TaskQueueManagementView()
        .modelContainer(for: [DailyEntry.self, IvyLeeTask.self, SomedayMaybeTask.self, SmartFeatures.self, UserInsight.self], inMemory: true)
} 