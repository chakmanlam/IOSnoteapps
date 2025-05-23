//
//  BrainDumpApp.swift
//  Brain Dump
//
//  Created by Chak Man Lam on 5/22/25.
//

import SwiftUI
import SwiftData

@main
struct BrainDumpApp: App {
    var body: some Scene {
        WindowGroup {
            MainAppView()
                .preferredColorScheme(.light)
        }
        .modelContainer(for: [
            DailyEntry.self, 
            ScheduleEntry.self, 
            TaskItem.self, 
            Habit.self,
            IvyLeeTask.self,
            SomedayMaybeTask.self,
            SmartFeatures.self,
            UserInsight.self
        ])
    }
}
