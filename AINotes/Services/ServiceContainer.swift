//
//  ServiceContainer.swift
//  Brain Dump
//
//  Created by AI Assistant on 5/23/25.
//

import Foundation
import SwiftData

/// Central service container for dependency injection and service coordination
@Observable
class ServiceContainer {
    static let shared = ServiceContainer()
    
    // Core services
    let notificationManager: NotificationManager
    private var smartFeaturesManager: SmartFeaturesManager?
    
    // Service state
    var isInitialized: Bool = false
    var servicesReady: Bool = false
    
    private init() {
        self.notificationManager = NotificationManager.shared
    }
    
    // MARK: - Service Initialization
    
    /// Initializes all services with the model context
    func initialize(with modelContext: ModelContext) async {
        guard !isInitialized else { return }
        
        // Initialize SmartFeaturesManager with context
        smartFeaturesManager = SmartFeaturesManager(modelContext: modelContext)
        
        // Setup notification categories
        notificationManager.setupNotificationCategories()
        
        // Request notification permissions if not already granted
        if !notificationManager.notificationPermissionGranted {
            _ = await notificationManager.requestNotificationPermission()
        }
        
        isInitialized = true
        servicesReady = true
        
        print("✅ ServiceContainer initialized successfully")
    }
    
    // MARK: - Service Access
    
    /// Gets the SmartFeaturesManager instance
    func getSmartFeaturesManager() -> SmartFeaturesService? {
        guard isInitialized else {
            print("⚠️ ServiceContainer not initialized. Call initialize(with:) first.")
            return nil
        }
        return smartFeaturesManager
    }
    
    /// Gets the NotificationManager instance
    func getNotificationManager() -> NotificationService {
        return notificationManager
    }
    
    // MARK: - Integrated Service Operations
    
    /// Performs daily setup tasks for a given entry
    func performDailySetup(for dailyEntry: DailyEntry) async {
        guard let smartManager = getSmartFeaturesManager() else { return }
        
        // Load and analyze smart features
        smartManager.loadSmartFeatures()
        smartManager.updateStreaks(for: dailyEntry)
        smartManager.analyzeTaskCompletionPatterns(for: dailyEntry)
        
        // Configure notifications based on smart features
        await notificationManager.configureWithSmartFeatures(smartManager, for: dailyEntry)
        
        print("✅ Daily setup completed for \(dailyEntry.date)")
    }
    
    /// Handles task completion with integrated services
    func handleTaskCompletion(_ task: IvyLeeTask, in dailyEntry: DailyEntry) async {
        guard let smartManager = getSmartFeaturesManager() else { return }
        
        // Record smart features data
        smartManager.recordOptimalTaskTiming(for: task, completedAt: Date())
        smartManager.updateTimeEstimation(for: task)
        
        // Check for milestone notifications
        let activeTasks = dailyEntry.taskQueue.filter { !$0.isCompleted }
        let completedTasks = dailyEntry.taskQueue.filter { $0.isCompleted }
        let streakCount = dailyEntry.smartInsights?.taskCompletionStreak ?? 0
        
        await notificationManager.notifyTaskMilestone(
            completedCount: completedTasks.count,
            totalCount: activeTasks.count + completedTasks.count,
            streakCount: streakCount
        )
        
        // Generate and notify new insights
        let insights = smartManager.generateInsights(for: dailyEntry)
        for insight in insights where insight.confidence >= 0.8 && insight.actionable {
            await notificationManager.notifyImportantInsight(insight)
        }
    }
    
    /// Handles evening planning completion
    func handleEveningPlanningComplete(for dailyEntry: DailyEntry) async {
        guard let smartManager = getSmartFeaturesManager() else { return }
        
        // Update streaks
        smartManager.updateStreaks(for: dailyEntry)
        
        // Schedule tomorrow's morning motivation
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: dailyEntry.date) ?? Date()
        await notificationManager.scheduleMorningMotivation(basedOn: dailyEntry, for: tomorrow)
        
        // Generate workflow insights
        let insights = smartManager.generateInsights(for: dailyEntry)
        for insight in insights where insight.insightType == .workflowOptimization {
            await notificationManager.notifyImportantInsight(insight)
        }
    }
    
    /// Handles energy level updates with accuracy tracking
    func handleEnergyLevelUpdate(predicted: EnergyLevel, actual: EnergyLevel, for dailyEntry: DailyEntry) async {
        guard let smartManager = getSmartFeaturesManager() else { return }
        
        smartManager.updateEnergyLevelAccuracy(predicted: predicted, actual: actual, for: dailyEntry)
        
        // Generate energy optimization insights if accuracy is low
        if let smartFeatures = dailyEntry.smartInsights {
            let averageAccuracy = smartManager.calculateAverageEnergyAccuracy(smartFeatures)
            if averageAccuracy < 0.6 {
                let insights = smartManager.generateInsights(for: dailyEntry)
                for insight in insights where insight.insightType == .energyOptimization {
                    await notificationManager.notifyImportantInsight(insight)
                }
            }
        }
    }
    
    /// Configures evening reminder settings
    func configureEveningReminder(time: Date, enabled: Bool, message: String, for dailyEntry: DailyEntry) async {
        guard let smartManager = getSmartFeaturesManager() else { return }
        
        // Update smart features
        smartManager.configureEveningReminder(time: time, enabled: enabled, message: message, for: dailyEntry)
        
        // Update notification scheduling
        await notificationManager.updateEveningReminder(for: dailyEntry)
    }
    
    // MARK: - Analytics Integration
    
    /// Generates comprehensive analytics report combining all services
    func generateComprehensiveReport(for dailyEntry: DailyEntry) async -> ComprehensiveReport? {
        guard let smartManager = getSmartFeaturesManager() else { return nil }
        
        let smartReport = smartManager.generateAnalyticsReport(for: dailyEntry)
        let pendingNotifications = await notificationManager.getPendingNotifications()
        
        return ComprehensiveReport(
            smartAnalytics: smartReport,
            notificationStatus: NotificationStatus(
                permissionGranted: notificationManager.notificationPermissionGranted,
                pendingCount: pendingNotifications.count,
                eveningReminderScheduled: pendingNotifications.contains { $0.identifier == "evening_planning_reminder" }
            ),
            serviceHealth: ServiceHealth(
                smartFeaturesActive: smartManager != nil,
                notificationsActive: notificationManager.notificationPermissionGranted,
                allServicesReady: servicesReady
            )
        )
    }
    
    // MARK: - Service Health & Debugging
    
    /// Performs service health check
    func performHealthCheck() -> ServiceHealthReport {
        return ServiceHealthReport(
            isInitialized: isInitialized,
            servicesReady: servicesReady,
            smartFeaturesManagerReady: smartFeaturesManager != nil,
            notificationPermissionGranted: notificationManager.notificationPermissionGranted,
            timestamp: Date()
        )
    }
    
    /// Resets all services (useful for testing or troubleshooting)
    func resetServices() async {
        // Cancel all notifications
        notificationManager.cancelAllNotifications()
        
        // Reset initialization state
        isInitialized = false
        servicesReady = false
        smartFeaturesManager = nil
        
        print("🔄 Services reset completed")
    }
}

// MARK: - Supporting Types

struct ComprehensiveReport {
    let smartAnalytics: SmartAnalyticsReport
    let notificationStatus: NotificationStatus
    let serviceHealth: ServiceHealth
    
    var summary: String {
        """
        📊 Comprehensive Service Report
        
        \(smartAnalytics.summary)
        
        🔔 Notifications: \(notificationStatus.permissionGranted ? "✅ Active" : "❌ Disabled")
        📋 Pending: \(notificationStatus.pendingCount) notifications
        🌙 Evening Reminder: \(notificationStatus.eveningReminderScheduled ? "✅ Scheduled" : "❌ Not scheduled")
        
        🔧 Service Health: \(serviceHealth.allServicesReady ? "✅ All Ready" : "⚠️ Issues Detected")
        """
    }
}

struct NotificationStatus {
    let permissionGranted: Bool
    let pendingCount: Int
    let eveningReminderScheduled: Bool
}

struct ServiceHealth {
    let smartFeaturesActive: Bool
    let notificationsActive: Bool
    let allServicesReady: Bool
}

struct ServiceHealthReport {
    let isInitialized: Bool
    let servicesReady: Bool
    let smartFeaturesManagerReady: Bool
    let notificationPermissionGranted: Bool
    let timestamp: Date
    
    var status: String {
        if isInitialized && servicesReady && smartFeaturesManagerReady && notificationPermissionGranted {
            return "✅ All Systems Ready"
        } else if isInitialized && smartFeaturesManagerReady {
            return "⚠️ Partial - Notifications Need Permission"
        } else if isInitialized {
            return "⚠️ Partial - Smart Features Issue"
        } else {
            return "❌ Not Initialized"
        }
    }
    
    var details: String {
        """
        Service Health Report (\(timestamp.formatted(.dateTime)))
        
        Initialization: \(isInitialized ? "✅" : "❌")
        Services Ready: \(servicesReady ? "✅" : "❌")
        Smart Features: \(smartFeaturesManagerReady ? "✅" : "❌")
        Notifications: \(notificationPermissionGranted ? "✅" : "❌")
        
        Status: \(status)
        """
    }
} 