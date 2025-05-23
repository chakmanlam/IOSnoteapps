//
//  DailyPlannerDetailView.swift
//  Brain Dump
//
//  Created by AI Assistant on 5/23/25.
//

import SwiftUI
import SwiftData

struct DailyPlannerDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: DailyEntryViewModel
    @State private var selectedDate = Date()
    @State private var currentQuoteIndex = 0
    @State private var completionProgress: Double = 0.0
    @State private var showSaveIndicator = false
    
    init() {
        // Initialize with nil, will be set in onAppear
        self._viewModel = State(wrappedValue: DailyEntryViewModel(modelContext: nil))
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Custom Menu Bar
                menuBar
                
                // Main Content
                ScrollView {
                    VStack(spacing: BrainDumpTheme.standardPadding) {
                        // Header with inspirational quote
                        headerSection
                        
                        // Main Brain Dump Sections
                        VStack(spacing: BrainDumpTheme.largePadding) {
                            // Morning Brain Dump
                            NavigationLink(destination: MorningBrainDumpView()) {
                                brainDumpCard(
                                    title: "Morning Brain Dump",
                                    subtitle: "Set your intention",
                                    icon: "sun.max",
                                    color: BrainDumpTheme.sageColor,
                                    isCustomIcon: false
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            // Task Brain Dump
                            NavigationLink(destination: TaskBrainDumpView()) {
                                brainDumpCard(
                                    title: "Task Brain Dump",
                                    subtitle: "Organize your priorities",
                                    icon: "brain.head.profile",
                                    color: BrainDumpTheme.accentColor,
                                    isCustomIcon: false
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            // Schedule Planner
                            NavigationLink(destination: SchedulePlannerView()) {
                                brainDumpCard(
                                    title: "Schedule Planner",
                                    subtitle: "Time-block your day",
                                    icon: "calendar",
                                    color: BrainDumpTheme.sageColor,
                                    isCustomIcon: false
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            // Evening Brain Dump
                            NavigationLink(destination: EveningBrainDumpView()) {
                                brainDumpCard(
                                    title: "Evening Brain Dump",
                                    subtitle: "Reflect and unwind",
                                    icon: "moon",
                                    color: BrainDumpTheme.actionColor,
                                    isCustomIcon: false
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        .padding(.horizontal, BrainDumpTheme.standardPadding)
                        .padding(.bottom, BrainDumpTheme.largePadding)
                    }
                }
                .background(BrainDumpTheme.backgroundColor)
            }
            .navigationBarHidden(true)
        }
        .onAppear {
            // Initialize the view model with the environment model context
            if viewModel.modelContext == nil {
                viewModel.setModelContext(modelContext)
            }
        }
    }
    
    // MARK: - Menu Bar
    private var menuBar: some View {
        HStack {
            // Left: Brain Dump Icon
            Image(systemName: "brain.head.profile")
                .font(.title2)
                .foregroundColor(BrainDumpTheme.accentColor)
            
            Spacer()
            
            // Center: Date (MM/DD/YY format)
            Text(selectedDate.formatted(.dateTime.month(.twoDigits).day(.twoDigits).year(.twoDigits)))
                .font(BrainDumpTheme.headlineFont)
                .foregroundColor(BrainDumpTheme.textColor)
                .fontWeight(.medium)
            
            Spacer()
            
            // Right: Day of Week (shortened)
            Text(selectedDate.formatted(.dateTime.weekday(.abbreviated)))
                .font(BrainDumpTheme.bodyFont)
                .foregroundColor(BrainDumpTheme.textColor)
                .fontWeight(.medium)
        }
        .padding(.horizontal, BrainDumpTheme.standardPadding)
        .padding(.vertical, BrainDumpTheme.smallPadding)
        .background(BrainDumpTheme.backgroundColor)
        .shadow(color: BrainDumpTheme.textColor.opacity(0.08), radius: 2, x: 0, y: 1)
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: BrainDumpTheme.standardPadding) {
            // Intentional vs Reactive messaging - Hero element
            VStack(spacing: BrainDumpTheme.smallPadding) {
                Text("Start Intentional, Not Reactive")
                    .font(BrainDumpTheme.titleFont)
                    .foregroundColor(BrainDumpTheme.actionColor)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                Text("Your mind is a thinking device, not a storage device")
                    .font(BrainDumpTheme.bodyFont)
                    .foregroundColor(BrainDumpTheme.textColor.opacity(0.8))
                    .italic()
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, BrainDumpTheme.smallPadding)
            }
            .padding(.vertical, BrainDumpTheme.standardPadding)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [
                        BrainDumpTheme.actionColor.opacity(0.1),
                        BrainDumpTheme.sageColor.opacity(0.1)
                    ]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(BrainDumpTheme.cornerRadius)
            
            // Date and greeting
            VStack(spacing: BrainDumpTheme.tinyPadding) {
                Text("Good Morning! ☀️")
                    .font(BrainDumpTheme.headlineFont)
                    .foregroundColor(BrainDumpTheme.textColor)
                    .fontWeight(.medium)
                
                Text(viewModel.todayDateString)
                    .font(BrainDumpTheme.captionFont)
                    .foregroundColor(BrainDumpTheme.textColor.opacity(0.7))
            }
        }
        .padding(.horizontal, BrainDumpTheme.standardPadding)
    }
    
    // MARK: - Brain Dump Card
    private func brainDumpCard(title: String, subtitle: String, icon: String, color: Color, isCustomIcon: Bool) -> some View {
        HStack(spacing: BrainDumpTheme.standardPadding) {
            // Icon
            if isCustomIcon {
                Image(icon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 40, height: 40)
                    .foregroundColor(color)
            } else {
                Image(systemName: icon)
                    .font(.title)
                    .foregroundColor(color)
                    .frame(width: 40, height: 40)
            }
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(BrainDumpTheme.headlineFont)
                    .foregroundColor(BrainDumpTheme.textColor)
                    .fontWeight(.medium)
                
                Text(subtitle)
                    .font(BrainDumpTheme.bodyFont)
                    .foregroundColor(BrainDumpTheme.textColor.opacity(0.7))
            }
            
            Spacer()
            
            // Arrow
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(BrainDumpTheme.textColor.opacity(0.4))
        }
        .padding(BrainDumpTheme.standardPadding)
        .background(BrainDumpTheme.surfaceColor)
        .cornerRadius(BrainDumpTheme.cornerRadius)
        .shadow(color: BrainDumpTheme.textColor.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

#Preview {
    DailyPlannerDetailView()
        .modelContainer(for: [DailyEntry.self, ScheduleEntry.self, TaskItem.self, Habit.self, IvyLeeTask.self, SomedayMaybeTask.self, SmartFeatures.self, UserInsight.self], inMemory: true)
} 