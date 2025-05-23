//
//  TaskBrainDumpView.swift
//  Brain Dump
//
//  Created by AI Assistant on 5/23/25.
//

import SwiftUI
import SwiftData

struct TaskBrainDumpView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var dailyEntryViewModel: DailyEntryViewModel
    @State private var taskViewModel = IvyLeeTaskViewModel()
    @State private var showingSomedayMaybe = false
    @State private var showingAddTask = false
    @State private var newTaskDescription = ""
    @State private var draggedTask: IvyLeeTask?
    
    init() {
        // We'll initialize the dailyEntryViewModel in onAppear when we have access to modelContext
        self._dailyEntryViewModel = State(wrappedValue: DailyEntryViewModel(modelContext: nil))
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: BrainDumpTheme.largePadding) {
                // Header
                headerSection
                
                // Current Task Focus
                if let currentTask = taskViewModel.currentTask {
                    currentTaskSection(currentTask)
                }
                
                // Task Queue
                taskQueueSection
                
                // Quick Add Task
                quickAddTaskSection
                
                // Someday/Maybe Preview
                somedayMaybeSection
            }
            .padding(BrainDumpTheme.standardPadding)
        }
        .background(BrainDumpTheme.backgroundColor)
        .sheet(isPresented: $showingSomedayMaybe) {
            SomedayMaybeView()
        }
        .sheet(isPresented: $showingAddTask) {
            AddTaskView()
        }
        .onAppear {
            // Initialize view models
            if dailyEntryViewModel.modelContext == nil {
                dailyEntryViewModel.setModelContext(modelContext)
            }
            taskViewModel.setModelContext(modelContext)
            taskViewModel.setDailyEntryViewModel(dailyEntryViewModel)
            loadData()
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: BrainDumpTheme.smallPadding) {
            HStack {
                Image(systemName: "brain.head.profile")
                    .font(.largeTitle)
                    .foregroundColor(BrainDumpTheme.accentColor)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Ivy Lee Method")
                        .font(BrainDumpTheme.titleFont)
                        .foregroundColor(BrainDumpTheme.textColor)
                    
                    Text("Focus on what matters most")
                        .font(BrainDumpTheme.bodyFont)
                        .foregroundColor(BrainDumpTheme.textColor.opacity(0.7))
                }
                
                Spacer()
                
                // Task Count Badge
                VStack {
                    Text("\(taskViewModel.activeTasks.count)")
                        .font(BrainDumpTheme.headlineFont)
                        .foregroundColor(BrainDumpTheme.actionColor)
                        .fontWeight(.bold)
                    
                    Text("/ 6")
                        .font(BrainDumpTheme.captionFont)
                        .foregroundColor(BrainDumpTheme.textColor.opacity(0.6))
                }
                .padding(.horizontal, BrainDumpTheme.smallPadding)
                .padding(.vertical, BrainDumpTheme.tinyPadding)
                .background(
                    RoundedRectangle(cornerRadius: BrainDumpTheme.smallCornerRadius)
                        .stroke(BrainDumpTheme.actionColor.opacity(0.3), lineWidth: 1)
                )
            }
            
            // Ivy Lee Philosophy
            VStack(spacing: BrainDumpTheme.smallPadding) {
                Text("\"At the end of each day, write down six important things you need to accomplish tomorrow.\"")
                    .font(BrainDumpTheme.bodyFont)
                    .italic()
                    .foregroundColor(BrainDumpTheme.textColor.opacity(0.8))
                    .multilineTextAlignment(.center)
                
                Text("— Ivy Lee's $25,000 advice")
                    .font(BrainDumpTheme.captionFont)
                    .foregroundColor(BrainDumpTheme.textColor.opacity(0.6))
            }
            .padding(BrainDumpTheme.standardPadding)
            .background(
                RoundedRectangle(cornerRadius: BrainDumpTheme.cornerRadius)
                    .fill(BrainDumpTheme.accentColor.opacity(0.1))
            )
        }
    }
    
    // MARK: - Current Task Section
    private func currentTaskSection(_ task: IvyLeeTask) -> some View {
        VStack(spacing: BrainDumpTheme.standardPadding) {
            sectionHeader(title: "Current Focus", icon: "target")
            
            VStack(spacing: BrainDumpTheme.standardPadding) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("TASK")
                                .font(BrainDumpTheme.smallFont)
                                .foregroundColor(BrainDumpTheme.actionColor)
                                .fontWeight(.bold)
                            
                            Text("#\(task.priority)")
                                .font(BrainDumpTheme.smallFont)
                                .foregroundColor(BrainDumpTheme.actionColor)
                                .fontWeight(.bold)
                        }
                        
                        Text(task.taskDescription)
                            .font(BrainDumpTheme.headlineFont)
                            .foregroundColor(BrainDumpTheme.textColor)
                            .multilineTextAlignment(.leading)
                    }
                    
                    Spacer()
                    
                    VStack {
                        Text(task.priorityEmoji)
                            .font(.title)
                        
                        Text(task.formattedEstimatedDuration)
                            .font(BrainDumpTheme.captionFont)
                            .foregroundColor(BrainDumpTheme.textColor.opacity(0.7))
                    }
                }
                
                // Action Buttons
                HStack(spacing: BrainDumpTheme.standardPadding) {
                    Button(action: { taskViewModel.startFocusTimer(for: task) }) {
                        HStack {
                            Image(systemName: "play.circle.fill")
                            Text("Focus")
                        }
                        .font(BrainDumpTheme.bodyFont)
                        .foregroundColor(.white)
                        .padding(.horizontal, BrainDumpTheme.standardPadding)
                        .padding(.vertical, BrainDumpTheme.smallPadding)
                        .background(BrainDumpTheme.actionColor)
                        .cornerRadius(BrainDumpTheme.cornerRadius)
                    }
                    
                    Button(action: { taskViewModel.completeTask(task) }) {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Complete")
                        }
                        .font(BrainDumpTheme.bodyFont)
                        .foregroundColor(.white)
                        .padding(.horizontal, BrainDumpTheme.standardPadding)
                        .padding(.vertical, BrainDumpTheme.smallPadding)
                        .background(BrainDumpTheme.sageColor)
                        .cornerRadius(BrainDumpTheme.cornerRadius)
                    }
                    
                    Button(action: { taskViewModel.moveTaskToSomeday(task) }) {
                        HStack {
                            Image(systemName: "arrow.right.circle")
                            Text("Later")
                        }
                        .font(BrainDumpTheme.bodyFont)
                        .foregroundColor(BrainDumpTheme.textColor.opacity(0.7))
                        .padding(.horizontal, BrainDumpTheme.standardPadding)
                        .padding(.vertical, BrainDumpTheme.smallPadding)
                        .background(BrainDumpTheme.surfaceColor)
                        .cornerRadius(BrainDumpTheme.cornerRadius)
                    }
                }
            }
            .padding(BrainDumpTheme.standardPadding)
            .background(
                RoundedRectangle(cornerRadius: BrainDumpTheme.cornerRadius)
                    .fill(BrainDumpTheme.surfaceColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: BrainDumpTheme.cornerRadius)
                            .stroke(BrainDumpTheme.actionColor.opacity(0.3), lineWidth: 2)
                    )
            )
        }
    }
    
    // MARK: - Task Queue Section
    private var taskQueueSection: some View {
        VStack(spacing: BrainDumpTheme.standardPadding) {
            HStack {
                sectionHeader(title: "Today's Queue", icon: "list.number")
                
                Spacer()
                
                if taskViewModel.activeTasks.count < 6 {
                    Button(action: { showingAddTask = true }) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(BrainDumpTheme.actionColor)
                            .font(.title3)
                    }
                }
            }
            
            if taskViewModel.activeTasks.isEmpty {
                // Empty State
                VStack(spacing: BrainDumpTheme.smallPadding) {
                    Image(systemName: "tray")
                        .font(.title)
                        .foregroundColor(BrainDumpTheme.textColor.opacity(0.6))
                    
                    Text("No tasks planned")
                        .font(BrainDumpTheme.headlineFont)
                        .foregroundColor(BrainDumpTheme.textColor)
                    
                    Text("Head to Evening planning to set up tomorrow's priorities")
                        .font(BrainDumpTheme.bodyFont)
                        .foregroundColor(BrainDumpTheme.textColor.opacity(0.7))
                        .multilineTextAlignment(.center)
                    
                    Button(action: { showingAddTask = true }) {
                        Text("Add First Task")
                            .font(BrainDumpTheme.bodyFont)
                            .foregroundColor(.white)
                            .padding(.horizontal, BrainDumpTheme.standardPadding)
                            .padding(.vertical, BrainDumpTheme.smallPadding)
                            .background(BrainDumpTheme.actionColor)
                            .cornerRadius(BrainDumpTheme.cornerRadius)
                    }
                }
                .padding(BrainDumpTheme.largePadding)
                .background(BrainDumpTheme.surfaceColor)
                .cornerRadius(BrainDumpTheme.cornerRadius)
            } else {
                // Task List with Drag & Drop
                LazyVStack(spacing: BrainDumpTheme.smallPadding) {
                    ForEach(taskViewModel.activeTasks.sorted(by: { $0.priority < $1.priority }), id: \.id) { task in
                        TaskRowView(
                            task: task,
                            isCurrent: task.priority == 1,
                            onComplete: { taskViewModel.completeTask(task) },
                            onMoveToSomeday: { taskViewModel.moveTaskToSomeday(task) },
                            onStartFocus: { taskViewModel.startFocusTimer(for: task) }
                        )
                        .draggable(task) {
                            TaskRowView(
                                task: task,
                                isCurrent: false,
                                onComplete: { },
                                onMoveToSomeday: { },
                                onStartFocus: { }
                            )
                            .opacity(0.8)
                            .scaleEffect(0.95)
                        }
                        .dropDestination(for: IvyLeeTask.self) { droppedTasks, location in
                            handleTaskDrop(droppedTasks: droppedTasks, targetTask: task)
                            return true
                        }
                    }
                }
            }
            
            // Queue Status
            if !taskViewModel.activeTasks.isEmpty {
                HStack {
                    Text("Capacity: \(taskViewModel.activeTasks.count)/6")
                        .font(BrainDumpTheme.captionFont)
                        .foregroundColor(BrainDumpTheme.textColor.opacity(0.6))
                    
                    Spacer()
                    
                    if taskViewModel.activeTasks.count == 6 {
                        Text("Queue Full")
                            .font(BrainDumpTheme.captionFont)
                            .foregroundColor(BrainDumpTheme.actionColor)
                    }
                }
                .padding(.horizontal, BrainDumpTheme.smallPadding)
            }
        }
    }
    
    // MARK: - Quick Add Task Section
    private var quickAddTaskSection: some View {
        VStack(spacing: BrainDumpTheme.standardPadding) {
            HStack {
                TextField("Add a quick task...", text: $newTaskDescription)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .onSubmit {
                        if !newTaskDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            taskViewModel.addQuickTask(description: newTaskDescription)
                            newTaskDescription = ""
                        }
                    }
                
                Button(action: {
                    if !newTaskDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        taskViewModel.addQuickTask(description: newTaskDescription)
                        newTaskDescription = ""
                    }
                }) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(BrainDumpTheme.actionColor)
                        .font(.title2)
                }
                .disabled(newTaskDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
    }
    
    // MARK: - Someday/Maybe Section
    private var somedayMaybeSection: some View {
        VStack(spacing: BrainDumpTheme.standardPadding) {
            HStack {
                sectionHeader(title: "Someday/Maybe", icon: "archivebox")
                
                Spacer()
                
                Button("View All") {
                    showingSomedayMaybe = true
                }
                .font(BrainDumpTheme.captionFont)
                .foregroundColor(BrainDumpTheme.actionColor)
            }
            
            if taskViewModel.somedayTasks.isEmpty {
                Text("Tasks beyond your daily capacity will appear here")
                    .font(BrainDumpTheme.bodyFont)
                    .foregroundColor(BrainDumpTheme.textColor.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .padding(BrainDumpTheme.standardPadding)
                    .background(BrainDumpTheme.surfaceColor)
                    .cornerRadius(BrainDumpTheme.cornerRadius)
            } else {
                VStack(spacing: BrainDumpTheme.smallPadding) {
                    ForEach(Array(taskViewModel.somedayTasks.prefix(3)), id: \.id) { task in
                        HStack {
                            Text(task.taskDescription)
                                .font(BrainDumpTheme.bodyFont)
                                .foregroundColor(BrainDumpTheme.textColor)
                            
                            Spacer()
                            
                            Button(action: { taskViewModel.promoteTaskFromSomeday(task) }) {
                                Image(systemName: "arrow.up.circle")
                                    .foregroundColor(BrainDumpTheme.sageColor)
                            }
                            .disabled(taskViewModel.activeTasks.count >= 6)
                        }
                        .padding(BrainDumpTheme.smallPadding)
                        .background(BrainDumpTheme.cardBackgroundColor)
                        .cornerRadius(BrainDumpTheme.smallCornerRadius)
                    }
                    
                    if taskViewModel.somedayTasks.count > 3 {
                        Text("+ \(taskViewModel.somedayTasks.count - 3) more in Someday/Maybe")
                            .font(BrainDumpTheme.captionFont)
                            .foregroundColor(BrainDumpTheme.textColor.opacity(0.6))
                    }
                }
                .padding(BrainDumpTheme.standardPadding)
                .background(BrainDumpTheme.surfaceColor)
                .cornerRadius(BrainDumpTheme.cornerRadius)
            }
        }
    }
    
    // MARK: - Helper Views
    private func sectionHeader(title: String, icon: String) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(BrainDumpTheme.actionColor)
            Text(title)
                .font(BrainDumpTheme.subheadingFont)
                .foregroundColor(BrainDumpTheme.textColor)
        }
    }
    
    // MARK: - Methods
    private func loadData() {
        // Load current data and refresh the view models
        if let entry = dailyEntryViewModel.currentEntry {
            taskViewModel.loadSmartFeatures()
        }
    }
    
    private func handleTaskDrop(droppedTasks: [IvyLeeTask], targetTask: IvyLeeTask) {
        guard let droppedTask = droppedTasks.first else { return }
        
        // Reorder tasks based on drop position
        taskViewModel.reorderTask(droppedTask, toPosition: targetTask.priority)
    }
}

// MARK: - Task Row View
struct TaskRowView: View {
    let task: IvyLeeTask
    let isCurrent: Bool
    let onComplete: () -> Void
    let onMoveToSomeday: () -> Void
    let onStartFocus: () -> Void
    
    var body: some View {
        HStack(spacing: BrainDumpTheme.standardPadding) {
            // Priority Number
            ZStack {
                Circle()
                    .fill(isCurrent ? BrainDumpTheme.actionColor : BrainDumpTheme.textColor.opacity(0.2))
                    .frame(width: 32, height: 32)
                
                Text("\(task.priority)")
                    .font(BrainDumpTheme.headlineFont)
                    .foregroundColor(isCurrent ? .white : BrainDumpTheme.textColor)
                    .fontWeight(.bold)
            }
            
            // Task Content
            VStack(alignment: .leading, spacing: 4) {
                Text(task.taskDescription)
                    .font(BrainDumpTheme.bodyFont)
                    .foregroundColor(BrainDumpTheme.textColor)
                    .lineLimit(2)
                
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
            
            // Actions
            HStack(spacing: BrainDumpTheme.smallPadding) {
                if isCurrent {
                    Button(action: onStartFocus) {
                        Image(systemName: "play.circle")
                            .foregroundColor(BrainDumpTheme.actionColor)
                    }
                }
                
                Button(action: onComplete) {
                    Image(systemName: "checkmark.circle")
                        .foregroundColor(BrainDumpTheme.sageColor)
                }
                
                Button(action: onMoveToSomeday) {
                    Image(systemName: "arrow.right.circle")
                        .foregroundColor(BrainDumpTheme.textColor.opacity(0.6))
                }
            }
        }
        .padding(BrainDumpTheme.standardPadding)
        .background(
            RoundedRectangle(cornerRadius: BrainDumpTheme.cornerRadius)
                .fill(isCurrent ? BrainDumpTheme.actionColor.opacity(0.1) : BrainDumpTheme.surfaceColor)
                .overlay(
                    RoundedRectangle(cornerRadius: BrainDumpTheme.cornerRadius)
                        .stroke(isCurrent ? BrainDumpTheme.actionColor.opacity(0.3) : Color.clear, lineWidth: 1)
                )
        )
    }
}

#Preview {
    TaskBrainDumpView()
        .modelContainer(for: [DailyEntry.self, IvyLeeTask.self, SomedayMaybeTask.self, SmartFeatures.self, UserInsight.self], inMemory: true)
} 