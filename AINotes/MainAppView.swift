import SwiftUI
import UIKit

// Main App View with Bottom Tab Navigation
struct MainAppView: View {
    @State private var selectedTab = 0
    @Environment(\.modelContext) private var modelContext
    @State private var dailyEntryViewModel: DailyEntryViewModel
    @State private var taskViewModel = IvyLeeTaskViewModel()
    
    init() {
        self._dailyEntryViewModel = State(wrappedValue: DailyEntryViewModel(modelContext: nil))
        
        // Customize tab bar appearance
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(Color(red: 0.98, green: 0.97, blue: 0.95))
        appearance.shadowColor = UIColor.black.withAlphaComponent(0.1)
        
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Today Tab (Home)
            NavigationStack {
                EnhancedHomeView(selectedTab: $selectedTab)
                    .navigationBarHidden(true)
            }
            .tabItem {
                Image(systemName: selectedTab == 0 ? "house.fill" : "house")
                Text("Today")
            }
            .tag(0)
            
            // Plan Tab (Evening Brain Dump)
            NavigationStack {
                EveningBrainDumpView()
            }
            .tabItem {
                Image(systemName: selectedTab == 1 ? "moon.stars.fill" : "moon.stars")
                Text("Plan")
            }
            .tag(1)
            
            // Execute Tab (Morning Brain Dump)
            NavigationStack {
                MorningBrainDumpView()
            }
            .tabItem {
                Image(systemName: selectedTab == 2 ? "sun.max.fill" : "sun.max")
                Text("Execute")
            }
            .tag(2)
            
            // Tasks Tab (Task Management)
            NavigationStack {
                TaskBrainDumpView()
            }
            .tabItem {
                Image(systemName: selectedTab == 3 ? "brain.head.profile.fill" : "brain.head.profile")
                Text("Tasks")
            }
            .tag(3)
            
            // Settings Tab
            NavigationStack {
                EnhancedSettingsView()
            }
            .tabItem {
                Image(systemName: selectedTab == 4 ? "gearshape.fill" : "gearshape")
                Text("Settings")
            }
            .tag(4)
        }
        .accentColor(.blue)
        .overlay(alignment: .topTrailing) {
            // Daily Progress Indicator
            dailyProgressIndicator
                .padding(.top, 50)
                .padding(.trailing, 20)
        }
        .onAppear {
            setupViewModels()
        }
    }
    
    // MARK: - Daily Progress Indicator
    private var dailyProgressIndicator: some View {
        HStack(spacing: 6) {
            // Morning Ritual
            Circle()
                .fill(dailyEntryViewModel.currentEntry?.morningRitualCompleted == true ? Color.green : Color.gray.opacity(0.3))
                .frame(width: 8, height: 8)
            
            // Task Ritual  
            Circle()
                .fill(dailyEntryViewModel.currentEntry?.taskRitualCompleted == true ? Color.blue : Color.gray.opacity(0.3))
                .frame(width: 8, height: 8)
            
            // Evening Ritual
            Circle()
                .fill(dailyEntryViewModel.currentEntry?.eveningRitualCompleted == true ? Color.purple : Color.gray.opacity(0.3))
                .frame(width: 8, height: 8)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.white.opacity(0.9))
        .clipShape(Capsule())
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        .accessibilityLabel("Daily ritual progress: \(dailyEntryViewModel.completedRitualsCount) of 3 completed")
    }
    
    private func setupViewModels() {
        if dailyEntryViewModel.modelContext == nil {
            dailyEntryViewModel.setModelContext(modelContext)
        }
        taskViewModel.setModelContext(modelContext)
        taskViewModel.setDailyEntryViewModel(dailyEntryViewModel)
    }
}

#Preview {
    MainAppView()
        .modelContainer(for: [DailyEntry.self, IvyLeeTask.self, SomedayMaybeTask.self, SmartFeatures.self, UserInsight.self], inMemory: true)
} 