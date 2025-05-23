//
//  ServiceProtocols.swift
//  Brain Dump
//
//  Created by AI Assistant on 5/23/25.
//

import Foundation
import SwiftData
import UserNotifications

// MARK: - Task Management Service Protocol

protocol TaskManagementService {
    /// Adds a new task to the queue
    static func addTask(description: String, reasoning: String, to dailyEntry: DailyEntry, preferredPriority: Int?) -> (success: Bool, addedTask: IvyLeeTask?, movedToSomeday: SomedayMaybeTask?)
    
    /// Promotes a someday task to active queue
    static func promoteTask(_ somedayTask: SomedayMaybeTask, to dailyEntry: DailyEntry, withPriority priority: Int, reasoning: String) -> (success: Bool, promotedTask: IvyLeeTask?, demotedTask: SomedayMaybeTask?)
    
    /// Moves a task to someday/maybe list
    static func moveTaskToSomeday(_ task: IvyLeeTask, from dailyEntry: DailyEntry) -> SomedayMaybeTask
    
    /// Reorders tasks to maintain priority sequence
    static func reorderTasks(_ tasks: inout [IvyLeeTask])
    
    /// Updates task priority
    static func updateTaskPriority(_ task: IvyLeeTask, to newPriority: Int, in tasks: inout [IvyLeeTask])
    
    /// Handles end-of-day rollover
    static func rolloverIncompleteTasks(from currentEntry: DailyEntry, to nextEntry: DailyEntry) -> RolloverResult
    
    /// Calculates completion rate
    static func calculateCompletionRate(for dailyEntry: DailyEntry) -> Double
    
    /// Gets struggling tasks
    static func getStrugglingTasks(for dailyEntry: DailyEntry) -> [IvyLeeTask]
    
    /// Suggests energy allocation
    static func suggestEnergyAllocation(for energyLevel: EnergyLevel, in dailyEntry: DailyEntry) -> EnergyAllocationSuggestion
}

// MARK: - Smart Features Service Protocol

protocol SmartFeaturesService {
    /// Analyzes task completion patterns
    func analyzeTaskCompletionPatterns(for dailyEntry: DailyEntry)
    
    /// Updates time estimation learning
    func updateTimeEstimation(for task: IvyLeeTask)
    
    /// Updates energy level accuracy
    func updateEnergyLevelAccuracy(predicted: EnergyLevel, actual: EnergyLevel, for dailyEntry: DailyEntry)
    
    /// Records optimal task timing
    func recordOptimalTaskTiming(for task: IvyLeeTask, completedAt: Date)
    
    /// Updates streaks
    func updateStreaks(for dailyEntry: DailyEntry)
    
    /// Generates insights
    func generateInsights(for dailyEntry: DailyEntry) -> [UserInsight]
    
    /// Gets recent insights
    func getRecentInsights(for dailyEntry: DailyEntry, limit: Int) -> [UserInsight]
    
    /// Acknowledges insight
    func acknowledgeInsight(_ insight: UserInsight)
    
    /// Predicts task duration
    func predictTaskDuration(for taskDescription: String, in dailyEntry: DailyEntry) -> TimeInterval
    
    /// Suggests optimal time
    func suggestOptimalTime(for taskDescription: String, in dailyEntry: DailyEntry) -> Date?
    
    /// Configures evening reminder
    func configureEveningReminder(time: Date, enabled: Bool, message: String, for dailyEntry: DailyEntry)
    
    /// Checks if evening reminder should show
    func shouldShowEveningReminder(for dailyEntry: DailyEntry) -> Bool
    
    /// Generates analytics report
    func generateAnalyticsReport(for dailyEntry: DailyEntry) -> SmartAnalyticsReport
    
    /// Calculates average energy accuracy
    func calculateAverageEnergyAccuracy(_ smartFeatures: SmartFeatures) -> Double
    
    /// Loads smart features
    func loadSmartFeatures()
}

// MARK: - Notification Service Protocol

protocol NotificationService {
    /// Notification permission status
    var notificationPermissionGranted: Bool { get }
    var notificationSettings: UNNotificationSettings? { get }
    
    /// Permission management
    func requestNotificationPermission() async -> Bool
    func checkNotificationPermission() async
    
    /// Evening reminder management
    func scheduleEveningReminder(for dailyEntry: DailyEntry) async
    func cancelEveningReminders() async
    func updateEveningReminder(for dailyEntry: DailyEntry) async
    
    /// Task completion notifications
    func notifyTaskMilestone(completedCount: Int, totalCount: Int, streakCount: Int) async
    
    /// Smart insight notifications
    func notifyImportantInsight(_ insight: UserInsight) async
    
    /// Morning motivation notifications
    func scheduleMorningMotivation(basedOn dailyEntry: DailyEntry, for tomorrowDate: Date) async
    
    /// Utility methods
    func getPendingNotifications() async -> [UNNotificationRequest]
    func cancelAllNotifications()
    func setupNotificationCategories()
    
    /// Integration with smart features
    func configureWithSmartFeatures(_ smartFeaturesManager: SmartFeaturesService, for dailyEntry: DailyEntry) async
}

// MARK: - Service Container Protocol

protocol ServiceContainerProtocol {
    /// Service state
    var isInitialized: Bool { get }
    var servicesReady: Bool { get }
    
    /// Initialization
    func initialize(with modelContext: ModelContext) async
    
    /// Service access
    func getSmartFeaturesManager() -> SmartFeaturesService?
    func getNotificationManager() -> NotificationService
    
    /// Integrated operations
    func performDailySetup(for dailyEntry: DailyEntry) async
    func handleTaskCompletion(_ task: IvyLeeTask, in dailyEntry: DailyEntry) async
    func handleEveningPlanningComplete(for dailyEntry: DailyEntry) async
    func handleEnergyLevelUpdate(predicted: EnergyLevel, actual: EnergyLevel, for dailyEntry: DailyEntry) async
    func configureEveningReminder(time: Date, enabled: Bool, message: String, for dailyEntry: DailyEntry) async
    
    /// Analytics and health
    func generateComprehensiveReport(for dailyEntry: DailyEntry) async -> ComprehensiveReport?
    func performHealthCheck() -> ServiceHealthReport
    func resetServices() async
}

// MARK: - Service Factory Protocol

protocol ServiceFactory {
    /// Creates task management service
    static func createTaskManagementService() -> TaskManagementService.Type
    
    /// Creates smart features service
    static func createSmartFeaturesService(with modelContext: ModelContext) -> SmartFeaturesService
    
    /// Creates notification service
    static func createNotificationService() -> NotificationService
    
    /// Creates service container
    static func createServiceContainer() -> ServiceContainerProtocol
}

// MARK: - Default Service Factory Implementation

class DefaultServiceFactory: ServiceFactory {
    static func createTaskManagementService() -> TaskManagementService.Type {
        return TaskQueueManager.self
    }
    
    static func createSmartFeaturesService(with modelContext: ModelContext) -> SmartFeaturesService {
        return SmartFeaturesManager(modelContext: modelContext)
    }
    
    static func createNotificationService() -> NotificationService {
        return NotificationManager.shared
    }
    
    static func createServiceContainer() -> ServiceContainerProtocol {
        return ServiceContainer.shared
    }
}

// MARK: - Protocol Extensions

extension TaskQueueManager: TaskManagementService {
    // TaskQueueManager already implements all required methods
}

extension SmartFeaturesManager: SmartFeaturesService {
    // SmartFeaturesManager already implements all required methods
}

extension NotificationManager: NotificationService {
    // NotificationManager already implements all required methods
}

extension ServiceContainer: ServiceContainerProtocol {
    // ServiceContainer already implements all required methods
} 