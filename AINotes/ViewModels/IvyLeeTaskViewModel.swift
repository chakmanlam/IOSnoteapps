//
//  IvyLeeTaskViewModel.swift
//  Brain Dump
//
//  Created by AI Assistant on 5/23/25.
//

import Foundation
import SwiftData
import SwiftUI

class IvyLeeTaskViewModel: ObservableObject {
    var modelContext: ModelContext?
    var dailyEntryViewModel: DailyEntryViewModel?
    
    // Smart Features Integration
    private var smartFeaturesManager: SmartFeaturesManager?
    
    // Task management state
    var newTaskText: String = ""
    var newTaskReasoning: String = ""
    var selectedPriority: Int = 1
    var isAddingTask: Bool = false
    var isReorderingMode: Bool = false
    
    // Someday/Maybe management
    var somedaySearchText: String = ""
    var selectedSomedayTags: Set<String> = []
    var showSomedayMaybe: Bool = false
    
    // UI feedback
    var showSuccessMessage: String? = nil
    var showErrorMessage: String? = nil
    var lastActionResult: TaskActionResult? = nil
    
    // Smart Features UI State
    var showSmartInsights: Bool = false
    var currentAnalyticsReport: SmartAnalyticsReport = SmartAnalyticsReport.empty
    var recentInsights: [UserInsight] = []
    
    // Default initializer
    init() {
        self.modelContext = nil
        self.dailyEntryViewModel = nil
        self.smartFeaturesManager = nil
    }
    
    // Full initializer for direct use
    init(modelContext: ModelContext, dailyEntryViewModel: DailyEntryViewModel) {
        self.modelContext = modelContext
        self.dailyEntryViewModel = dailyEntryViewModel
        self.smartFeaturesManager = SmartFeaturesManager(modelContext: modelContext)
        
        // Load initial insights
        loadSmartFeatures()
    }
    
    // MARK: - Model Context Management
    
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
        self.smartFeaturesManager = SmartFeaturesManager(modelContext: context)
        loadSmartFeatures()
    }
    
    func setDailyEntryViewModel(_ viewModel: DailyEntryViewModel) {
        self.dailyEntryViewModel = viewModel
    }
    
    // MARK: - Computed Properties
    
    /// Active tasks (not completed) sorted by priority
    var activeTasks: [IvyLeeTask] {
        guard let entry = dailyEntryViewModel?.currentEntry else { return [] }
        return entry.taskQueue
            .filter { !$0.isCompleted }
            .sorted { $0.priority < $1.priority }
    }
    
    /// Completed tasks sorted by completion time
    var completedTasks: [IvyLeeTask] {
        guard let entry = dailyEntryViewModel?.currentEntry else { return [] }
        return entry.taskQueue
            .filter { $0.isCompleted }
            .sorted { ($0.completedAt ?? Date.distantPast) > ($1.completedAt ?? Date.distantPast) }
    }
    
    /// Current task (priority #1)
    var currentTask: IvyLeeTask? {
        return activeTasks.first { $0.priority == 1 }
    }
    
    /// Next tasks (#2-3)
    var nextTasks: [IvyLeeTask] {
        return activeTasks.filter { $0.priority >= 2 && $0.priority <= 3 }
    }
    
    /// Later tasks (#4-6)
    var laterTasks: [IvyLeeTask] {
        return activeTasks.filter { $0.priority >= 4 }
    }
    
    /// Filtered someday/maybe tasks
    var filteredSomedayTasks: [SomedayMaybeTask] {
        guard let entry = dailyEntryViewModel?.currentEntry else { return [] }
        
        var tasks = entry.somedayMaybeTasks
        
        // Apply search filter
        if !somedaySearchText.isEmpty {
            tasks = tasks.filter { task in
                task.taskDescription.localizedCaseInsensitiveContains(somedaySearchText) ||
                task.tags.contains { $0.localizedCaseInsensitiveContains(somedaySearchText) }
            }
        }
        
        // Apply tag filter
        if !selectedSomedayTags.isEmpty {
            tasks = tasks.filter { task in
                !Set(task.tags).isDisjoint(with: selectedSomedayTags)
            }
        }
        
        return tasks.sorted { $0.dateAdded > $1.dateAdded }
    }
    
    /// Available tags from someday tasks
    var availableTags: [String] {
        guard let entry = dailyEntryViewModel?.currentEntry else { return [] }
        let allTags = entry.somedayMaybeTasks.flatMap { $0.tags }
        return Array(Set(allTags)).sorted()
    }
    
    /// Tasks that need review
    var tasksNeedingReview: [SomedayMaybeTask] {
        return filteredSomedayTasks.filter { $0.needsReview }
    }
    
    /// Queue status information
    var queueStatus: QueueStatus {
        let active = activeTasks.count
        let completed = completedTasks.count
        let total = active + completed
        let completionRate = total > 0 ? Double(completed) / Double(total) : 0.0
        
        return QueueStatus(
            activeCount: active,
            completedCount: completed,
            completionRate: completionRate,
            hasOpenSlots: active < TaskQueueManager.maxActiveTasksLimit,
            availableSlots: TaskQueueManager.maxActiveTasksLimit - active
        )
    }
    
    // MARK: - Task Management Actions
    
    /// Adds a new task with smart duration prediction
    func addTask() {
        guard !newTaskText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              let entry = dailyEntryViewModel?.currentEntry else {
            showError("Please enter a task description")
            return
        }
        
        // Get smart duration prediction
        let predictedDuration = predictTaskDuration(for: newTaskText)
        
        let result = TaskQueueManager.addTask(
            description: newTaskText.trimmingCharacters(in: .whitespacesAndNewlines),
            reasoning: newTaskReasoning.trimmingCharacters(in: .whitespacesAndNewlines),
            to: entry,
            preferredPriority: selectedPriority
        )
        
        if result.success {
            // Apply predicted duration
            result.addedTask?.estimatedDuration = predictedDuration
            
            // Clear form
            newTaskText = ""
            newTaskReasoning = ""
            selectedPriority = 1
            isAddingTask = false
            
            // Show success message with smart info
            var message = "Task added successfully! 🎯"
            if predictedDuration != 3600 { // Not default
                let hours = Int(predictedDuration / 3600)
                let minutes = Int((predictedDuration.truncatingRemainder(dividingBy: 3600)) / 60)
                if hours > 0 {
                    message += " (Est: \(hours)h \(minutes)m)"
                } else {
                    message += " (Est: \(minutes)m)"
                }
            }
            
            if let _ = result.movedToSomeday {
                message = "Task added! ✨ One task moved to Someday/Maybe due to 6-task limit."
            }
            
            showSuccess(message)
            
            lastActionResult = TaskActionResult(
                action: .added,
                taskDescription: result.addedTask?.taskDescription ?? "",
                details: result.movedToSomeday?.taskDescription
            )
            
            // Update smart features
            loadSmartFeatures()
            
            saveContext()
        } else {
            showError("Failed to add task")
        }
    }
    
    /// Marks a task as completed
    func completeTask(_ task: IvyLeeTask) {
        task.markCompleted()
        
        // Record smart features data
        recordTaskCompletion(for: task)
        
        // Update current task focus if this was the #1 task
        if task.priority == 1, let entry = dailyEntryViewModel?.currentEntry {
            // Update to next highest priority task or clear
            let nextTask = activeTasks.first { $0.priority == 2 }
            entry.currentTaskFocus = nextTask?.taskDescription ?? ""
        }
        
        showSuccess("Task completed! 🎉")
        lastActionResult = TaskActionResult(
            action: .completed,
            taskDescription: task.taskDescription
        )
        
        saveContext()
    }
    
    /// Updates task priority with smart features integration
    func updateTaskPriority(_ task: IvyLeeTask, to newPriority: Int) {
        guard let entry = dailyEntryViewModel?.currentEntry else { return }
        
        let oldPriority = task.priority
        TaskQueueManager.updateTaskPriority(task, to: newPriority, in: &entry.taskQueue)
        
        // Update current task focus if priority #1 changed
        if newPriority == 1 || oldPriority == 1 {
            entry.currentTaskFocus = currentTask?.taskDescription ?? ""
        }
        
        // Update analytics
        loadSmartFeatures()
        
        showSuccess("Priority updated! 📊")
        saveContext()
    }
    
    /// Moves task to someday/maybe
    func moveTaskToSomeday(_ task: IvyLeeTask) {
        guard let entry = dailyEntryViewModel?.currentEntry else { return }
        
        _ = TaskQueueManager.moveTaskToSomeday(task, from: entry)
        
        showSuccess("Task moved to Someday/Maybe 📝")
        lastActionResult = TaskActionResult(
            action: .movedToSomeday,
            taskDescription: task.taskDescription
        )
        
        saveContext()
    }
    
    /// Promotes a someday task to active queue
    func promoteTask(_ somedayTask: SomedayMaybeTask, toPriority priority: Int, withReasoning reasoning: String = "") {
        guard let entry = dailyEntryViewModel?.currentEntry else { return }
        
        let result = TaskQueueManager.promoteTask(
            somedayTask,
            to: entry,
            withPriority: priority,
            reasoning: reasoning
        )
        
        if result.success {
            showSuccess("Task promoted to active queue! 🚀")
            
            if let demoted = result.demotedTask {
                lastActionResult = TaskActionResult(
                    action: .promoted,
                    taskDescription: somedayTask.taskDescription,
                    details: "Demoted: \(demoted.taskDescription)"
                )
            } else {
                lastActionResult = TaskActionResult(
                    action: .promoted,
                    taskDescription: somedayTask.taskDescription
                )
            }
            
            saveContext()
        } else {
            showError("Failed to promote task")
        }
    }
    
    /// Deletes a someday task permanently
    func deleteSomedayTask(_ task: SomedayMaybeTask) {
        guard let entry = dailyEntryViewModel?.currentEntry,
              let index = entry.somedayMaybeTasks.firstIndex(where: { $0 === task }) else { return }
        
        entry.somedayMaybeTasks.remove(at: index)
        
        showSuccess("Task deleted 🗑️")
        saveContext()
    }
    
    /// Marks a someday task as reviewed
    func markTaskReviewed(_ task: SomedayMaybeTask) {
        task.markReviewed()
        saveContext()
    }
    
    // MARK: - Batch Actions
    
    /// Clear all completed tasks
    func clearCompletedTasks() {
        guard let entry = dailyEntryViewModel?.currentEntry else { return }
        
        let completedCount = completedTasks.count
        entry.taskQueue = entry.taskQueue.filter { !$0.isCompleted }
        
        showSuccess("Cleared \(completedCount) completed tasks ✨")
        saveContext()
    }
    
    /// Review all tasks needing review
    func markAllReviewed() {
        tasksNeedingReview.forEach { $0.markReviewed() }
        showSuccess("All tasks marked as reviewed 📖")
        saveContext()
    }
    
    // MARK: - Energy-Based Suggestions
    
    /// Get energy-based task suggestions
    func getEnergyBasedSuggestion() -> EnergyAllocationSuggestion? {
        guard let entry = dailyEntryViewModel?.currentEntry else { return nil }
        
        // Use current energy level from morning check or default to medium
        let energyLevel = entry.morningEnergyCheck
        return TaskQueueManager.suggestEnergyAllocation(for: energyLevel, in: entry)
    }
    
    // MARK: - Smart Features Integration
    
    /// Loads smart features and insights for the current entry
    func loadSmartFeatures() {
        guard let entry = dailyEntryViewModel?.currentEntry else { return }
        
        // Update analytics report
        currentAnalyticsReport = smartFeaturesManager?.generateAnalyticsReport(for: entry) ?? SmartAnalyticsReport.empty
        
        // Load recent insights
        recentInsights = smartFeaturesManager?.getRecentInsights(for: entry) ?? []
        
        // Update streaks
        smartFeaturesManager?.updateStreaks(for: entry)
        
        // Analyze patterns
        smartFeaturesManager?.analyzeTaskCompletionPatterns(for: entry)
    }
    
    /// Predicts duration for a new task using AI learning
    func predictTaskDuration(for taskDescription: String) -> TimeInterval {
        guard let entry = dailyEntryViewModel?.currentEntry else { return 3600 }
        return smartFeaturesManager?.predictTaskDuration(for: taskDescription, in: entry) ?? 3600
    }
    
    /// Suggests optimal time for a task type
    func suggestOptimalTime(for taskDescription: String) -> Date? {
        guard let entry = dailyEntryViewModel?.currentEntry else { return nil }
        return smartFeaturesManager?.suggestOptimalTime(for: taskDescription, in: entry)
    }
    
    /// Generates fresh insights based on current patterns
    func generateInsights() {
        guard let entry = dailyEntryViewModel?.currentEntry else { return }
        
        let newInsights = smartFeaturesManager?.generateInsights(for: entry) ?? []
        recentInsights = smartFeaturesManager?.getRecentInsights(for: entry) ?? []
        
        if !newInsights.isEmpty {
            showSuccess("💡 New insights generated!")
        }
    }
    
    /// Acknowledges an insight (marks as read)
    func acknowledgeInsight(_ insight: UserInsight) {
        smartFeaturesManager?.acknowledgeInsight(insight)
        
        // Refresh insights list
        guard let entry = dailyEntryViewModel?.currentEntry else { return }
        recentInsights = smartFeaturesManager?.getRecentInsights(for: entry) ?? []
    }
    
    /// Checks if evening reminder should be shown
    func shouldShowEveningReminder() -> Bool {
        guard let entry = dailyEntryViewModel?.currentEntry else { return false }
        return smartFeaturesManager?.shouldShowEveningReminder(for: entry) ?? false
    }
    
    /// Configures evening reminder settings
    func configureEveningReminder(time: Date, enabled: Bool, message: String) {
        guard let entry = dailyEntryViewModel?.currentEntry else { return }
        smartFeaturesManager?.configureEveningReminder(time: time, enabled: enabled, message: message, for: entry)
        showSuccess("Evening reminder configured! 🌙")
    }
    
    /// Records optimal timing when a task is completed
    func recordTaskCompletion(for task: IvyLeeTask) {
        // Record optimal timing
        smartFeaturesManager?.recordOptimalTaskTiming(for: task, completedAt: Date())
        
        // Update time estimation accuracy
        smartFeaturesManager?.updateTimeEstimation(for: task)
        
        // Refresh analytics
        loadSmartFeatures()
    }
    
    /// Updates energy prediction accuracy
    func updateEnergyAccuracy(predicted: EnergyLevel, actual: EnergyLevel) {
        guard let entry = dailyEntryViewModel?.currentEntry else { return }
        smartFeaturesManager?.updateEnergyLevelAccuracy(predicted: predicted, actual: actual, for: entry)
    }
    
    /// Gets smart suggestions for task prioritization
    func getSmartPrioritySuggestions() -> [TaskPrioritySuggestion] {
        guard let entry = dailyEntryViewModel?.currentEntry else { return [] }
        
        var suggestions: [TaskPrioritySuggestion] = []
        
        // Energy-based suggestions
        if let energySuggestion = getEnergyBasedSuggestion() {
            for (index, task) in energySuggestion.recommendedTasks.enumerated() {
                suggestions.append(TaskPrioritySuggestion(
                    task: task,
                    reason: "Optimal for \(entry.morningEnergyCheck.description)",
                    confidence: 0.8,
                    suggestedPriority: index + 1
                ))
            }
        }
        
        return suggestions
    }
    
    /// Gets the current day's completion summary with smart insights
    var smartDaySummary: DaySummary {
        let activeCount = activeTasks.count
        let completedCount = completedTasks.count
        let completionRate = queueStatus.completionRate
        
        // Calculate streak info
        let maxStreak = max(currentAnalyticsReport.eveningPlanningStreak,
                           currentAnalyticsReport.morningExecutionStreak,
                           currentAnalyticsReport.taskCompletionStreak)
        
        // Generate summary message
        var message = ""
        if completedCount == 0 && activeCount == 0 {
            message = "Ready to start your productive day! ✨"
        } else if completionRate >= 0.8 {
            message = "Excellent progress! You're crushing it today! 🔥"
        } else if completionRate >= 0.5 {
            message = "Good momentum! Keep pushing forward! 💪"
        } else {
            message = "Every step counts. Focus on your #1 priority! 🎯"
        }
        
        return DaySummary(
            completionRate: completionRate,
            completedTasks: completedCount,
            activeTasks: activeCount,
            currentStreak: maxStreak,
            message: message,
            insights: recentInsights.prefix(2).map { $0 }
        )
    }
    
    // MARK: - Additional Task Management Methods
    
    /// Starts a focus timer for a specific task
    func startFocusTimer(for task: IvyLeeTask) {
        guard let entry = dailyEntryViewModel?.currentEntry else { return }
        
        // Set current task focus
        entry.currentTaskFocus = task.taskDescription
        entry.focusTimerState = .running
        
        // Record start time for smart features (if available)
        // smartFeaturesManager?.recordTaskStartTime(for: task, at: Date())
        
        showSuccess("Focus timer started for: \(task.taskDescription) ⏰")
        saveContext()
    }
    
    /// Adds a quick task with minimal information
    func addQuickTask(description: String) {
        guard let entry = dailyEntryViewModel?.currentEntry else { return }
        
        let result = TaskQueueManager.addTask(
            description: description,
            reasoning: "",
            to: entry,
            preferredPriority: activeTasks.count + 1
        )
        
        if result.success {
            showSuccess("Quick task added! 🚀")
            saveContext()
        } else {
            showError("Failed to add quick task")
        }
    }
    
    /// Promotes a someday task to active queue
    func promoteTaskFromSomeday(_ task: SomedayMaybeTask) {
        promoteTask(task, toPriority: activeTasks.count + 1, withReasoning: "Promoted from Someday/Maybe")
    }
    
    /// Reorders a task to a new position
    func reorderTask(_ task: IvyLeeTask, toPosition newPosition: Int) {
        guard let entry = dailyEntryViewModel?.currentEntry else { return }
        
        let oldPriority = task.priority
        TaskQueueManager.updateTaskPriority(task, to: newPosition, in: &entry.taskQueue)
        
        showSuccess("Task moved from #\(oldPriority) to #\(newPosition)")
        saveContext()
    }
    
    /// Computed property for someday tasks (alias for filteredSomedayTasks)
    var somedayTasks: [SomedayMaybeTask] {
        return filteredSomedayTasks
    }
    
    /// Processes brain dump text into structured tasks
    func processBrainDumpText(_ text: String) async {
        // This would typically use AI to parse the brain dump text
        // For now, we'll create a simple implementation
        let lines = text.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        
        await MainActor.run {
            for line in lines.prefix(6) { // Limit to 6 tasks max
                newTaskText = line
                addTask()
            }
            showSuccess("Brain dump processed into \(min(lines.count, 6)) tasks! 🧠")
        }
    }
    
    /// Gets recent insights for display
    func getRecentInsights() -> [UserInsight]? {
        return recentInsights.isEmpty ? nil : recentInsights
    }
    
    // MARK: - Helper Methods
    
    private func showSuccess(_ message: String) {
        showSuccessMessage = message
        showErrorMessage = nil
        
        // Clear message after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            self.showSuccessMessage = nil
        }
    }
    
    private func showError(_ message: String) {
        showErrorMessage = message
        showSuccessMessage = nil
        
        // Clear message after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
            self.showErrorMessage = nil
        }
    }
    
    private func saveContext() {
        do {
            try modelContext?.save()
        } catch {
            showError("Failed to save changes: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Form Helpers
    
    func resetAddTaskForm() {
        newTaskText = ""
        newTaskReasoning = ""
        selectedPriority = 1
        isAddingTask = false
    }
    
    func validateTaskInput() -> Bool {
        return !newTaskText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    /// Triggers a refresh of the task data and UI updates
    func refreshTasks() {
        objectWillChange.send()
        loadSmartFeatures()
    }
}

// MARK: - Supporting Types

struct QueueStatus {
    let activeCount: Int
    let completedCount: Int
    let completionRate: Double
    let hasOpenSlots: Bool
    let availableSlots: Int
    
    var statusEmoji: String {
        switch activeCount {
        case 0: return "✨"
        case 1...2: return "🎯"
        case 3...4: return "💪"
        case 5...6: return "🔥"
        default: return "⚠️"
        }
    }
    
    var statusText: String {
        switch activeCount {
        case 0: return "Queue is empty - add your first task!"
        case 1...2: return "Light load - perfect for deep work"
        case 3...4: return "Balanced queue - good focus needed"
        case 5...6: return "Full queue - maximum capacity"
        default: return "Over capacity!"
        }
    }
    
    var completionText: String {
        if completedCount == 0 && activeCount == 0 {
            return "Ready to start your day"
        } else if completedCount == 0 {
            return "No tasks completed yet"
        } else {
            let percentage = Int(completionRate * 100)
            return "\(completedCount) completed (\(percentage)%)"
        }
    }
}

struct TaskActionResult {
    let action: TaskAction
    let taskDescription: String
    let details: String?
    
    init(action: TaskAction, taskDescription: String, details: String? = nil) {
        self.action = action
        self.taskDescription = taskDescription
        self.details = details
    }
}

enum TaskAction {
    case added
    case completed
    case promoted
    case movedToSomeday
    case priorityChanged
    case deleted
    
    var emoji: String {
        switch self {
        case .added: return "➕"
        case .completed: return "✅"
        case .promoted: return "⬆️"
        case .movedToSomeday: return "📝"
        case .priorityChanged: return "🔄"
        case .deleted: return "🗑️"
        }
    }
}

// MARK: - Smart Features Supporting Types

struct TaskPrioritySuggestion {
    let task: IvyLeeTask
    let reason: String
    let confidence: Double
    let suggestedPriority: Int
    
    var displayText: String {
        "#\(suggestedPriority): \(task.taskDescription) - \(reason) (Confidence: \(Int(confidence * 100))%)"
    }
}

struct DaySummary {
    let completionRate: Double
    let completedTasks: Int
    let activeTasks: Int
    let currentStreak: Int
    let message: String
    let insights: [UserInsight]
    
    var completionEmoji: String {
        switch completionRate {
        case 0.9...1.0: return "🔥"
        case 0.7..<0.9: return "💪"
        case 0.5..<0.7: return "⚡"
        case 0.2..<0.5: return "🌱"
        default: return "✨"
        }
    }
    
    var streakText: String {
        if currentStreak >= 7 {
            return "🔥 \(currentStreak)-day streak!"
        } else if currentStreak >= 3 {
            return "💪 \(currentStreak) days strong!"
        } else if currentStreak > 0 {
            return "⚡ \(currentStreak) day(s)!"
        } else {
            return "Start your streak today! ✨"
        }
    }
    
    var progressText: String {
        let percentage = Int(completionRate * 100)
        return "\(completedTasks) completed (\(percentage)%)"
    }
} 