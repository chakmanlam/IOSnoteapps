//
//  SmartFeaturesManager.swift
//  Brain Dump
//
//  Created by AI Assistant on 5/23/25.
//

import Foundation
import SwiftData
import SwiftUI

@Observable
class SmartFeaturesManager {
    var modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - Pattern Recognition & Learning
    
    /// Analyzes task completion patterns and updates the SmartFeatures model
    func analyzeTaskCompletionPatterns(for dailyEntry: DailyEntry) {
        guard let smartFeatures = getOrCreateSmartFeatures(for: dailyEntry) else { return }
        
        let completedTasks = dailyEntry.taskQueue.filter { $0.isCompleted }
        let totalTasks = dailyEntry.taskQueue.count
        
        // Update completion patterns by task type
        for task in completedTasks {
            let taskType = extractTaskType(from: task.taskDescription)
            let currentRate = smartFeatures.taskCompletionPatterns[taskType] ?? 0.0
            let newRate = (currentRate + 1.0) / max(1.0, Double(totalTasks))
            smartFeatures.taskCompletionPatterns[taskType] = newRate
        }
        
        // Track struggling tasks (tasks that consistently get deprioritized)
        for task in dailyEntry.taskQueue where !task.isCompleted && task.priority >= 4 {
            let taskType = extractTaskType(from: task.taskDescription)
            smartFeatures.strugglingTaskPatterns[taskType] = (smartFeatures.strugglingTaskPatterns[taskType] ?? 0) + 1
        }
        
        saveContext()
    }
    
    /// Updates time estimation accuracy based on actual vs predicted task duration
    func updateTimeEstimation(for task: IvyLeeTask) {
        guard let dailyEntry = task.dailyEntry,
              let smartFeatures = getOrCreateSmartFeatures(for: dailyEntry),
              let actualDuration = task.actualDuration,
              actualDuration > 0 else { return }
        
        let estimatedDuration = task.estimatedDuration
        let accuracy = min(estimatedDuration, actualDuration) / max(estimatedDuration, actualDuration)
        
        // Update overall accuracy with moving average
        let currentAccuracy = smartFeatures.timeEstimationAccuracy
        smartFeatures.timeEstimationAccuracy = (currentAccuracy * 0.8) + (accuracy * 0.2)
        
        // Update duration learning for this task type
        let taskType = extractTaskType(from: task.taskDescription)
        let currentAverage = smartFeatures.taskDurationLearning[taskType] ?? estimatedDuration
        smartFeatures.taskDurationLearning[taskType] = (currentAverage * 0.7) + (actualDuration * 0.3)
        
        saveContext()
    }
    
    /// Analyzes energy level prediction accuracy
    func updateEnergyLevelAccuracy(predicted: EnergyLevel, actual: EnergyLevel, for dailyEntry: DailyEntry) {
        guard let smartFeatures = getOrCreateSmartFeatures(for: dailyEntry) else { return }
        
        let accuracy = predicted == actual ? 1.0 : 0.0
        let energyKey = "\(predicted.rawValue)_to_\(actual.rawValue)"
        let currentAccuracy = smartFeatures.energyLevelAccuracy[energyKey] ?? 0.5
        smartFeatures.energyLevelAccuracy[energyKey] = (currentAccuracy * 0.8) + (accuracy * 0.2)
        
        saveContext()
    }
    
    /// Records optimal timing for different types of tasks
    func recordOptimalTaskTiming(for task: IvyLeeTask, completedAt: Date) {
        guard let dailyEntry = task.dailyEntry,
              let smartFeatures = getOrCreateSmartFeatures(for: dailyEntry) else { return }
        
        let taskType = extractTaskType(from: task.taskDescription)
        let timeOfDay = Calendar.current.component(.hour, from: completedAt) * 3600 + 
                       Calendar.current.component(.minute, from: completedAt) * 60
        
        // Store as TimeInterval from start of day
        smartFeatures.optimalTaskTiming[taskType] = TimeInterval(timeOfDay)
        
        saveContext()
    }
    
    // MARK: - Streak Management
    
    /// Updates streaks based on daily activities
    func updateStreaks(for dailyEntry: DailyEntry) {
        guard let smartFeatures = getOrCreateSmartFeatures(for: dailyEntry) else { return }
        
        let today = Calendar.current.startOfDay(for: dailyEntry.date)
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!
        
        // Check if yesterday's entry exists and had activity
        let yesterdayHadActivity = checkPreviousDayActivity(date: yesterday)
        
        // Evening Planning Streak
        let hasEveningPlanning = !dailyEntry.todayHighlight.isEmpty || 
                                !dailyEntry.tomorrowIntention.isEmpty ||
                                dailyEntry.taskQueue.count > 0
        
        if hasEveningPlanning {
            smartFeatures.eveningPlanningStreak = yesterdayHadActivity ? smartFeatures.eveningPlanningStreak + 1 : 1
        } else {
            smartFeatures.eveningPlanningStreak = 0
        }
        
        // Morning Execution Streak
        let hasMorningExecution = !dailyEntry.morningGratitude.isEmpty ||
                                 !dailyEntry.currentTaskFocus.isEmpty ||
                                 dailyEntry.taskQueue.contains { $0.isCompleted }
        
        if hasMorningExecution {
            smartFeatures.morningExecutionStreak = yesterdayHadActivity ? smartFeatures.morningExecutionStreak + 1 : 1
        } else {
            smartFeatures.morningExecutionStreak = 0
        }
        
        // Task Completion Streak
        let hasCompletedTasks = dailyEntry.taskQueue.contains { $0.isCompleted }
        if hasCompletedTasks {
            smartFeatures.taskCompletionStreak = yesterdayHadActivity ? smartFeatures.taskCompletionStreak + 1 : 1
        } else {
            smartFeatures.taskCompletionStreak = 0
        }
        
        // Update longest streak
        let currentMaxStreak = max(smartFeatures.eveningPlanningStreak, 
                                  smartFeatures.morningExecutionStreak, 
                                  smartFeatures.taskCompletionStreak)
        smartFeatures.longestStreak = max(smartFeatures.longestStreak, currentMaxStreak)
        
        saveContext()
    }
    
    // MARK: - Insight Generation
    
    /// Generates actionable insights based on accumulated patterns
    func generateInsights(for dailyEntry: DailyEntry) -> [UserInsight] {
        guard let smartFeatures = getOrCreateSmartFeatures(for: dailyEntry) else { return [] }
        
        var insights: [UserInsight] = []
        
        // Pattern Recognition Insights
        insights.append(contentsOf: generatePatternInsights(smartFeatures))
        
        // Time Estimation Insights
        insights.append(contentsOf: generateTimeEstimationInsights(smartFeatures))
        
        // Energy Optimization Insights
        insights.append(contentsOf: generateEnergyInsights(smartFeatures))
        
        // Streak Motivation Insights
        insights.append(contentsOf: generateStreakInsights(smartFeatures))
        
        // Task Struggle Insights
        insights.append(contentsOf: generateTaskStruggleInsights(smartFeatures))
        
        // Workflow Optimization Insights
        insights.append(contentsOf: generateWorkflowInsights(smartFeatures))
        
        // Add new insights to the model (avoid duplicates)
        for insight in insights {
            if !smartFeatures.generatedInsights.contains(where: { 
                $0.insightText == insight.insightText && $0.insightType == insight.insightType 
            }) {
                smartFeatures.generatedInsights.append(insight)
            }
        }
        
        saveContext()
        return insights
    }
    
    /// Gets recent unacknowledged insights
    func getRecentInsights(for dailyEntry: DailyEntry, limit: Int = 3) -> [UserInsight] {
        guard let smartFeatures = getOrCreateSmartFeatures(for: dailyEntry) else { return [] }
        
        return smartFeatures.generatedInsights
            .filter { !$0.isAcknowledged }
            .sorted { $0.confidence > $1.confidence }
            .prefix(limit)
            .map { $0 }
    }
    
    /// Marks an insight as acknowledged
    func acknowledgeInsight(_ insight: UserInsight) {
        insight.isAcknowledged = true
        saveContext()
    }
    
    // MARK: - Time Estimation Predictions
    
    /// Predicts duration for a new task based on learned patterns
    func predictTaskDuration(for taskDescription: String, in dailyEntry: DailyEntry) -> TimeInterval {
        guard let smartFeatures = getOrCreateSmartFeatures(for: dailyEntry) else { 
            return 3600 // Default 1 hour
        }
        
        let taskType = extractTaskType(from: taskDescription)
        let learnedDuration = smartFeatures.taskDurationLearning[taskType]
        
        if let learned = learnedDuration {
            // Apply accuracy adjustment
            let adjustmentFactor = smartFeatures.timeEstimationAccuracy
            return learned * adjustmentFactor
        } else {
            // Find similar task types
            let similarTypes = smartFeatures.taskDurationLearning.keys.filter { key in
                taskDescription.localizedCaseInsensitiveContains(key) || key.localizedCaseInsensitiveContains(taskType)
            }
            
            if !similarTypes.isEmpty {
                let averageDuration = similarTypes.compactMap { smartFeatures.taskDurationLearning[$0] }.reduce(0, +) / Double(similarTypes.count)
                return averageDuration
            }
            
            return 3600 // Default 1 hour
        }
    }
    
    /// Suggests optimal time of day for a task type
    func suggestOptimalTime(for taskDescription: String, in dailyEntry: DailyEntry) -> Date? {
        guard let smartFeatures = getOrCreateSmartFeatures(for: dailyEntry) else { return nil }
        
        let taskType = extractTaskType(from: taskDescription)
        guard let optimalTimeInterval = smartFeatures.optimalTaskTiming[taskType] else { return nil }
        
        let startOfDay = Calendar.current.startOfDay(for: dailyEntry.date)
        return startOfDay.addingTimeInterval(optimalTimeInterval)
    }
    
    // MARK: - Evening Reminder Management
    
    /// Configures evening reminder settings
    func configureEveningReminder(time: Date, enabled: Bool, message: String, for dailyEntry: DailyEntry) {
        guard let smartFeatures = getOrCreateSmartFeatures(for: dailyEntry) else { return }
        
        smartFeatures.eveningReminderTime = time
        smartFeatures.reminderEnabled = enabled
        smartFeatures.reminderMessage = message
        
        saveContext()
    }
    
    /// Checks if it's time for evening reminder
    func shouldShowEveningReminder(for dailyEntry: DailyEntry) -> Bool {
        guard let smartFeatures = getOrCreateSmartFeatures(for: dailyEntry),
              smartFeatures.reminderEnabled else { return false }
        
        let now = Date()
        let reminderTime = smartFeatures.eveningReminderTime
        
        // Check if current time is within 30 minutes of reminder time
        let timeDifference = abs(now.timeIntervalSince(reminderTime))
        return timeDifference <= 1800 // 30 minutes
    }
    
    // MARK: - Analytics & Reporting
    
    /// Generates a comprehensive analytics report
    func generateAnalyticsReport(for dailyEntry: DailyEntry) -> SmartAnalyticsReport {
        guard let smartFeatures = getOrCreateSmartFeatures(for: dailyEntry) else {
            return SmartAnalyticsReport.empty
        }
        
        let completionRate = TaskQueueManager.calculateCompletionRate(for: dailyEntry)
        let strugglingTasks = TaskQueueManager.getStrugglingTasks(for: dailyEntry)
        
        return SmartAnalyticsReport(
            overallCompletionRate: completionRate,
            timeEstimationAccuracy: smartFeatures.timeEstimationAccuracy,
            eveningPlanningStreak: smartFeatures.eveningPlanningStreak,
            morningExecutionStreak: smartFeatures.morningExecutionStreak,
            taskCompletionStreak: smartFeatures.taskCompletionStreak,
            longestStreak: smartFeatures.longestStreak,
            strugglingTaskCount: strugglingTasks.count,
            topTaskTypes: Array(smartFeatures.taskCompletionPatterns.sorted { $0.value > $1.value }.prefix(3)),
            recentInsights: getRecentInsights(for: dailyEntry),
            energyAccuracy: calculateAverageEnergyAccuracy(smartFeatures)
        )
    }
    
    // MARK: - Private Helper Methods
    
    private func getOrCreateSmartFeatures(for dailyEntry: DailyEntry) -> SmartFeatures? {
        if let existing = dailyEntry.smartInsights {
            return existing
        }
        
        let newSmartFeatures = SmartFeatures()
        dailyEntry.smartInsights = newSmartFeatures
        return newSmartFeatures
    }
    
    private func extractTaskType(from description: String) -> String {
        // Simple task type extraction based on keywords
        let lowercased = description.lowercased()
        
        if lowercased.contains("email") || lowercased.contains("message") || lowercased.contains("reply") {
            return "communication"
        } else if lowercased.contains("meeting") || lowercased.contains("call") || lowercased.contains("discuss") {
            return "meeting"
        } else if lowercased.contains("write") || lowercased.contains("document") || lowercased.contains("report") {
            return "writing"
        } else if lowercased.contains("code") || lowercased.contains("develop") || lowercased.contains("program") {
            return "development"
        } else if lowercased.contains("review") || lowercased.contains("check") || lowercased.contains("analyze") {
            return "review"
        } else if lowercased.contains("plan") || lowercased.contains("organize") || lowercased.contains("prepare") {
            return "planning"
        } else if lowercased.contains("learn") || lowercased.contains("study") || lowercased.contains("research") {
            return "learning"
        } else {
            return "general"
        }
    }
    
    private func checkPreviousDayActivity(date: Date) -> Bool {
        // Query for previous day's entry and check if it had any activity
        let startOfDay = Calendar.current.startOfDay(for: date)
        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let descriptor = FetchDescriptor<DailyEntry>(
            predicate: #Predicate<DailyEntry> { entry in
                entry.date >= startOfDay && entry.date < endOfDay
            }
        )
        
        do {
            let entries = try modelContext.fetch(descriptor)
            if let previousEntry = entries.first {
                return !previousEntry.todayHighlight.isEmpty || 
                       !previousEntry.morningGratitude.isEmpty ||
                       previousEntry.taskQueue.contains { $0.isCompleted }
            }
        } catch {
            print("Error fetching previous day activity: \(error)")
        }
        
        return false
    }
    
    /// Calculates average energy accuracy (public for ServiceContainer integration)
    func calculateAverageEnergyAccuracy(_ smartFeatures: SmartFeatures) -> Double {
        let accuracyValues = Array(smartFeatures.energyLevelAccuracy.values)
        guard !accuracyValues.isEmpty else { return 0.0 }
        return accuracyValues.reduce(0, +) / Double(accuracyValues.count)
    }
    
    /// Loads smart features for the current entry (for ServiceContainer integration)
    func loadSmartFeatures() {
        // This method can be expanded to perform any initialization logic
        // Currently, the smart features are loaded on-demand in other methods
    }
    
    private func saveContext() {
        do {
            try modelContext.save()
        } catch {
            print("Failed to save SmartFeatures context: \(error)")
        }
    }
}

// MARK: - Insight Generation Methods

extension SmartFeaturesManager {
    
    private func generatePatternInsights(_ smartFeatures: SmartFeatures) -> [UserInsight] {
        var insights: [UserInsight] = []
        
        // Find most successful task types
        if let topTaskType = smartFeatures.taskCompletionPatterns.max(by: { $0.value < $1.value }),
           topTaskType.value > 0.8 {
            insights.append(UserInsight(
                text: "You consistently excel at \(topTaskType.key) tasks! Consider scheduling more during your peak hours.",
                type: .patternRecognition,
                confidence: topTaskType.value
            ))
        }
        
        return insights
    }
    
    private func generateTimeEstimationInsights(_ smartFeatures: SmartFeatures) -> [UserInsight] {
        var insights: [UserInsight] = []
        
        if smartFeatures.timeEstimationAccuracy < 0.6 {
            insights.append(UserInsight(
                text: "Your time estimates tend to be off. Try breaking larger tasks into smaller, more predictable chunks.",
                type: .timeEstimation,
                confidence: 1.0 - smartFeatures.timeEstimationAccuracy
            ))
        } else if smartFeatures.timeEstimationAccuracy > 0.85 {
            insights.append(UserInsight(
                text: "Excellent time estimation skills! You're great at predicting how long tasks will take.",
                type: .timeEstimation,
                confidence: smartFeatures.timeEstimationAccuracy
            ))
        }
        
        return insights
    }
    
    private func generateEnergyInsights(_ smartFeatures: SmartFeatures) -> [UserInsight] {
        var insights: [UserInsight] = []
        
        // Find optimal task timing patterns
        let morningTasks = smartFeatures.optimalTaskTiming.filter { $0.value < 43200 } // Before noon
        let afternoonTasks = smartFeatures.optimalTaskTiming.filter { $0.value >= 43200 }
        
        if morningTasks.count > afternoonTasks.count {
            insights.append(UserInsight(
                text: "You tend to be most productive in the morning. Consider scheduling your most important tasks before noon.",
                type: .energyOptimization,
                confidence: 0.8
            ))
        }
        
        return insights
    }
    
    private func generateStreakInsights(_ smartFeatures: SmartFeatures) -> [UserInsight] {
        var insights: [UserInsight] = []
        
        let maxStreak = max(smartFeatures.eveningPlanningStreak, 
                           smartFeatures.morningExecutionStreak, 
                           smartFeatures.taskCompletionStreak)
        
        if maxStreak >= 7 {
            insights.append(UserInsight(
                text: "Amazing! You're on a \(maxStreak)-day streak. Consistency is building your success momentum! 🔥",
                type: .streakMotivation,
                confidence: 0.9
            ))
        } else if maxStreak >= 3 {
            insights.append(UserInsight(
                text: "Great work! \(maxStreak) days in a row. Keep the momentum going! 💪",
                type: .streakMotivation,
                confidence: 0.75
            ))
        }
        
        return insights
    }
    
    private func generateTaskStruggleInsights(_ smartFeatures: SmartFeatures) -> [UserInsight] {
        var insights: [UserInsight] = []
        
        if let strugglingType = smartFeatures.strugglingTaskPatterns.max(by: { $0.value < $1.value }),
           strugglingType.value >= 3 {
            insights.append(UserInsight(
                text: "\(strugglingType.key.capitalized) tasks often get pushed down your priority list. Consider breaking them into smaller steps or scheduling them at your peak energy time.",
                type: .taskStruggles,
                confidence: 0.8
            ))
        }
        
        return insights
    }
    
    private func generateWorkflowInsights(_ smartFeatures: SmartFeatures) -> [UserInsight] {
        var insights: [UserInsight] = []
        
        // Check for workflow optimization opportunities
        if smartFeatures.eveningPlanningStreak > smartFeatures.morningExecutionStreak + 2 {
            insights.append(UserInsight(
                text: "You're great at evening planning but could improve morning execution. Try preparing your workspace the night before.",
                type: .workflowOptimization,
                confidence: 0.75
            ))
        }
        
        return insights
    }
}

// MARK: - Supporting Types

struct SmartAnalyticsReport {
    let overallCompletionRate: Double
    let timeEstimationAccuracy: Double
    let eveningPlanningStreak: Int
    let morningExecutionStreak: Int
    let taskCompletionStreak: Int
    let longestStreak: Int
    let strugglingTaskCount: Int
    let topTaskTypes: [(key: String, value: Double)]
    let recentInsights: [UserInsight]
    let energyAccuracy: Double
    
    static let empty = SmartAnalyticsReport(
        overallCompletionRate: 0.0,
        timeEstimationAccuracy: 0.0,
        eveningPlanningStreak: 0,
        morningExecutionStreak: 0,
        taskCompletionStreak: 0,
        longestStreak: 0,
        strugglingTaskCount: 0,
        topTaskTypes: [],
        recentInsights: [],
        energyAccuracy: 0.0
    )
    
    var summary: String {
        """
        📊 Smart Analytics Report
        
        ✅ Completion Rate: \(Int(overallCompletionRate * 100))%
        ⏱️ Time Estimation: \(Int(timeEstimationAccuracy * 100))% accurate
        🔥 Longest Streak: \(longestStreak) days
        ⚡ Current Streaks: Evening \(eveningPlanningStreak) | Morning \(morningExecutionStreak) | Tasks \(taskCompletionStreak)
        """
    }
} 