//
//  DailyEntryViewModel.swift
//  Brain Dump
//
//  Created by Chak Man Lam on 5/22/25.
//

import Foundation
import SwiftData
import SwiftUI

@Observable
class DailyEntryViewModel {
    var modelContext: ModelContext?
    var currentEntry: DailyEntry?
    
    // Form state for morning brain dump (compatible with new model)
    var gratitude: String = ""
    var intention: String = ""
    var mostImportantTask: String = ""
    var mostImportantTaskCompleted: Bool = false
    
    // Task management state
    var newTaskText: String = ""
    var selectedPriority: TaskPriority = .medium
    var isAddingTask: Bool = false
    
    // Evening reflection state (compatible with new model)
    var dayHighlights: String = ""
    var dailyLearnings: String = ""
    var dayRating: Int = 0
    var tomorrowsFocus: String = ""
    var eveningGratitude: String = ""
    
    init(modelContext: ModelContext?) {
        self.modelContext = modelContext
        if modelContext != nil {
            loadOrCreateTodaysEntry()
        }
    }
    
    // MARK: - Model Context Management
    
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
        loadOrCreateTodaysEntry()
    }
    
    // MARK: - Data Management
    
    func loadOrCreateTodaysEntry() {
        guard let modelContext = modelContext else { return }
        
        let today = Calendar.current.startOfDay(for: Date())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today) ?? Date()
        
        let descriptor = FetchDescriptor<DailyEntry>(
            predicate: #Predicate<DailyEntry> { entry in
                entry.date >= today && entry.date < tomorrow
            }
        )
        
        do {
            let entries = try modelContext.fetch(descriptor)
            if let existingEntry = entries.first {
                currentEntry = existingEntry
                loadStateFromEntry(existingEntry)
            } else {
                let newEntry = DailyEntry(date: today)
                modelContext.insert(newEntry)
                currentEntry = newEntry
                try modelContext.save()
            }
        } catch {
            print("Failed to load or create today's entry: \(error)")
        }
    }
    
    func getOrCreateEntry(for date: Date) -> DailyEntry {
        guard let modelContext = modelContext else {
            // Fallback: create a temporary entry if no context
            return DailyEntry(date: date)
        }
        
        let startOfDay = Calendar.current.startOfDay(for: date)
        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay) ?? Date()
        
        let descriptor = FetchDescriptor<DailyEntry>(
            predicate: #Predicate<DailyEntry> { entry in
                entry.date >= startOfDay && entry.date < endOfDay
            }
        )
        
        do {
            let entries = try modelContext.fetch(descriptor)
            if let existingEntry = entries.first {
                return existingEntry
            } else {
                let newEntry = DailyEntry(date: startOfDay)
                modelContext.insert(newEntry)
                try modelContext.save()
                return newEntry
            }
        } catch {
            print("Failed to load or create entry for \(date): \(error)")
            // Fallback: create a temporary entry
            return DailyEntry(date: startOfDay)
        }
    }
    
    private func loadStateFromEntry(_ entry: DailyEntry) {
        // Load from new model fields (with legacy fallback)
        gratitude = entry.morningGratitude
        intention = entry.morningIntention
        
        // For legacy compatibility, check if we have old task data to migrate
        if !entry.morningGratitude.isEmpty {
            // New model has data, use it
            mostImportantTask = entry.taskQueue.first(where: { $0.priority == 1 })?.taskDescription ?? ""
            mostImportantTaskCompleted = entry.taskQueue.first(where: { $0.priority == 1 })?.isCompleted ?? false
        } else {
            // Try legacy fields if they exist
            if let legacyGratitude = entry.legacyGratitude, !legacyGratitude.isEmpty {
                gratitude = legacyGratitude
            }
            if let legacyIntention = entry.legacyIntention, !legacyIntention.isEmpty {
                intention = legacyIntention
            }
            if let legacyTask = entry.legacyMostImportantTask, !legacyTask.isEmpty {
                mostImportantTask = legacyTask
            }
            if let legacyCompleted = entry.legacyMostImportantTaskCompleted {
                mostImportantTaskCompleted = legacyCompleted
            }
        }
        
        // Evening reflection (use new fields with legacy fallback)
        dayHighlights = entry.todayHighlight
        dailyLearnings = entry.todayLearning
        dayRating = 0 // No direct equivalent in new model
        tomorrowsFocus = entry.tomorrowIntention
        eveningGratitude = entry.todayGratitude
    }
    
    // MARK: - Morning Brain Dump Save Methods
    
    func saveGratitude() {
        guard let entry = currentEntry else { return }
        entry.morningGratitude = gratitude
        saveContext()
    }
    
    func saveIntention() {
        guard let entry = currentEntry else { return }
        entry.morningIntention = intention
        saveContext()
    }
    
    func saveMostImportantTask() {
        guard let entry = currentEntry else { return }
        
        // Update or create the #1 priority task in the new task queue
        if let existingTask = entry.taskQueue.first(where: { $0.priority == 1 }) {
            existingTask.taskDescription = mostImportantTask
        } else if !mostImportantTask.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            let newTask = IvyLeeTask(description: mostImportantTask, priority: 1)
            newTask.dailyEntry = entry
            newTask.isCompleted = mostImportantTaskCompleted
            entry.taskQueue.append(newTask)
        }
        
        syncMostImportantTaskToTaskList()
        saveContext()
    }
    
    func toggleMostImportantTaskCompletion() {
        guard let entry = currentEntry else { return }
        mostImportantTaskCompleted.toggle()
        
        // Update the #1 priority task in the new task queue
        if let task = entry.taskQueue.first(where: { $0.priority == 1 }) {
            task.isCompleted = mostImportantTaskCompleted
            if mostImportantTaskCompleted {
                task.markCompleted()
            }
        }
        
        // Sync with legacy task list
        if let taskInList = findLegacySecondaryTasks().first(where: { $0.isFromMorningBrainDump }) {
            taskInList.isCompleted = mostImportantTaskCompleted
        }
        
        saveContext()
    }
    
    // MARK: - Evening Reflection Save Methods
    
    func saveDayHighlights() {
        guard let entry = currentEntry else { return }
        entry.todayHighlight = dayHighlights
        saveContext()
    }
    
    func saveDailyLearnings() {
        guard let entry = currentEntry else { return }
        entry.todayLearning = dailyLearnings
        saveContext()
    }
    
    func saveDayRating() {
        guard currentEntry != nil else { return }
        // Note: dayRating doesn't have a direct equivalent in new model
        // Could potentially map to energy level or add to smart insights
        saveContext()
    }
    
    func saveTomorrowsFocus() {
        guard let entry = currentEntry else { return }
        entry.tomorrowIntention = tomorrowsFocus
        saveContext()
    }
    
    func saveEveningGratitude() {
        guard let entry = currentEntry else { return }
        entry.todayGratitude = eveningGratitude
        saveContext()
    }
    
    // MARK: - Legacy Task Synchronization (for backward compatibility)
    
    private func syncMostImportantTaskToTaskList() {
        guard let entry = currentEntry else { return }
        
        let trimmedTask = mostImportantTask.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Find existing morning brain dump task in legacy system
        let existingMorningTask = findMorningBrainDumpTask()
        var legacyTasks = findLegacySecondaryTasks()
        
        if trimmedTask.isEmpty {
            // Remove the task if the most important task is cleared
            if let taskToRemove = existingMorningTask {
                if let index = legacyTasks.firstIndex(of: taskToRemove) {
                    legacyTasks.remove(at: index)
                }
                modelContext?.delete(taskToRemove)
            }
        } else {
            if let existingTask = existingMorningTask {
                // Update existing task
                existingTask.taskDescription = trimmedTask
                existingTask.isCompleted = mostImportantTaskCompleted
            } else {
                // Create new high-priority task in legacy system
                let newTask = TaskItem(
                    description: trimmedTask,
                    priority: .high,
                    isFromMorningBrainDump: true
                )
                newTask.dailyEntry = entry
                newTask.isCompleted = mostImportantTaskCompleted
                legacyTasks.append(newTask)
            }
        }
    }
    
    private func findMorningBrainDumpTask() -> TaskItem? {
        return findLegacySecondaryTasks().first { $0.isFromMorningBrainDump }
    }
    
    private func findLegacySecondaryTasks() -> [TaskItem] {
        // For now, return empty array as we're transitioning to new model
        // This could be expanded to handle migration if needed
        return []
    }
    
    var hasMostImportantTaskInList: Bool {
        return findMorningBrainDumpTask() != nil && !mostImportantTask.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    // MARK: - Task Management Methods (Legacy Support)
    
    func addTask() {
        guard !newTaskText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              let entry = currentEntry else { return }
        
        // Add to new task queue as lower priority
        let nextPriority = (entry.taskQueue.map { $0.priority }.max() ?? 0) + 1
        if nextPriority <= 6 { // Ivy Lee method limit
            let newTask = IvyLeeTask(description: newTaskText.trimmingCharacters(in: .whitespacesAndNewlines), priority: nextPriority)
            newTask.dailyEntry = entry
            entry.taskQueue.append(newTask)
        } else {
            // Add to someday/maybe list
            let somedayTask = SomedayMaybeTask(description: newTaskText.trimmingCharacters(in: .whitespacesAndNewlines))
            entry.somedayMaybeTasks.append(somedayTask)
        }
        
        // Reset form
        newTaskText = ""
        selectedPriority = .medium
        isAddingTask = false
        
        saveContext()
    }
    
    func toggleTaskCompletion(_ task: TaskItem) {
        task.isCompleted.toggle()
        
        // If this is the morning brain dump task, sync back to morning brain dump
        if task.isFromMorningBrainDump {
            mostImportantTaskCompleted = task.isCompleted
            // Also update the corresponding IvyLeeTask
            if let ivyTask = currentEntry?.taskQueue.first(where: { $0.priority == 1 }) {
                ivyTask.isCompleted = task.isCompleted
                if task.isCompleted {
                    ivyTask.markCompleted()
                }
            }
        }
        
        saveContext()
    }
    
    func deleteTask(_ task: TaskItem) {
        guard let entry = currentEntry else { return }
        
        // If this is the morning brain dump task, clear the morning brain dump field too
        if task.isFromMorningBrainDump {
            mostImportantTask = ""
            mostImportantTaskCompleted = false
            // Also remove from IvyLeeTask queue
            if let ivyTask = entry.taskQueue.first(where: { $0.priority == 1 }) {
                entry.taskQueue.removeAll { $0 === ivyTask }
                modelContext?.delete(ivyTask)
            }
        }
        
        var legacyTasks = findLegacySecondaryTasks()
        if let index = legacyTasks.firstIndex(of: task) {
            legacyTasks.remove(at: index)
        }
        modelContext?.delete(task)
        saveContext()
    }
    
    func updateTaskPriority(_ task: TaskItem, priority: TaskPriority) {
        // Don't allow changing priority of morning brain dump task (always high)
        if !task.isFromMorningBrainDump {
            task.priority = priority
            saveContext()
        }
    }
    
    func moveTask(from sourceIndexSet: IndexSet, to destinationIndex: Int) {
        // Task reordering will be handled differently in the new Ivy Lee system
        // For now, maintain legacy compatibility
        saveContext()
    }
    
    // MARK: - Task Filtering and Sorting (New Model)
    
    var sortedTasks: [TaskItem] {
        // Return empty for now as we transition to new IvyLeeTask system
        return []
    }
    
    var ivyLeeTasks: [IvyLeeTask] {
        return currentEntry?.taskQueue.sorted { $0.priority < $1.priority } ?? []
    }
    
    var somedayMaybeTasks: [SomedayMaybeTask] {
        return currentEntry?.somedayMaybeTasks ?? []
    }
    
    // MARK: - Helper Methods
    
    public func saveContext() {
        do {
            try modelContext?.save()
        } catch {
            print("Failed to save context: \(error)")
        }
    }
    
    var todayDateString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        return formatter.string(from: Date())
    }
    
    // MARK: - Data Migration Helper
    
    func migrateLegacyData() {
        guard let entry = currentEntry else { return }
        
        // Migrate legacy fields to new structure if they exist
        if let legacyGratitude = entry.legacyGratitude, !legacyGratitude.isEmpty, entry.morningGratitude.isEmpty {
            entry.morningGratitude = legacyGratitude
            entry.legacyGratitude = nil
        }
        
        if let legacyIntention = entry.legacyIntention, !legacyIntention.isEmpty, entry.morningIntention.isEmpty {
            entry.morningIntention = legacyIntention
            entry.legacyIntention = nil
        }
        
        if let legacyTask = entry.legacyMostImportantTask, !legacyTask.isEmpty, entry.taskQueue.isEmpty {
            let ivyTask = IvyLeeTask(description: legacyTask, priority: 1)
            ivyTask.dailyEntry = entry
            ivyTask.isCompleted = entry.legacyMostImportantTaskCompleted ?? false
            entry.taskQueue.append(ivyTask)
            entry.legacyMostImportantTask = nil
            entry.legacyMostImportantTaskCompleted = nil
        }
        
        if let legacyNotes = entry.legacyNotes, !legacyNotes.isEmpty, entry.executionNotes.isEmpty {
            entry.executionNotes = legacyNotes
            entry.legacyNotes = nil
        }
        
        saveContext()
    }
    
    // MARK: - Ritual Completion Tracking
    
    func completeMorningRitual() {
        guard let entry = currentEntry else { return }
        entry.morningRitualCompleted = true
        entry.morningRitualCompletedAt = Date()
        saveContext()
    }
    
    func completeTaskRitual() {
        guard let entry = currentEntry else { return }
        entry.taskRitualCompleted = true
        entry.taskRitualCompletedAt = Date()
        saveContext()
    }
    
    func completeEveningRitual() {
        guard let entry = currentEntry else { return }
        entry.eveningRitualCompleted = true
        entry.eveningRitualCompletedAt = Date()
        saveContext()
    }
    
    var dailyProgressPercentage: Double {
        guard let entry = currentEntry else { return 0.0 }
        
        let completed = [
            entry.morningRitualCompleted,
            entry.taskRitualCompleted,
            entry.eveningRitualCompleted
        ].filter { $0 }.count
        
        return Double(completed) / 3.0
    }
    
    var completedRitualsCount: Int {
        guard let entry = currentEntry else { return 0 }
        
        return [
            entry.morningRitualCompleted,
            entry.taskRitualCompleted,
            entry.eveningRitualCompleted
        ].filter { $0 }.count
    }
} 