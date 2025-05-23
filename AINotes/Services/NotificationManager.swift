//
//  NotificationManager.swift
//  Brain Dump
//
//  Created by AI Assistant on 5/23/25.
//

import Foundation
import UserNotifications
import SwiftData

@Observable
class NotificationManager {
    static let shared = NotificationManager()
    
    private let notificationCenter = UNUserNotificationCenter.current()
    
    // Permission state
    var notificationPermissionGranted: Bool = false
    var notificationSettings: UNNotificationSettings?
    
    private init() {
        Task {
            await checkNotificationPermission()
        }
    }
    
    // MARK: - Permission Management
    
    /// Requests notification permissions from the user
    @MainActor
    func requestNotificationPermission() async -> Bool {
        do {
            let granted = try await notificationCenter.requestAuthorization(options: [.alert, .sound, .badge])
            notificationPermissionGranted = granted
            
            if granted {
                await updateNotificationSettings()
            }
            
            return granted
        } catch {
            print("Failed to request notification permission: \(error)")
            return false
        }
    }
    
    /// Checks current notification permission status
    func checkNotificationPermission() async {
        let settings = await notificationCenter.notificationSettings()
        
        await MainActor.run {
            self.notificationSettings = settings
            self.notificationPermissionGranted = settings.authorizationStatus == .authorized
        }
    }
    
    /// Updates notification settings after permission changes
    @MainActor
    private func updateNotificationSettings() async {
        let settings = await notificationCenter.notificationSettings()
        self.notificationSettings = settings
    }
    
    // MARK: - Evening Reminder Management
    
    /// Schedules evening planning reminder based on SmartFeatures configuration
    func scheduleEveningReminder(for dailyEntry: DailyEntry) async {
        guard notificationPermissionGranted,
              let smartFeatures = dailyEntry.smartInsights,
              smartFeatures.reminderEnabled else { return }
        
        // Cancel existing evening reminders to avoid duplicates
        await cancelEveningReminders()
        
        let content = UNMutableNotificationContent()
        content.title = "🌙 Evening Planning Time"
        content.body = smartFeatures.reminderMessage
        content.sound = .default
        content.categoryIdentifier = "EVENING_PLANNING"
        
        // Create trigger from reminder time
        let reminderTime = smartFeatures.eveningReminderTime
        let components = Calendar.current.dateComponents([.hour, .minute], from: reminderTime)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        
        let request = UNNotificationRequest(
            identifier: "evening_planning_reminder",
            content: content,
            trigger: trigger
        )
        
        do {
            try await notificationCenter.add(request)
            print("✅ Evening reminder scheduled for \(components.hour ?? 20):\(String(format: "%02d", components.minute ?? 0))")
        } catch {
            print("❌ Failed to schedule evening reminder: \(error)")
        }
    }
    
    /// Cancels all evening planning reminders
    func cancelEveningReminders() async {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: ["evening_planning_reminder"])
    }
    
    /// Updates evening reminder when settings change
    func updateEveningReminder(for dailyEntry: DailyEntry) async {
        guard let smartFeatures = dailyEntry.smartInsights else { return }
        
        if smartFeatures.reminderEnabled {
            await scheduleEveningReminder(for: dailyEntry)
        } else {
            await cancelEveningReminders()
        }
    }
    
    // MARK: - Task Completion Notifications
    
    /// Sends a notification when task completion milestones are reached
    func notifyTaskMilestone(completedCount: Int, totalCount: Int, streakCount: Int) async {
        guard notificationPermissionGranted else { return }
        
        var title = ""
        var body = ""
        var shouldNotify = false
        
        let completionRate = Double(completedCount) / Double(totalCount)
        
        // Milestone notifications
        if completedCount == totalCount && totalCount > 0 {
            title = "🎉 Perfect Day!"
            body = "All \(totalCount) tasks completed! You're crushing it!"
            shouldNotify = true
        } else if completionRate >= 0.8 && completedCount >= 3 {
            title = "🔥 Amazing Progress!"
            body = "\(completedCount)/\(totalCount) tasks done! You're on fire!"
            shouldNotify = true
        } else if streakCount >= 7 {
            title = "🚀 Week Streak!"
            body = "\(streakCount) days of consistent productivity! Incredible!"
            shouldNotify = true
        }
        
        if shouldNotify {
            let content = UNMutableNotificationContent()
            content.title = title
            content.body = body
            content.sound = .default
            content.categoryIdentifier = "TASK_MILESTONE"
            
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
            let request = UNNotificationRequest(
                identifier: "task_milestone_\(Date().timeIntervalSince1970)",
                content: content,
                trigger: trigger
            )
            
            do {
                try await notificationCenter.add(request)
            } catch {
                print("Failed to send milestone notification: \(error)")
            }
        }
    }
    
    // MARK: - Smart Insight Notifications
    
    /// Sends notification when important insights are generated
    func notifyImportantInsight(_ insight: UserInsight) async {
        guard notificationPermissionGranted,
              insight.confidence >= 0.8,
              insight.actionable else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "💡 Smart Insight"
        content.body = insight.insightText
        content.sound = .default
        content.categoryIdentifier = "SMART_INSIGHT"
        content.userInfo = [
            "insightId": insight.dateGenerated.timeIntervalSince1970,
            "insightType": insight.insightType.rawValue
        ]
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        let request = UNNotificationRequest(
            identifier: "insight_\(insight.dateGenerated.timeIntervalSince1970)",
            content: content,
            trigger: trigger
        )
        
        do {
            try await notificationCenter.add(request)
        } catch {
            print("Failed to send insight notification: \(error)")
        }
    }
    
    // MARK: - Morning Motivation Notifications
    
    /// Schedules motivational morning notification based on yesterday's progress
    func scheduleMorningMotivation(basedOn dailyEntry: DailyEntry, for tomorrowDate: Date) async {
        guard notificationPermissionGranted else { return }
        
        let completionRate = TaskQueueManager.calculateCompletionRate(for: dailyEntry)
        let streakCount = dailyEntry.smartInsights?.longestStreak ?? 0
        
        var motivationMessage = ""
        
        if completionRate >= 0.8 {
            motivationMessage = "Yesterday was amazing! Ready to build on that momentum? 🔥"
        } else if completionRate >= 0.5 {
            motivationMessage = "Good progress yesterday! Today's a new opportunity to shine ✨"
        } else if streakCount > 0 {
            motivationMessage = "Every day is a chance to restart. You've got this! 💪"
        } else {
            motivationMessage = "Fresh day, fresh start! What will you accomplish today? 🌅"
        }
        
        let content = UNMutableNotificationContent()
        content.title = "☀️ Good Morning!"
        content.body = motivationMessage
        content.sound = .default
        content.categoryIdentifier = "MORNING_MOTIVATION"
        
        // Schedule for 8 AM tomorrow
        var components = Calendar.current.dateComponents([.year, .month, .day], from: tomorrowDate)
        components.hour = 8
        components.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(
            identifier: "morning_motivation_\(tomorrowDate.timeIntervalSince1970)",
            content: content,
            trigger: trigger
        )
        
        do {
            try await notificationCenter.add(request)
        } catch {
            print("Failed to schedule morning motivation: \(error)")
        }
    }
    
    // MARK: - Utility Methods
    
    /// Gets all pending notifications for debugging
    func getPendingNotifications() async -> [UNNotificationRequest] {
        return await notificationCenter.pendingNotificationRequests()
    }
    
    /// Cancels all notifications
    func cancelAllNotifications() {
        notificationCenter.removeAllPendingNotificationRequests()
        notificationCenter.removeAllDeliveredNotifications()
    }
    
    /// Configures notification categories for interaction
    func setupNotificationCategories() {
        let planNowAction = UNNotificationAction(
            identifier: "PLAN_NOW",
            title: "Plan Now",
            options: [.foreground]
        )
        
        let remindLaterAction = UNNotificationAction(
            identifier: "REMIND_LATER",
            title: "Remind Me in 1 Hour",
            options: []
        )
        
        let eveningPlanningCategory = UNNotificationCategory(
            identifier: "EVENING_PLANNING",
            actions: [planNowAction, remindLaterAction],
            intentIdentifiers: [],
            options: []
        )
        
        let taskMilestoneCategory = UNNotificationCategory(
            identifier: "TASK_MILESTONE",
            actions: [],
            intentIdentifiers: [],
            options: []
        )
        
        let smartInsightCategory = UNNotificationCategory(
            identifier: "SMART_INSIGHT",
            actions: [],
            intentIdentifiers: [],
            options: []
        )
        
        let morningMotivationCategory = UNNotificationCategory(
            identifier: "MORNING_MOTIVATION",
            actions: [],
            intentIdentifiers: [],
            options: []
        )
        
        notificationCenter.setNotificationCategories([
            eveningPlanningCategory,
            taskMilestoneCategory,
            smartInsightCategory,
            morningMotivationCategory
        ])
    }
}

// MARK: - Integration with SmartFeaturesManager

extension NotificationManager {
    
    /// Integrates with SmartFeaturesManager to handle reminder configuration
    func configureWithSmartFeatures(_ smartFeaturesManager: SmartFeaturesService, for dailyEntry: DailyEntry) async {
        // Schedule evening reminder if enabled
        if smartFeaturesManager.shouldShowEveningReminder(for: dailyEntry) {
            await scheduleEveningReminder(for: dailyEntry)
        }
        
        // Generate insights and notify if important
        let insights = smartFeaturesManager.generateInsights(for: dailyEntry)
        for insight in insights where insight.confidence >= 0.8 && insight.actionable {
            await notifyImportantInsight(insight)
        }
        
        // Schedule tomorrow's morning motivation
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: dailyEntry.date) ?? Date()
        await scheduleMorningMotivation(basedOn: dailyEntry, for: tomorrow)
    }
} 