//
//  BrainDumpModels.swift
//  Brain Dump
//
//  Created by Chak Man Lam on 5/22/25.
//

import Foundation
import SwiftData
import UniformTypeIdentifiers
import CoreTransferable

// MARK: - Core Models

@Model
class DailyEntry {
    var date: Date
    
    // MARK: - Evening Planning (The Planning Ritual)
    
    // Today's Reflection
    var todayHighlight: String // What went well today?
    var todayLearning: String // What insights did you capture?
    var todayRemembrance: String // Key takeaways for future
    var todayGratitude: String // What are you appreciative of?
    
    // Tomorrow's Planning
    var tomorrowIntention: String // "Tomorrow I will..."
    var tomorrowEnergyPrediction: EnergyLevel // high/medium/low
    var tomorrowCalendarPreview: String // Meeting context for task planning
    var taskBrainDumpText: String // Unlimited initial task capture
    
    // MARK: - Morning Execution (The Execution Ritual)
    
    // Morning Brain Dump
    var brainDumpText: String? // Free-form morning brain dump text
    var whyMostImportant: String // Why is the #1 priority most important today
    
    // Mindset Preparation
    var morningGratitude: String // Quick gratitude (can be pre-filled from suggestions)
    var morningIntention: String // Display of yesterday's intention setting
    var morningEnergyCheck: EnergyLevel // How do you feel? affects task approach
    
    // Mission Dashboard
    var currentTaskFocus: String // Track which task is currently being worked on
    var focusTimerState: TimerState // Timer state for current task
    var executionNotes: String // Quick notes captured during task execution
    
    // MARK: - Ritual Completion Tracking
    var morningRitualCompleted: Bool // Morning Brain Dump completion
    var taskRitualCompleted: Bool // Task Brain Dump completion  
    var eveningRitualCompleted: Bool // Evening Brain Dump completion
    var morningRitualCompletedAt: Date? // When morning ritual was completed
    var taskRitualCompletedAt: Date? // When task ritual was completed
    var eveningRitualCompletedAt: Date? // When evening ritual was completed
    
    // Legacy fields (for migration compatibility)
    @Attribute(.unique) var legacyGratitude: String? // Will migrate to morningGratitude
    @Attribute(.unique) var legacyIntention: String? // Will migrate to morningIntention
    @Attribute(.unique) var legacyMostImportantTask: String? // Will migrate to TaskQueue
    @Attribute(.unique) var legacyMostImportantTaskCompleted: Bool?
    @Attribute(.unique) var legacyNotes: String? // Will migrate to executionNotes
    
    // Relationships
    var taskQueue: [IvyLeeTask] // Maximum 6 prioritized tasks
    var somedayMaybeTasks: [SomedayMaybeTask] // Overflow tasks
    var scheduleEntries: [ScheduleEntry] // Existing schedule entries
    var smartInsights: SmartFeatures? // AI insights and patterns
    
    init(date: Date) {
        self.date = date
        
        // Evening Planning
        self.todayHighlight = ""
        self.todayLearning = ""
        self.todayRemembrance = ""
        self.todayGratitude = ""
        self.tomorrowIntention = ""
        self.tomorrowEnergyPrediction = .medium
        self.tomorrowCalendarPreview = ""
        self.taskBrainDumpText = ""
        
        // Morning Execution
        self.brainDumpText = ""
        self.whyMostImportant = ""
        self.morningGratitude = ""
        self.morningIntention = ""
        self.morningEnergyCheck = .medium
        self.currentTaskFocus = ""
        self.focusTimerState = .stopped
        self.executionNotes = ""
        
        // Ritual Completion Tracking
        self.morningRitualCompleted = false
        self.taskRitualCompleted = false
        self.eveningRitualCompleted = false
        self.morningRitualCompletedAt = nil
        self.taskRitualCompletedAt = nil
        self.eveningRitualCompletedAt = nil
        
        // Relationships
        self.taskQueue = []
        self.somedayMaybeTasks = []
        self.scheduleEntries = []
        
        // Legacy fields (for migration)
        self.legacyGratitude = nil
        self.legacyIntention = nil
        self.legacyMostImportantTask = nil
        self.legacyMostImportantTaskCompleted = nil
        self.legacyNotes = nil
    }
}

// MARK: - Ivy Lee Method Implementation

@Model
class IvyLeeTask {
    var taskDescription: String
    var priority: Int // 1-6, with 1 being most important
    var isCompleted: Bool
    var whyImportantReasoning: String // "Why is #1 most important?"
    var createdAt: Date
    var completedAt: Date?
    var estimatedDuration: TimeInterval // Learned from user patterns
    var actualDuration: TimeInterval? // Track for learning
    
    // Relationship
    var dailyEntry: DailyEntry?
    
    init(description: String, priority: Int, reasoning: String = "") {
        self.taskDescription = description
        self.priority = priority
        self.isCompleted = false
        self.whyImportantReasoning = reasoning
        self.createdAt = Date()
        self.estimatedDuration = 3600 // Default 1 hour
    }
    
    func markCompleted() {
        self.isCompleted = true
        self.completedAt = Date()
        
        // Calculate actual duration if task was started
        if let startTime = dailyEntry?.smartInsights?.taskStartTimes[taskDescription] {
            self.actualDuration = Date().timeIntervalSince(startTime)
        }
    }
    
    // MARK: - Task Queue Management Methods
    
    /// Updates the priority and shifts other tasks accordingly
    func updatePriority(to newPriority: Int, in tasks: inout [IvyLeeTask]) {
        self.priority = newPriority
        
        // Shift other tasks to maintain proper ordering
        TaskQueueManager.reorderTasks(&tasks)
    }
    
    /// Gets the display emoji for priority level
    var priorityEmoji: String {
        switch priority {
        case 1: return "🔥" // Most important
        case 2: return "⚡"
        case 3: return "💪"
        case 4: return "✨"
        case 5: return "📝"
        case 6: return "🌱"
        default: return "❓"
        }
    }
    
    /// Gets display text for why this task is at its current priority
    var priorityDisplayText: String {
        switch priority {
        case 1: return "Most Important Task - Start here!"
        case 2: return "High Priority - Do after #1"
        case 3: return "Important - Focus after top 2"
        case 4: return "Moderate Priority"
        case 5: return "Lower Priority"
        case 6: return "Lowest Priority"
        default: return "Unknown Priority"
        }
    }
    
    /// Gets formatted duration string for display
    var formattedEstimatedDuration: String {
        let hours = Int(estimatedDuration / 3600)
        let minutes = Int((estimatedDuration.truncatingRemainder(dividingBy: 3600)) / 60)
        
        if hours > 0 {
            if minutes > 0 {
                return "\(hours)h \(minutes)m"
            } else {
                return "\(hours)h"
            }
        } else {
            return "\(minutes)m"
        }
    }
}

// MARK: - IvyLeeTask Transferable Conformance
extension IvyLeeTask: Transferable {
    static var transferRepresentation: some TransferRepresentation {
        ProxyRepresentation(exporting: \.taskDescription)
    }
}

// Custom UTType for IvyLeeTask
extension UTType {
    static let ivyLeeTask = UTType(exportedAs: "com.braindump.ivyleetask")
}

@Model
class SomedayMaybeTask {
    var taskDescription: String
    var dateAdded: Date
    var tags: [String] // For categorization and filtering
    var sourceContext: String // Where this task came from (brain dump, quick capture, etc.)
    var priority: SomedayPriority // Different priority system for someday tasks
    var lastReviewed: Date? // When was this last considered for promotion
    
    init(description: String, tags: [String] = [], context: String = "brain_dump") {
        self.taskDescription = description
        self.dateAdded = Date()
        self.tags = tags
        self.sourceContext = context
        self.priority = .medium
        self.lastReviewed = nil
    }
    
    // Convert to active task for the 6-task queue
    func convertToIvyLeeTask(priority: Int, reasoning: String = "") -> IvyLeeTask {
        return IvyLeeTask(description: taskDescription, priority: priority, reasoning: reasoning)
    }
    
    /// Mark as reviewed (helps with weekly reviews)
    func markReviewed() {
        lastReviewed = Date()
    }
    
    /// Get age of task in days
    var ageInDays: Int {
        return Calendar.current.dateComponents([.day], from: dateAdded, to: Date()).day ?? 0
    }
    
    /// Check if task needs review (older than 2 weeks without review)
    var needsReview: Bool {
        guard let lastReviewed = lastReviewed else { return ageInDays > 14 }
        let daysSinceReview = Calendar.current.dateComponents([.day], from: lastReviewed, to: Date()).day ?? 0
        return daysSinceReview > 14
    }
}

// MARK: - Smart Features & Pattern Recognition

@Model
class SmartFeatures {
    var dailyEntry: DailyEntry?
    
    // Pattern Recognition
    var taskCompletionPatterns: [String: Double] // Task type -> completion rate
    var energyLevelAccuracy: [String: Double] // Predicted vs actual energy correlation
    var optimalTaskTiming: [String: TimeInterval] // Task type -> best time of day
    var strugglingTaskPatterns: [String: Int] // Tasks that often get pushed to #3+ position
    
    // Time Estimation Learning
    var taskDurationLearning: [String: TimeInterval] // Task patterns -> average duration
    var timeEstimationAccuracy: Double // How accurate are our estimates?
    
    // Streaks and Progress
    var eveningPlanningStreak: Int
    var morningExecutionStreak: Int
    var taskCompletionStreak: Int
    var longestStreak: Int
    
    // User Insights (Generated patterns)
    var generatedInsights: [UserInsight]
    
    // Timer tracking
    var taskStartTimes: [String: Date] // Track when tasks were started
    
    // Evening Reminder Configuration
    var eveningReminderTime: Date
    var reminderEnabled: Bool
    var reminderMessage: String
    
    init() {
        self.taskCompletionPatterns = [:]
        self.energyLevelAccuracy = [:]
        self.optimalTaskTiming = [:]
        self.strugglingTaskPatterns = [:]
        self.taskDurationLearning = [:]
        self.timeEstimationAccuracy = 0.7 // Start with 70% baseline
        
        self.eveningPlanningStreak = 0
        self.morningExecutionStreak = 0
        self.taskCompletionStreak = 0
        self.longestStreak = 0
        
        self.generatedInsights = []
        self.taskStartTimes = [:]
        
        // Default reminder for 8 PM
        self.eveningReminderTime = Calendar.current.date(bySettingHour: 20, minute: 0, second: 0, of: Date()) ?? Date()
        self.reminderEnabled = true
        self.reminderMessage = "Ready to plan tomorrow? Transform chaos into clarity 🌙"
    }
}

@Model
class UserInsight {
    var insightText: String
    var insightType: InsightType
    var confidence: Double // 0.0 - 1.0
    var dateGenerated: Date
    var isAcknowledged: Bool // User has seen this insight
    var actionable: Bool // Whether this insight suggests a specific action
    
    init(text: String, type: InsightType, confidence: Double = 0.8) {
        self.insightText = text
        self.insightType = type
        self.confidence = confidence
        self.dateGenerated = Date()
        self.isAcknowledged = false
        self.actionable = type.isActionable
    }
}

// MARK: - Existing Models (Updated)

@Model
class ScheduleEntry {
    var time: Date
    var endTime: Date
    var taskDescription: String
    var color: String
    var dailyEntry: DailyEntry?
    
    init(time: Date, endTime: Date? = nil, description: String, color: String = "#A3BFCB") {
        self.time = time
        self.endTime = endTime ?? time.addingTimeInterval(3600) // Default 1 hour if no end time provided
        self.taskDescription = description
        self.color = color
    }
}

// Legacy TaskItem (will be migrated to IvyLeeTask)
@Model
class TaskItem {
    var taskDescription: String
    var isCompleted: Bool
    var priority: TaskPriority
    var isFromMorningBrainDump: Bool
    var dailyEntry: DailyEntry?
    
    init(description: String, priority: TaskPriority = .medium, isFromMorningBrainDump: Bool = false) {
        self.taskDescription = description
        self.isCompleted = false
        self.priority = priority
        self.isFromMorningBrainDump = isFromMorningBrainDump
    }
}

// MARK: - Enums

enum EnergyLevel: String, CaseIterable, Codable {
    case high = "High"
    case medium = "Medium"
    case low = "Low"
    
    var emoji: String {
        switch self {
        case .high: return "⚡"
        case .medium: return "🔥"
        case .low: return "🌱"
        }
    }
    
    var description: String {
        switch self {
        case .high: return "High Energy - Ready to tackle challenging tasks"
        case .medium: return "Medium Energy - Good for most tasks"
        case .low: return "Low Energy - Focus on lighter, easier tasks"
        }
    }
}

enum TimerState: String, CaseIterable, Codable {
    case stopped = "Stopped"
    case running = "Running"
    case paused = "Paused"
    case completed = "Completed"
}

enum SomedayPriority: String, CaseIterable, Codable {
    case high = "High"
    case medium = "Medium"
    case low = "Low"
    case someday = "Someday"
}

enum InsightType: String, CaseIterable, Codable {
    case patternRecognition = "Pattern Recognition"
    case timeEstimation = "Time Estimation"
    case energyOptimization = "Energy Optimization"
    case taskStruggles = "Task Struggles"
    case streakMotivation = "Streak Motivation"
    case workflowOptimization = "Workflow Optimization"
    
    var isActionable: Bool {
        switch self {
        case .patternRecognition, .timeEstimation, .energyOptimization, .taskStruggles, .workflowOptimization:
            return true
        case .streakMotivation:
            return false
        }
    }
}

// Legacy enum (for migration compatibility)
enum TaskPriority: String, CaseIterable, Codable {
    case high = "High"
    case medium = "Medium"
    case low = "Low"
    
    var emoji: String {
        switch self {
        case .high: return "🔥"
        case .medium: return "⚡"
        case .low: return "🌱"
        }
    }
    
    var color: String {
        switch self {
        case .high: return "red"
        case .medium: return "blue"
        case .low: return "green"
        }
    }
}

// Legacy Habit model (may be removed in future versions)
@Model
class Habit {
    var name: String
    var icon: String
    var isActive: Bool
    var createdAt: Date
    
    init(name: String, icon: String = "circle") {
        self.name = name
        self.icon = icon
        self.isActive = true
        self.createdAt = Date()
    }
}

// MARK: - Task Queue Manager

class TaskQueueManager {
    static let maxActiveTasksLimit = 6 // Ivy Lee Method limit
    
    // MARK: - Queue Management
    
    /// Adds a new task to the queue, moving excess tasks to someday/maybe
    static func addTask(
        description: String,
        reasoning: String = "",
        to dailyEntry: DailyEntry,
        preferredPriority: Int? = nil
    ) -> (success: Bool, addedTask: IvyLeeTask?, movedToSomeday: SomedayMaybeTask?) {
        
        let activeTasks = dailyEntry.taskQueue.filter { !$0.isCompleted }
        
        // Determine the priority for the new task
        let newPriority: Int
        if let preferred = preferredPriority, preferred >= 1, preferred <= maxActiveTasksLimit {
            newPriority = preferred
        } else {
            newPriority = min(activeTasks.count + 1, maxActiveTasksLimit)
        }
        
        let newTask = IvyLeeTask(description: description, priority: newPriority, reasoning: reasoning)
        newTask.dailyEntry = dailyEntry
        
        // If we're at capacity, move the lowest priority task to someday/maybe
        var movedTask: SomedayMaybeTask? = nil
        if activeTasks.count >= maxActiveTasksLimit {
            if let lastTask = activeTasks.sorted(by: { $0.priority > $1.priority }).first {
                movedTask = moveTaskToSomeday(lastTask, from: dailyEntry)
            }
        }
        
        // Add the new task and reorder
        dailyEntry.taskQueue.append(newTask)
        reorderTasks(&dailyEntry.taskQueue)
        
        return (success: true, addedTask: newTask, movedToSomeday: movedTask)
    }
    
    /// Promotes a someday/maybe task to the active queue
    static func promoteTask(
        _ somedayTask: SomedayMaybeTask,
        to dailyEntry: DailyEntry,
        withPriority priority: Int,
        reasoning: String = ""
    ) -> (success: Bool, promotedTask: IvyLeeTask?, demotedTask: SomedayMaybeTask?) {
        
        let activeTasks = dailyEntry.taskQueue.filter { !$0.isCompleted }
        var demotedTask: SomedayMaybeTask? = nil
        
        // If at capacity, demote lowest priority active task
        if activeTasks.count >= maxActiveTasksLimit {
            if let lastTask = activeTasks.sorted(by: { $0.priority > $1.priority }).first {
                demotedTask = moveTaskToSomeday(lastTask, from: dailyEntry)
            }
        }
        
        // Create new active task
        let promotedTask = somedayTask.convertToIvyLeeTask(priority: priority, reasoning: reasoning)
        promotedTask.dailyEntry = dailyEntry
        dailyEntry.taskQueue.append(promotedTask)
        
        // Remove from someday/maybe
        if let index = dailyEntry.somedayMaybeTasks.firstIndex(where: { $0 === somedayTask }) {
            dailyEntry.somedayMaybeTasks.remove(at: index)
        }
        
        reorderTasks(&dailyEntry.taskQueue)
        
        return (success: true, promotedTask: promotedTask, demotedTask: demotedTask)
    }
    
    /// Moves a task from active queue to someday/maybe
    @discardableResult
    static func moveTaskToSomeday(_ task: IvyLeeTask, from dailyEntry: DailyEntry) -> SomedayMaybeTask {
        let somedayTask = SomedayMaybeTask(
            description: task.taskDescription,
            tags: ["demoted"], // Tag to track that this was demoted
            context: "queue_overflow"
        )
        
        // Remove from active queue
        if let index = dailyEntry.taskQueue.firstIndex(where: { $0 === task }) {
            dailyEntry.taskQueue.remove(at: index)
        }
        
        // Add to someday/maybe
        dailyEntry.somedayMaybeTasks.append(somedayTask)
        
        // Reorder remaining active tasks
        reorderTasks(&dailyEntry.taskQueue)
        
        return somedayTask
    }
    
    /// Reorders tasks to maintain proper 1-6 priority sequence
    static func reorderTasks(_ tasks: inout [IvyLeeTask]) {
        let activeTasks = tasks.filter { !$0.isCompleted }
        let completedTasks = tasks.filter { $0.isCompleted }
        
        // Sort active tasks by current priority
        let sortedActive = activeTasks.sorted { $0.priority < $1.priority }
        
        // Reassign priorities 1-6
        for (index, task) in sortedActive.enumerated() {
            task.priority = index + 1
        }
        
        // Reconstruct the array with active + completed
        tasks = sortedActive + completedTasks
    }
    
    /// Updates task priority and reorders the queue
    static func updateTaskPriority(_ task: IvyLeeTask, to newPriority: Int, in tasks: inout [IvyLeeTask]) {
        guard newPriority >= 1 && newPriority <= maxActiveTasksLimit else { return }
        
        let activeTasks = tasks.filter { !$0.isCompleted }
        guard activeTasks.contains(where: { $0 === task }) else { return }
        
        task.priority = newPriority
        reorderTasks(&tasks)
    }
    
    // MARK: - Rollover Management
    
    /// Handles end-of-day rollover logic for incomplete tasks
    static func rolloverIncompleteTasks(from currentEntry: DailyEntry, to nextEntry: DailyEntry) -> RolloverResult {
        let incompleteTasks = currentEntry.taskQueue.filter { !$0.isCompleted }
        var rolledOverTasks: [IvyLeeTask] = []
        var movedToSomeday: [SomedayMaybeTask] = []
        
        for task in incompleteTasks {
            // Create new task for next day
            let newTask = IvyLeeTask(
                description: task.taskDescription,
                priority: task.priority,
                reasoning: task.whyImportantReasoning
            )
            newTask.dailyEntry = nextEntry
            
            // Check if we have space in tomorrow's queue
            let activeTomorrowTasks = nextEntry.taskQueue.filter { !$0.isCompleted }
            if activeTomorrowTasks.count < maxActiveTasksLimit {
                nextEntry.taskQueue.append(newTask)
                rolledOverTasks.append(newTask)
            } else {
                // Move to someday/maybe if tomorrow is full
                let somedayTask = SomedayMaybeTask(
                    description: task.taskDescription,
                    tags: ["rollover"],
                    context: "daily_rollover"
                )
                nextEntry.somedayMaybeTasks.append(somedayTask)
                movedToSomeday.append(somedayTask)
            }
        }
        
        reorderTasks(&nextEntry.taskQueue)
        
        return RolloverResult(
            rolledOverTasks: rolledOverTasks,
            movedToSomeday: movedToSomeday,
            totalIncomplete: incompleteTasks.count
        )
    }
    
    // MARK: - Analytics & Insights
    
    /// Calculates completion rate for the current queue
    static func calculateCompletionRate(for dailyEntry: DailyEntry) -> Double {
        let totalTasks = dailyEntry.taskQueue.count
        guard totalTasks > 0 else { return 0.0 }
        
        let completedTasks = dailyEntry.taskQueue.filter { $0.isCompleted }.count
        return Double(completedTasks) / Double(totalTasks)
    }
    
    /// Gets tasks that frequently get pushed to lower priorities
    static func getStrugglingTasks(for dailyEntry: DailyEntry) -> [IvyLeeTask] {
        return dailyEntry.taskQueue.filter { task in
            task.priority >= 4 && !task.isCompleted
        }
    }
    
    /// Suggests optimal energy allocation based on task priorities and current energy
    static func suggestEnergyAllocation(
        for energyLevel: EnergyLevel,
        in dailyEntry: DailyEntry
    ) -> EnergyAllocationSuggestion {
        let activeTasks = dailyEntry.taskQueue.filter { !$0.isCompleted }.sorted { $0.priority < $1.priority }
        
        switch energyLevel {
        case .high:
            return EnergyAllocationSuggestion(
                recommendedTasks: Array(activeTasks.prefix(3)),
                suggestion: "Perfect time for your top 3 priorities! Tackle the most important work now.",
                energyEmoji: "⚡"
            )
        case .medium:
            let midTasks = Array(activeTasks.dropFirst(1).prefix(3))
            return EnergyAllocationSuggestion(
                recommendedTasks: midTasks,
                suggestion: "Good energy for tasks #2-4. Save the biggest challenge for high energy time.",
                energyEmoji: "🔥"
            )
        case .low:
            let lightTasks = Array(activeTasks.dropFirst(3))
            return EnergyAllocationSuggestion(
                recommendedTasks: lightTasks,
                suggestion: "Low energy time - perfect for lighter tasks #4-6 or planning tomorrow.",
                energyEmoji: "🌱"
            )
        }
    }
}

// MARK: - Supporting Types

struct RolloverResult {
    let rolledOverTasks: [IvyLeeTask]
    let movedToSomeday: [SomedayMaybeTask]
    let totalIncomplete: Int
    
    var summary: String {
        let rolledCount = rolledOverTasks.count
        let somedayCount = movedToSomeday.count
        
        if totalIncomplete == 0 {
            return "🎉 Perfect! All tasks completed."
        } else if somedayCount == 0 {
            return "📋 \(rolledCount) task(s) rolled over to tomorrow."
        } else {
            return "📋 \(rolledCount) task(s) rolled over, \(somedayCount) moved to someday/maybe."
        }
    }
}

struct EnergyAllocationSuggestion {
    let recommendedTasks: [IvyLeeTask]
    let suggestion: String
    let energyEmoji: String
}

// MARK: - SomedayPriority Extension
extension SomedayPriority {
    var displayName: String {
        switch self {
        case .high: return "High"
        case .medium: return "Medium"
        case .low: return "Low"
        case .someday: return "Someday"
        }
    }
} 