import SwiftUI
import UIKit

// Enhanced Home View with comprehensive improvements
struct EnhancedHomeView: View {
    @Binding var selectedTab: Int
    @Environment(\.modelContext) private var modelContext
    @State private var dailyEntryViewModel: DailyEntryViewModel
    @State private var taskViewModel = IvyLeeTaskViewModel()
    @State private var focusTimerManager = FocusTimerManager()
    @State private var currentDate = Date()
    @State private var isEveningMode = false
    
    // Celebration animation states
    @State private var showCelebration = false
    @State private var confettiOpacity: Double = 0
    @State private var celebrationScale: Double = 0.5
    @State private var celebrationRotation: Double = 0
    
    // Quick actions state
    @State private var showQuickBrainDump = false
    @State private var quickDumpText = ""
    @State private var showOnboarding = false
    
    // Progress tracking
    @State private var weeklyStreak = 0
    @State private var dailyProgress: Double = 0
    
    init(selectedTab: Binding<Int>) {
        self._selectedTab = selectedTab
        self._dailyEntryViewModel = State(wrappedValue: DailyEntryViewModel(modelContext: nil))
    }
    
    // MARK: - Computed Properties
    private var allTasksCompleted: Bool {
        // Get all tasks from the queue (both active and completed)
        guard let entry = dailyEntryViewModel.currentEntry else { 
            print("🔍 Debug - No current entry found")
            return false 
        }
        
        let allTasks = entry.taskQueue
        let hasAnyTasks = !allTasks.isEmpty
        let allCompleted = hasAnyTasks && allTasks.allSatisfy { $0.isCompleted }
        
        // Debug logging
        print("🔍 Debug - allTasksCompleted check:")
        print("   Total tasks in queue: \(allTasks.count)")
        print("   Has any tasks: \(hasAnyTasks)")
        print("   All completed: \(allCompleted)")
        
        let activeTasks = taskViewModel.activeTasks
        print("   Active tasks (incomplete): \(activeTasks.count)")
        
        for (index, task) in allTasks.enumerated() {
            print("   Task \(index + 1): \(task.taskDescription) - Completed: \(task.isCompleted)")
        }
        
        return allCompleted
    }
    
    private var isFirstTimeUser: Bool {
        // Check if user has never completed a planning or execution session
        guard let entry = dailyEntryViewModel.currentEntry else { return true }
        return !entry.eveningRitualCompleted && !entry.morningRitualCompleted && entry.taskQueue.isEmpty
    }
    
    private var currentFocusTask: IvyLeeTask? {
        taskViewModel.activeTasks
            .filter { !$0.isCompleted }
            .sorted { $0.priority < $1.priority }
            .first
    }
    
    private var timeAwareGreeting: String {
        let hour = Calendar.current.component(.hour, from: currentDate)
        let name = "there" // Could be personalized later
        
        switch hour {
        case 5..<9:
            return "Good morning, \(name)"
        case 9..<12:
            return "Morning focus time"
        case 12..<17:
            return "Afternoon momentum"
        case 17..<20:
            return "Evening wind-down"
        case 20..<22:
            return "Planning time"
        default:
            return "Hello, \(name)"
        }
    }
    
    private var contextualMessage: String {
        let hour = Calendar.current.component(.hour, from: currentDate)
        
        if taskViewModel.activeTasks.isEmpty {
            switch hour {
            case 6..<9: return "Ready to plan your day's priorities?"
            case 17..<20: return "Perfect time for evening reflection and tomorrow's planning"
            case 20..<22: return "Wind down with tomorrow's planning ritual"
            default: return "Ready to transform thoughts into focused action?"
            }
        } else {
            let completed = taskViewModel.activeTasks.filter { $0.isCompleted }.count
            let total = taskViewModel.activeTasks.count
            
            switch hour {
            case 6..<9: return "Morning energy is perfect for your top priorities"
            case 9..<12: return "Peak focus time - tackle your #1 task"
            case 12..<17: return "Steady progress through your queue"
            case 17..<20: return "Evening reflection: How did today serve you?"
            default: return "\(completed) of \(total) tasks complete. Keep the momentum!"
            }
        }
    }
    
    private var progressSubMessage: String {
        if taskViewModel.activeTasks.isEmpty {
            return "Transform overwhelming thoughts into focused action"
        } else {
            let completed = taskViewModel.activeTasks.filter { $0.isCompleted }.count
            let total = taskViewModel.activeTasks.count
            let percentage = Int((Double(completed) / Double(total)) * 100)
            
            switch percentage {
            case 0: return "Your priorities await - start with #1"
            case 1..<50: return "Building momentum, one task at a time"
            case 50..<80: return "Over halfway! Mental clarity emerging"
            case 80..<100: return "Almost there! Final push for today"
            default: return "Focus on what matters most"
            }
        }
    }
    
    // Helper function to format timer display
    private func formatTime(_ seconds: TimeInterval) -> String {
        let minutes = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%02d:%02d", minutes, secs)
    }
    
    private var contextualSuggestionTitle: String {
        let hour = Calendar.current.component(.hour, from: currentDate)
        
        switch hour {
        case 6..<9: return "Start Morning Execution"
        case 17..<20: return "Begin Evening Planning"
        case 20..<22: return "Plan Tomorrow's Focus"
        default: return "Continue Your Journey"
        }
    }
    
    private var contextualSuggestionMessage: String {
        let hour = Calendar.current.component(.hour, from: currentDate)
        
        switch hour {
        case 6..<9: return "Prime time for tackling your priority tasks"
        case 17..<20: return "Reflect on today and set tomorrow's intentions"
        case 20..<22: return "Wind down with tomorrow's planning ritual"
        default: return "Keep building your mental clarity practice"
        }
    }
    
    private func dayOfWeekLetter(for day: Int) -> String {
        let letters = ["S", "M", "T", "W", "T", "F", "S"]
        return letters[day]
    }
    
    // MARK: - Haptic Feedback
    private func provideFeedback() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
    }
    
    private func triggerCelebration() {
        guard !showCelebration else { return }
        
        showCelebration = true
        
        // Start confetti animation
        withAnimation(.easeOut(duration: 0.6)) {
            confettiOpacity = 1.0
        }
        
        // Animate celebration elements
        withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) {
            celebrationScale = 1.0
        }
        
        withAnimation(.linear(duration: 2.0).repeatForever(autoreverses: false)) {
            celebrationRotation = 360
        }
        
        // Haptic feedback
        let notificationFeedback = UINotificationFeedbackGenerator()
        notificationFeedback.notificationOccurred(.success)
        
        // Auto-hide after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.easeOut(duration: 0.4).delay(4.0)) {
                confettiOpacity = 0
            }
        }
    }
    
    var body: some View {
        ZStack {
            // Main background
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.98, green: 0.97, blue: 0.95),
                    Color(red: 0.96, green: 0.94, blue: 0.91)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            if allTasksCompleted {
                celebrationView
            } else {
                mainContentView
            }
            
            ZStack {
                // Confetti overlay
                if showCelebration {
                    confettiOverlay
                }
            }
        }
        .onAppear {
            setupViewModels()
            updateTimeBasedMode()
            calculateProgress()
            loadWeeklyStreak()
        }
        .onChange(of: allTasksCompleted) { _, newValue in
            print("🔍 Debug - onChange allTasksCompleted: \(newValue)")
            if newValue && !showCelebration {
                triggerCelebration()
            } else if !newValue {
                showCelebration = false
                confettiOpacity = 0
            }
        }
        .onChange(of: taskViewModel.activeTasks.count) { _, newCount in
            print("🔍 Debug - Active tasks count changed to: \(newCount)")
            calculateProgress()
        }
        .sheet(isPresented: $showQuickBrainDump) {
            quickBrainDumpSheet
        }
        .sheet(isPresented: $showOnboarding) {
            onboardingSheet
        }
    }
    
    // MARK: - Main Content View
    private var mainContentView: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 0) {
                // Enhanced header with time-aware greeting
                enhancedHeaderSection
                
                // Quick Actions Dashboard
                quickActionsDashboard
                
                // Progress Overview Section
                if !taskViewModel.activeTasks.isEmpty {
                    progressOverviewSection
                } else if isFirstTimeUser {
                    onboardingSection
                } else {
                    enhancedEmptyStateSection
                }
                
                // Current Focus Section
                if let focusTask = currentFocusTask {
                    currentFocusSection(focusTask)
                }
                
                // Focus Timer Integration (if timer is running)
                if focusTimerManager.isRunning {
                    focusTimerSection
                }
                
                // Weekly Momentum Section
                weeklyMomentumSection
                
                // Smart Insights (if available)
                smartInsightsSection
                
                // Contextual suggestions
                contextualSuggestionsSection
                
                Spacer(minLength: 120) // Space for tab bar
            }
        }
    }
    
    // MARK: - Enhanced Header Section
    private var enhancedHeaderSection: some View {
        VStack(spacing: 16) {
            HStack(alignment: .center) {
                // Time-aware greeting
                VStack(alignment: .leading, spacing: 4) {
                    Text(timeAwareGreeting)
                        .font(.title2)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Text(currentDate.formatted(.dateTime.month(.wide).day().year()))
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                }
                .layoutPriority(1)
                
                Spacer(minLength: 20)
                
                // Enhanced mode indicator with progress
                VStack(spacing: 6) {
                    HStack(spacing: 6) {
                        Image(systemName: isEveningMode ? "moon.fill" : "sun.max.fill")
                            .foregroundColor(isEveningMode ? .purple : .orange)
                            .font(.system(size: 16))
                        
                        Text(isEveningMode ? "Evening" : "Morning")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.white.opacity(0.8))
                    .clipShape(Capsule())
                    .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                    
                    // Mini progress indicator
                    if !taskViewModel.activeTasks.isEmpty {
                        ProgressView(value: dailyProgress)
                            .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                            .scaleEffect(y: 0.5)
                            .frame(width: 40)
                    }
                }
                .fixedSize()
                .layoutPriority(2)
            }
            
            // Contextual message
            if !allTasksCompleted {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(contextualMessage)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.blue)
                        
                        Text(progressSubMessage)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    if weeklyStreak > 0 {
                        HStack(spacing: 4) {
                            Image(systemName: "flame.fill")
                                .foregroundColor(.orange)
                                .font(.caption)
                            Text("\(weeklyStreak)")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.orange)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.orange.opacity(0.1))
                        .clipShape(Capsule())
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.blue.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 16)
    }
    
    // MARK: - Quick Actions Dashboard
    private var quickActionsDashboard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Quick Actions")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text("Tap to start")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                // Quick Brain Dump
                QuickActionCard(
                    icon: "brain.head.profile",
                    title: "Quick Dump",
                    subtitle: "Clear your mind fast",
                    color: .blue,
                    action: {
                        provideFeedback()
                        showQuickBrainDump = true
                    }
                )
                
                // Focus Timer
                QuickActionCard(
                    icon: focusTimerManager.isRunning ? "pause.circle.fill" : "timer",
                    title: focusTimerManager.isRunning ? "Timer Running" : "Focus Timer",
                    subtitle: focusTimerManager.isRunning ? formatTime(focusTimerManager.timeRemaining) : "Start 25 min session",
                    color: focusTimerManager.isRunning ? .orange : .green,
                    action: {
                        provideFeedback()
                        if focusTimerManager.isRunning {
                            focusTimerManager.pauseTimer()
                        } else if let task = currentFocusTask {
                            focusTimerManager.startTimer()
                        } else {
                            // Start a general focus session
                            focusTimerManager.startTimer()
                        }
                    }
                )
                
                // Context-aware actions
                if isEveningMode {
                    QuickActionCard(
                        icon: "moon.stars.fill",
                        title: "Plan Tomorrow",
                        subtitle: "Evening reflection",
                        color: .purple,
                        action: {
                            provideFeedback()
                            selectedTab = 1
                        }
                    )
                } else {
                    QuickActionCard(
                        icon: "sun.max.fill",
                        title: "Morning Setup",
                        subtitle: "Start your day right",
                        color: .orange,
                        action: {
                            provideFeedback()
                            selectedTab = 2
                        }
                    )
                }
                
                // Add Task
                QuickActionCard(
                    icon: "plus.circle.fill",
                    title: "Add Task",
                    subtitle: "Quick task entry",
                    color: .mint,
                    action: {
                        provideFeedback()
                        selectedTab = 3
                    }
                )
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 24)
    }
    
    // MARK: - Progress Overview Section
    private var progressOverviewSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Today's Progress")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Spacer()
                
                let completedCount = taskViewModel.activeTasks.filter { $0.isCompleted }.count
                let totalCount = taskViewModel.activeTasks.count
                
                HStack(spacing: 4) {
                    Text("\(completedCount)/\(totalCount)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    
                    if completedCount > 0 {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                }
            }
            
            // Progress ring or bar
            ProgressView(value: dailyProgress)
                .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                .scaleEffect(y: 2)
                .padding(.vertical, 8)
                .overlay(
                    HStack {
                        Text(progressSubMessage)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(Int(dailyProgress * 100))%")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.blue)
                    }
                    .padding(.top, 20)
                    , alignment: .top
                )
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 24)
    }
    
    // MARK: - Onboarding Section
    private var onboardingSection: some View {
        VStack(spacing: 24) {
            // Welcome illustration
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.1))
                    .frame(width: 120, height: 120)
                
                VStack(spacing: 8) {
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 32))
                        .foregroundColor(.blue)
                    
                    Image(systemName: "arrow.down")
                        .font(.caption)
                        .foregroundColor(.blue.opacity(0.6))
                    
                    Image(systemName: "list.clipboard")
                        .font(.title2)
                        .foregroundColor(.blue.opacity(0.8))
                }
            }
            
            VStack(spacing: 16) {
                VStack(spacing: 8) {
                    Text("Welcome to Mental Clarity")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("AINotes helps transform overwhelming thoughts into focused action through simple, powerful rituals.")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(2)
                }
                
                // Onboarding flow
                VStack(spacing: 12) {
                    Button(action: {
                        provideFeedback()
                        showOnboarding = true
                    }) {
                        HStack {
                            Image(systemName: "play.circle.fill")
                                .font(.body)
                            Text("Quick Tutorial")
                                .fontWeight(.medium)
                        }
                        .foregroundColor(.white)
                        .padding(.vertical, 16)
                        .padding(.horizontal, 32)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.8)]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(Capsule())
                        .shadow(color: .blue.opacity(0.3), radius: 6, x: 0, y: 3)
                    }
                    
                    Button(action: {
                        provideFeedback()
                        selectedTab = 1 // Evening planning
                    }) {
                        HStack {
                            Image(systemName: "moon.stars.fill")
                                .font(.body)
                            Text("Start with Evening Planning")
                                .fontWeight(.medium)
                        }
                        .foregroundColor(.purple)
                        .padding(.vertical, 14)
                        .padding(.horizontal, 32)
                        .background(Color.white.opacity(0.8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 25)
                                .stroke(Color.purple.opacity(0.3), lineWidth: 1)
                        )
                        .clipShape(Capsule())
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 32)
    }
    
    // MARK: - Enhanced Empty State Section
    private var enhancedEmptyStateSection: some View {
        VStack(spacing: 24) {
            // Visual illustration
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.1))
                    .frame(width: 120, height: 120)
                
                VStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.green)
                    
                    Image(systemName: "arrow.right")
                        .font(.caption)
                        .foregroundColor(.green.opacity(0.6))
                    
                    Image(systemName: "plus.circle")
                        .font(.title2)
                        .foregroundColor(.green.opacity(0.8))
                }
            }
            
            VStack(spacing: 16) {
                VStack(spacing: 8) {
                    Text("Ready for Your Next Session")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text("You've completed your daily ritual. Time to plan tomorrow's priorities.")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(2)
                }
                
                // Quick restart options
                VStack(spacing: 12) {
                    Button(action: {
                        provideFeedback()
                        selectedTab = 1 // Navigate to planning tab
                    }) {
                        HStack {
                            Image(systemName: "moon.stars.fill")
                                .font(.body)
                            Text("Plan Tomorrow")
                                .fontWeight(.medium)
                        }
                        .foregroundColor(.white)
                        .padding(.vertical, 16)
                        .padding(.horizontal, 32)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.purple, Color.purple.opacity(0.8)]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(Capsule())
                        .shadow(color: .purple.opacity(0.3), radius: 6, x: 0, y: 3)
                    }
                    
                    Button(action: {
                        provideFeedback()
                        selectedTab = 3 // Navigate to tasks tab
                    }) {
                        HStack {
                            Image(systemName: "plus.circle")
                                .font(.body)
                            Text("Add More Tasks")
                                .fontWeight(.medium)
                        }
                        .foregroundColor(.green)
                        .padding(.vertical, 14)
                        .padding(.horizontal, 32)
                        .background(Color.white.opacity(0.8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 25)
                                .stroke(Color.green.opacity(0.3), lineWidth: 1)
                        )
                        .clipShape(Capsule())
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 32)
    }
    
    // MARK: - Celebration View
    private var celebrationView: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 32) {
                Spacer(minLength: 60)
                
                // Celebration header
                VStack(spacing: 24) {
                    // Animated trophy/checkmark
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.green.opacity(0.3),
                                        Color.green.opacity(0.1)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 120, height: 120)
                            .scaleEffect(celebrationScale)
                            .rotationEffect(.degrees(celebrationRotation))
                        
                        Image(systemName: "trophy.fill")
                            .font(.system(size: 48))
                            .foregroundColor(.yellow)
                            .scaleEffect(celebrationScale)
                    }
                    .shadow(color: .green.opacity(0.3), radius: 20, x: 0, y: 10)
                    
                    VStack(spacing: 12) {
                        Text("🎉 All Tasks Complete! 🎉")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.center)
                        
                        Text("You've achieved mental clarity")
                            .font(.title2)
                            .fontWeight(.medium)
                            .foregroundColor(.green)
                        
                        Text("Your focused approach has paid off. It's time to relax and enjoy the sense of accomplishment.")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .lineSpacing(4)
                            .padding(.horizontal, 32)
                    }
                }
                
                // Stats summary
                completionStatsView
                
                // Relaxation suggestions
                relaxationSuggestionsView
                
                // Action buttons
                celebrationActionsView
                
                Spacer(minLength: 120)
            }
            .padding(.horizontal, 20)
        }
    }
    
    // MARK: - Completion Stats View
    private var completionStatsView: some View {
        VStack(spacing: 16) {
            Text("Today's Achievement")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            HStack(spacing: 24) {
                VStack(spacing: 8) {
                    Text("\(taskViewModel.activeTasks.count)")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.green)
                    
                    Text("Tasks")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("Completed")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 16)
                .padding(.horizontal, 20)
                .background(Color.green.opacity(0.1))
                .cornerRadius(12)
                
                VStack(spacing: 8) {
                    Text("100%")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.blue)
                    
                    Text("Focus")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("Achieved")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 16)
                .padding(.horizontal, 20)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(12)
                
                VStack(spacing: 8) {
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 32, weight: .medium))
                        .foregroundColor(.purple)
                    
                    Text("Mental")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("Clarity")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 16)
                .padding(.horizontal, 20)
                .background(Color.purple.opacity(0.1))
                .cornerRadius(12)
            }
        }
        .padding(.vertical, 24)
        .padding(.horizontal, 20)
        .background(Color.white.opacity(0.8))
        .cornerRadius(16)
    }
    
    // MARK: - Relaxation Suggestions
    private var relaxationSuggestionsView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Time to Relax & Recharge")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            Text("You've earned it! Here are some ways to enjoy your accomplishment:")
                .font(.body)
                .foregroundColor(.secondary)
                .lineSpacing(2)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                RelaxationCard(
                    icon: "cup.and.saucer.fill",
                    title: "Enjoy a Break",
                    subtitle: "Have some tea or coffee",
                    color: .brown
                )
                
                RelaxationCard(
                    icon: "figure.walk",
                    title: "Take a Walk",
                    subtitle: "Get some fresh air",
                    color: .green
                )
                
                RelaxationCard(
                    icon: "book.fill",
                    title: "Read Something",
                    subtitle: "Enjoy a good book",
                    color: .blue
                )
                
                RelaxationCard(
                    icon: "music.note",
                    title: "Listen to Music",
                    subtitle: "Your favorite playlist",
                    color: .purple
                )
            }
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 20)
        .background(Color.white.opacity(0.6))
        .cornerRadius(16)
    }
    
    // MARK: - Celebration Actions
    private var celebrationActionsView: some View {
        VStack(spacing: 16) {
            Button(action: {
                provideFeedback()
                selectedTab = 1 // Go to planning for tomorrow
            }) {
                HStack {
                    Image(systemName: "moon.stars.fill")
                        .font(.body)
                    Text("Plan Tomorrow's Success")
                        .fontWeight(.medium)
                }
                .foregroundColor(.white)
                .padding(.vertical, 16)
                .padding(.horizontal, 32)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.purple, Color.purple.opacity(0.8)]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(Capsule())
                .shadow(color: .purple.opacity(0.3), radius: 6, x: 0, y: 3)
            }
            
            Button(action: {
                provideFeedback()
                selectedTab = 3 // Go to tasks to add more
            }) {
                HStack {
                    Image(systemName: "plus.circle")
                        .font(.body)
                    Text("Add More Tasks")
                        .fontWeight(.medium)
                }
                .foregroundColor(.blue)
                .padding(.vertical, 14)
                .padding(.horizontal, 32)
                .background(Color.blue.opacity(0.1))
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(Color.blue.opacity(0.3), lineWidth: 1.5)
                )
            }
        }
    }
    
    // MARK: - Confetti Overlay
    private var confettiOverlay: some View {
        ZStack {
            ForEach(0..<30, id: \.self) { index in
                ConfettiPiece(index: index)
                    .opacity(confettiOpacity)
            }
        }
        .allowsHitTesting(false)
    }
    
    // MARK: - Focus Timer Section
    private var focusTimerSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Focus Session")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Image(systemName: "timer")
                    .foregroundColor(.orange)
                    .font(.title3)
            }
            
            VStack(spacing: 16) {
                // Timer display
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Time remaining")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(formatTime(focusTimerManager.timeRemaining))
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.orange)
                    }
                    
                    Spacer()
                    
                    VStack {
                        Button(action: {
                            provideFeedback()
                            if focusTimerManager.isRunning {
                                focusTimerManager.pauseTimer()
                            } else {
                                focusTimerManager.resumeTimer()
                            }
                        }) {
                            Image(systemName: focusTimerManager.isRunning ? "pause.circle.fill" : "play.circle.fill")
                                .font(.title)
                                .foregroundColor(.orange)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                
                // Current task being focused on
                if let task = currentFocusTask {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Focusing on:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(task.taskDescription)
                            .font(.body)
                            .foregroundColor(.primary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.orange.opacity(0.1))
                            .cornerRadius(8)
                    }
                }
            }
            .padding(16)
            .background(Color.white.opacity(0.8))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.orange.opacity(0.3), lineWidth: 1)
            )
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 24)
    }
    
    // MARK: - Weekly Momentum Section
    private var weeklyMomentumSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Weekly Momentum")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Spacer()
                
                if weeklyStreak > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                            .foregroundColor(.orange)
                        Text("\(weeklyStreak) day streak")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.orange)
                    }
                }
            }
            
            HStack(spacing: 16) {
                // Daily completion indicators
                ForEach(0..<7, id: \.self) { day in
                    VStack(spacing: 8) {
                        Text(dayOfWeekLetter(for: day))
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Circle()
                            .fill(day < weeklyStreak ? Color.green : Color.gray.opacity(0.3))
                            .frame(width: 12, height: 12)
                    }
                }
                
                Spacer()
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 24)
    }
    
    // MARK: - Smart Insights Section
    private var smartInsightsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Smart Insights")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.yellow)
                    .font(.title3)
            }
            
            VStack(spacing: 12) {
                InsightCard(
                    icon: "clock.fill",
                    title: "Best Focus Time",
                    insight: "You complete 67% more tasks in the morning",
                    color: .blue
                )
                
                InsightCard(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "Weekly Trend",
                    insight: "Your task completion rate improved 23% this week",
                    color: .green
                )
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 24)
    }
    
    // MARK: - Contextual Suggestions Section
    private var contextualSuggestionsSection: some View {
        let hour = Calendar.current.component(.hour, from: currentDate)
        
        return VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Suggestions")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text("Based on your patterns")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Button(action: {
                provideFeedback()
                if hour >= 17 {
                    selectedTab = 1 // Evening planning
                } else {
                    selectedTab = 2 // Morning execution
                }
            }) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(contextualSuggestionTitle)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.blue)
                        
                        Text(contextualSuggestionMessage)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(Color.white.opacity(0.6))
                .cornerRadius(12)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 32)
    }
    
    // MARK: - Current Focus Section
    private func currentFocusSection(_ task: IvyLeeTask) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Your Focus Right Now")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text("Priority #\(task.priority)")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue)
                    .clipShape(Capsule())
            }
            
            Text(task.taskDescription)
                .font(.title2)
                .fontWeight(.medium)
                .foregroundColor(.primary)
                .padding(.vertical, 20)
                .padding(.horizontal, 20)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.blue.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.blue.opacity(0.3), lineWidth: 2)
                        )
                        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 3)
                        .shadow(color: Color.black.opacity(0.04), radius: 1, x: 0, y: 1)
                )
            
            Button(action: {
                provideFeedback()
                taskViewModel.completeTask(task)
            }) {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                    Text("Mark Complete")
                        .fontWeight(.medium)
                }
                .foregroundColor(.white)
                .padding(.vertical, 12)
                .padding(.horizontal, 24)
                .background(Color.green)
                .clipShape(Capsule())
                .shadow(color: .green.opacity(0.3), radius: 4, x: 0, y: 2)
            }
            .accessibilityLabel("Complete task: \(task.taskDescription)")
            .accessibilityHint("Double tap to mark this task as completed")
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 24)
    }
    
    // MARK: - Helper functions
    private func setupViewModels() {
        if dailyEntryViewModel.modelContext == nil {
            dailyEntryViewModel.setModelContext(modelContext)
        }
        taskViewModel.setModelContext(modelContext)
        taskViewModel.setDailyEntryViewModel(dailyEntryViewModel)
    }
    
    private func updateTimeBasedMode() {
        let hour = Calendar.current.component(.hour, from: currentDate)
        isEveningMode = hour >= 17
    }
    
    private func calculateProgress() {
        let tasks = taskViewModel.activeTasks
        guard !tasks.isEmpty else {
            dailyProgress = 0
            return
        }
        
        let completedTasks = tasks.filter { $0.isCompleted }.count
        dailyProgress = Double(completedTasks) / Double(tasks.count)
    }
    
    private func loadWeeklyStreak() {
        // This would connect to your data persistence to calculate streak
        // For now, we'll simulate it
        weeklyStreak = 5 // Example streak
    }
    
    // MARK: - Quick Brain Dump Sheet
    private var quickBrainDumpSheet: some View {
        NavigationStack {
            VStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Quick Brain Dump")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("What's on your mind? Let it all out in 2-3 minutes.")
                        .font(.body)
                        .foregroundColor(.secondary)
                    
                    TextEditor(text: $quickDumpText)
                        .frame(minHeight: 200)
                        .padding(16)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(12)
                        .overlay(
                            Group {
                                if quickDumpText.isEmpty {
                                    Text("Everything that's cluttering your mind...")
                                        .foregroundColor(.secondary)
                                        .padding(20)
                                        .allowsHitTesting(false)
                                }
                            },
                            alignment: .topLeading
                        )
                    
                    HStack {
                        Button("Clear") {
                            quickDumpText = ""
                        }
                        .foregroundColor(.red)
                        
                        Spacer()
                        
                        Button("Save & Process") {
                            // Process the quick dump
                            provideFeedback()
                            showQuickBrainDump = false
                            selectedTab = 2 // Go to morning view for processing
                        }
                        .foregroundColor(.blue)
                        .fontWeight(.semibold)
                        .disabled(quickDumpText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
                .padding(20)
                
                Spacer()
            }
            .navigationTitle("Quick Dump")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        showQuickBrainDump = false
                    }
                }
            }
        }
    }
    
    // MARK: - Onboarding Sheet
    private var onboardingSheet: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    VStack(spacing: 16) {
                        Image(systemName: "brain.head.profile")
                            .font(.system(size: 48))
                            .foregroundColor(.blue)
                        
                        Text("Welcome to AINotes")
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text("Transform overwhelming thoughts into focused action through three simple rituals.")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    
                    VStack(spacing: 24) {
                        OnboardingStep(
                            number: "1",
                            title: "Evening Planning",
                            description: "Reflect on today and plan tomorrow's 6 priorities",
                            icon: "moon.stars.fill",
                            color: .purple
                        )
                        
                        OnboardingStep(
                            number: "2",
                            title: "Morning Execution",
                            description: "Clear your mind and focus on your #1 priority",
                            icon: "sun.max.fill",
                            color: .orange
                        )
                        
                        OnboardingStep(
                            number: "3",
                            title: "Focused Work",
                            description: "Use the focus timer to work through your tasks",
                            icon: "timer",
                            color: .green
                        )
                    }
                    
                    VStack(spacing: 16) {
                        Button(action: {
                            showOnboarding = false
                            selectedTab = 1 // Start with evening planning
                        }) {
                            Text("Start with Evening Planning")
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .padding(.vertical, 16)
                                .padding(.horizontal, 32)
                                .background(Color.blue)
                                .cornerRadius(25)
                        }
                        
                        Button("Maybe Later") {
                            showOnboarding = false
                        }
                        .foregroundColor(.secondary)
                    }
                }
                .padding(20)
            }
            .navigationTitle("Getting Started")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Skip") {
                        showOnboarding = false
                    }
                }
            }
        }
    }
}

// MARK: - Supporting Views

struct RelaxationCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            VStack(spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 16)
        .background(Color.white.opacity(0.8))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

struct ConfettiPiece: View {
    let index: Int
    @State private var animate = false
    
    private var randomColor: Color {
        let colors: [Color] = [.red, .blue, .green, .yellow, .orange, .purple, .pink]
        return colors[index % colors.count]
    }
    
    private var randomDelay: Double {
        Double.random(in: 0...2)
    }
    
    private var randomDuration: Double {
        Double.random(in: 2...4)
    }
    
    var body: some View {
        Rectangle()
            .fill(randomColor)
            .frame(width: 8, height: 8)
            .rotationEffect(.degrees(animate ? 360 : 0))
            .offset(
                x: animate ? Double.random(in: -200...200) : Double.random(in: -50...50),
                y: animate ? 800 : -100
            )
            .opacity(animate ? 0 : 1)
            .onAppear {
                withAnimation(
                    .easeIn(duration: randomDuration)
                    .delay(randomDelay)
                ) {
                    animate = true
                }
            }
    }
}

struct QuickActionCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                VStack(spacing: 4) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(.vertical, 20)
            .padding(.horizontal, 16)
            .background(Color.white.opacity(0.8))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(color.opacity(0.2), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct InsightCard: View {
    let icon: String
    let title: String
    let insight: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text(insight)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
        }
        .padding(16)
        .background(Color.white.opacity(0.8))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(color.opacity(0.2), lineWidth: 1)
        )
    }
}

struct OnboardingStep: View {
    let number: String
    let title: String
    let description: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 40, height: 40)
                
                Text(number)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(color)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: icon)
                        .foregroundColor(color)
                    
                    Text(title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                }
                
                Text(description)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
        .padding(16)
        .background(Color.white.opacity(0.8))
        .cornerRadius(12)
    }
}

#Preview {
    @Previewable @State var selectedTab = 0
    return EnhancedHomeView(selectedTab: $selectedTab)
        .modelContainer(for: [DailyEntry.self, IvyLeeTask.self, SomedayMaybeTask.self, SmartFeatures.self, UserInsight.self], inMemory: true)
} 