import SwiftUI

struct EveningBrainDumpView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var dailyEntryViewModel: DailyEntryViewModel
    @State private var taskViewModel = IvyLeeTaskViewModel()
    @State private var currentStep = 0
    @State private var isCompleted = false
    
    // Today's Reflection States
    @State private var dayHighlight = ""
    @State private var lessonsLearned = ""
    @State private var keyTakeaways = ""
    @State private var gratitudeNote = ""
    
    // Tomorrow's Planning States
    @State private var brainDumpText = ""
    @State private var selectedTasks: [String] = []
    @State private var prioritizedTasks: [PriorityTask] = []
    @State private var whyImportant = ""
    
    // Tomorrow's Intention States
    @State private var dailyIntention = ""
    @State private var energyLevel: EnergyLevel = .medium
    @State private var showCalendarPreview = false
    
    // UI States
    @State private var showTaskSelector = false
    @State private var extractedTasks: [String] = []
    
    private let steps = ["Reflect", "Plan", "Intend"]
    
    init() {
        self._dailyEntryViewModel = State(wrappedValue: DailyEntryViewModel(modelContext: nil))
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Consistent background
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.98, green: 0.97, blue: 0.95),
                        Color(red: 0.96, green: 0.94, blue: 0.91)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 0) {
                        // Header with progress
                        headerSection
                        
                        // Step content
                        if !isCompleted {
                            stepContentSection
                        } else {
                            completionSection
                        }
                        
                        // Navigation buttons
                        if !isCompleted {
                            navigationButtonsSection
                        }
                        
                        Spacer(minLength: 120)
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            setupViewModels()
            loadEveningData()
        }
        .sheet(isPresented: $showTaskSelector) {
            TaskSelectorSheet(
                brainDumpText: brainDumpText,
                extractedTasks: $extractedTasks,
                selectedTasks: $selectedTasks,
                onComplete: {
                    createPriorityTasks()
                    showTaskSelector = false
                }
            )
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 20) {
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                        .font(.title3)
                        .foregroundColor(.secondary)
                        .padding(8)
                        .background(Color.white.opacity(0.6))
                        .clipShape(Circle())
                }
                
                Spacer()
                
                VStack(spacing: 4) {
                    HStack(spacing: 8) {
                        Image(systemName: "moon.stars.fill")
                            .foregroundColor(.purple)
                            .font(.title3)
                        
                        Text("Evening Ritual")
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                    
                    Text("Transform today into tomorrow's clarity")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Time indicator
                Text(Date().formatted(.dateTime.hour().minute()))
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.white.opacity(0.6))
                    .clipShape(Capsule())
            }
            
            // Progress indicator
            HStack(spacing: 8) {
                ForEach(0..<steps.count, id: \.self) { index in
                    VStack(spacing: 8) {
                        ZStack {
                            Circle()
                                .fill(index <= currentStep ? Color.purple : Color.gray.opacity(0.3))
                                .frame(width: 32, height: 32)
                            
                            if index < currentStep {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.white)
                                    .font(.caption)
                                    .fontWeight(.bold)
                            } else if index == currentStep {
                                Text("\(index + 1)")
                                    .foregroundColor(.white)
                                    .font(.caption)
                                    .fontWeight(.bold)
                            } else {
                                Text("\(index + 1)")
                                    .foregroundColor(.gray)
                                    .font(.caption)
                                    .fontWeight(.medium)
                            }
                        }
                        
                        Text(steps[index])
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundColor(index <= currentStep ? .primary : .secondary)
                    }
                    
                    if index < steps.count - 1 {
                        Rectangle()
                            .fill(index < currentStep ? Color.purple : Color.gray.opacity(0.3))
                            .frame(height: 2)
                            .frame(maxWidth: .infinity)
                    }
                }
            }
            .padding(.horizontal, 20)
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 16)
    }
    
    // MARK: - Step Content Section
    private var stepContentSection: some View {
        VStack(spacing: 24) {
            switch currentStep {
            case 0:
                reflectionSection
            case 1:
                planningSection
            case 2:
                intentionSection
            default:
                EmptyView()
            }
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - Reflection Section (Step 1)
    private var reflectionSection: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Today's Reflection")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text("Take a moment to honor today's journey")
                    .font(.body)
                    .foregroundColor(.secondary)
            }
            
            VStack(spacing: 20) {
                ReflectionCard(
                    icon: "star.fill",
                    iconColor: .yellow,
                    title: "Highlight of the day",
                    placeholder: "What went well today? What made you proud?",
                    text: $dayHighlight
                )
                
                ReflectionCard(
                    icon: "lightbulb.fill",
                    iconColor: .orange,
                    title: "What I learned",
                    placeholder: "What insights did you discover today?",
                    text: $lessonsLearned
                )
                
                ReflectionCard(
                    icon: "bookmark.fill",
                    iconColor: .blue,
                    title: "What to remember",
                    placeholder: "Key takeaways or important moments to carry forward",
                    text: $keyTakeaways
                )
                
                ReflectionCard(
                    icon: "heart.fill",
                    iconColor: .pink,
                    title: "Gratitude note",
                    placeholder: "What are you grateful for today?",
                    text: $gratitudeNote
                )
            }
        }
    }
    
    // MARK: - Planning Section (Step 2)
    private var planningSection: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Tomorrow's Planning")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text("Transform your thoughts into 6 focused priorities")
                    .font(.body)
                    .foregroundColor(.secondary)
            }
            
            VStack(spacing: 20) {
                // Brain Dump Area
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "brain.head.profile")
                            .foregroundColor(.purple)
                            .font(.title3)
                        
                        Text("Brain Dump")
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                    
                    Text("Let it all out - write everything you need to do tomorrow")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    TextEditor(text: $brainDumpText)
                        .frame(minHeight: 120)
                        .padding(16)
                        .background(Color.white)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                        .overlay(
                            Group {
                                if brainDumpText.isEmpty {
                                    Text("Everything on your mind for tomorrow - tasks, meetings, calls, errands, ideas...")
                                        .foregroundColor(.secondary)
                                        .padding(20)
                                        .allowsHitTesting(false)
                                }
                            },
                            alignment: .topLeading
                        )
                }
                
                // Task Selection
                if !brainDumpText.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "list.number")
                                .foregroundColor(.blue)
                                .font(.title3)
                            
                            Text("Select Your 6 Priorities")
                                .font(.headline)
                                .fontWeight(.semibold)
                        }
                        
                        Button(action: {
                            extractTasksFromText()
                            showTaskSelector = true
                        }) {
                            HStack {
                                Image(systemName: "wand.and.rays")
                                    .font(.body)
                                Text("Extract & Select Tasks")
                                    .fontWeight(.medium)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                            }
                            .foregroundColor(.blue)
                            .padding(.vertical, 16)
                            .padding(.horizontal, 20)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                            )
                        }
                    }
                }
                
                // Priority Ranking
                if !prioritizedTasks.isEmpty {
                    PriorityRankingSection(tasks: $prioritizedTasks)
                    
                    // Why #1 is important
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "1.circle.fill")
                                .foregroundColor(.green)
                                .font(.title3)
                            
                            Text("Why is #1 most important?")
                                .font(.headline)
                                .fontWeight(.semibold)
                        }
                        
                        TextEditor(text: $whyImportant)
                            .frame(minHeight: 80)
                            .padding(16)
                            .background(Color.white)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.green.opacity(0.3), lineWidth: 1)
                            )
                            .overlay(
                                Group {
                                    if whyImportant.isEmpty {
                                        Text("This helps reinforce your commitment to your top priority...")
                                            .foregroundColor(.secondary)
                                            .padding(20)
                                            .allowsHitTesting(false)
                                    }
                                },
                                alignment: .topLeading
                            )
                    }
                }
            }
        }
    }
    
    // MARK: - Intention Section (Step 3)
    private var intentionSection: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Tomorrow's Intention")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text("Set your mindset and energy for tomorrow")
                    .font(.body)
                    .foregroundColor(.secondary)
            }
            
            VStack(spacing: 20) {
                // Daily Intention
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "target")
                            .foregroundColor(.mint)
                            .font(.title3)
                        
                        Text("Daily Intention")
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                    
                    HStack {
                        Text("Tomorrow I will...")
                            .font(.body)
                            .foregroundColor(.primary)
                        
                        TextField("focus on what matters most", text: $dailyIntention)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                }
                
                // Energy Level Prediction
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "bolt.fill")
                            .foregroundColor(.yellow)
                            .font(.title3)
                        
                        Text("Predicted Energy Level")
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                    
                    HStack(spacing: 12) {
                        ForEach(EnergyLevel.allCases, id: \.self) { level in
                            Button(action: { energyLevel = level }) {
                                VStack(spacing: 8) {
                                    Text(level.emoji)
                                        .font(.title2)
                                    
                                    Text(level.rawValue)
                                        .font(.caption)
                                        .fontWeight(.medium)
                                }
                                .foregroundColor(energyLevel == level ? .white : .primary)
                                .padding(.vertical, 12)
                                .padding(.horizontal, 16)
                                .background(energyLevel == level ? energyLevelColor(level) : Color.white)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(energyLevelColor(level).opacity(0.3), lineWidth: 1)
                                )
                            }
                        }
                    }
                }
                
                // Calendar Preview
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "calendar")
                            .foregroundColor(.blue)
                            .font(.title3)
                        
                        Text("Tomorrow's Schedule")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Spacer()
                        
                        Button(action: { showCalendarPreview.toggle() }) {
                            Text(showCalendarPreview ? "Hide" : "Preview")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                    }
                    
                    if showCalendarPreview {
                        CalendarPreviewCard()
                    }
                }
            }
        }
    }
    
    // MARK: - Completion Section
    private var completionSection: some View {
        VStack(spacing: 32) {
            VStack(spacing: 16) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 64))
                    .foregroundColor(.green)
                
                Text("Tonight's Ritual Complete")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text("Your mind is clear. Tomorrow is planned.\nRest well knowing you're prepared.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            
            VStack(spacing: 16) {
                Text("Tomorrow's Focus")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                if let topTask = prioritizedTasks.first {
                    HStack {
                        Text("#1")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.blue)
                            .clipShape(Capsule())
                        
                        Text(topTask.description)
                            .font(.body)
                            .fontWeight(.medium)
                        
                        Spacer()
                    }
                    .padding(.vertical, 16)
                    .padding(.horizontal, 20)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(12)
                }
            }
            
            Button(action: { dismiss() }) {
                HStack {
                    Image(systemName: "moon.zzz.fill")
                        .font(.body)
                    Text("Good Night")
                        .fontWeight(.medium)
                }
                .foregroundColor(.white)
                .padding(.vertical, 16)
                .padding(.horizontal, 32)
                .background(Color.purple)
                .clipShape(Capsule())
                .shadow(color: .purple.opacity(0.3), radius: 6, x: 0, y: 3)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 32)
    }
    
    // MARK: - Navigation Buttons
    private var navigationButtonsSection: some View {
        HStack(spacing: 16) {
            if currentStep > 0 {
                Button(action: { currentStep -= 1 }) {
                    HStack {
                        Image(systemName: "chevron.left")
                            .font(.body)
                        Text("Previous")
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.secondary)
                    .padding(.vertical, 16)
                    .padding(.horizontal, 24)
                    .background(Color.white)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
                }
            }
            
            Spacer()
            
            Button(action: { 
                if currentStep < steps.count - 1 {
                    currentStep += 1
                } else {
                    completeRitual()
                }
            }) {
                HStack {
                    Text(currentStep < steps.count - 1 ? "Continue" : "Complete Ritual")
                        .fontWeight(.medium)
                    
                    Image(systemName: currentStep < steps.count - 1 ? "chevron.right" : "checkmark")
                        .font(.body)
                }
                .foregroundColor(.white)
                .padding(.vertical, 16)
                .padding(.horizontal, 24)
                .background(canProceed ? Color.purple : Color.gray)
                .cornerRadius(12)
                .shadow(color: canProceed ? .purple.opacity(0.3) : .clear, radius: 4, x: 0, y: 2)
            }
            .disabled(!canProceed)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 24)
    }
    
    // MARK: - Helper Functions
    private var canProceed: Bool {
        switch currentStep {
        case 0:
            return !dayHighlight.isEmpty || !lessonsLearned.isEmpty || !keyTakeaways.isEmpty || !gratitudeNote.isEmpty
        case 1:
            return !prioritizedTasks.isEmpty
        case 2:
            return !dailyIntention.isEmpty
        default:
            return true
        }
    }
    
    private func extractTasksFromText() {
        // Simple task extraction - split by lines and filter meaningful content
        let lines = brainDumpText.components(separatedBy: .newlines)
        extractedTasks = lines
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty && $0.count > 3 }
    }
    
    private func createPriorityTasks() {
        prioritizedTasks = selectedTasks.enumerated().map { index, task in
            PriorityTask(id: UUID(), description: task, priority: index + 1)
        }
    }
    
    private func completeRitual() {
        isCompleted = true
        // Here you would save the ritual data to CoreData
        saveEveningRitual()
    }
    
    private func saveEveningRitual() {
        guard let entry = dailyEntryViewModel.currentEntry else { return }
        
        // Save reflection data
        entry.todayHighlight = dayHighlight
        entry.todayLearning = lessonsLearned
        entry.todayRemembrance = keyTakeaways
        entry.todayGratitude = gratitudeNote
        
        // Save tomorrow's planning data
        entry.tomorrowIntention = dailyIntention
        entry.tomorrowEnergyPrediction = energyLevel
        entry.taskBrainDumpText = brainDumpText
        
        // Convert prioritizedTasks to IvyLeeTask objects for tomorrow
        if !prioritizedTasks.isEmpty {
            // Get or create tomorrow's entry
            let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
            let tomorrowEntry = dailyEntryViewModel.getOrCreateEntry(for: tomorrow)
            
            // Clear existing tasks for tomorrow to avoid duplicates
            tomorrowEntry.taskQueue.removeAll { !$0.isCompleted }
            
            // Create IvyLeeTask objects from prioritized tasks
            for priorityTask in prioritizedTasks {
                let newTask = IvyLeeTask(
                    description: priorityTask.description,
                    priority: priorityTask.priority,
                    reasoning: priorityTask.priority == 1 ? "Tomorrow's most important task from evening planning" : "Evening planning priority #\(priorityTask.priority)"
                )
                newTask.dailyEntry = tomorrowEntry
                tomorrowEntry.taskQueue.append(newTask)
            }
        }
        
        // Mark evening ritual as completed
        dailyEntryViewModel.completeEveningRitual()
        
        // Save all changes
        dailyEntryViewModel.saveContext()
    }
    
    private func energyLevelColor(_ level: EnergyLevel) -> Color {
        switch level {
        case .low: return .orange
        case .medium: return .yellow
        case .high: return .green
        }
    }
    
    private func setupViewModels() {
        if dailyEntryViewModel.modelContext == nil {
            dailyEntryViewModel.setModelContext(modelContext)
        }
        taskViewModel.setModelContext(modelContext)
        taskViewModel.setDailyEntryViewModel(dailyEntryViewModel)
    }
    
    private func loadEveningData() {
        if let entry = dailyEntryViewModel.currentEntry {
            dayHighlight = entry.todayHighlight
            lessonsLearned = entry.todayLearning
            keyTakeaways = entry.todayRemembrance
            gratitudeNote = entry.todayGratitude
            dailyIntention = entry.tomorrowIntention
            energyLevel = entry.tomorrowEnergyPrediction
            brainDumpText = entry.taskBrainDumpText
        }
    }
}

// MARK: - Supporting Views

struct ReflectionCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    let placeholder: String
    @Binding var text: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(iconColor)
                    .font(.title3)
                
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            
            TextEditor(text: $text)
                .frame(minHeight: 80)
                .padding(16)
                .background(Color.white)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
                .overlay(
                    Group {
                        if text.isEmpty {
                            Text(placeholder)
                                .foregroundColor(.secondary)
                                .padding(20)
                                .allowsHitTesting(false)
                        }
                    },
                    alignment: .topLeading
                )
        }
    }
}

struct PriorityRankingSection: View {
    @Binding var tasks: [PriorityTask]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "arrow.up.arrow.down")
                    .foregroundColor(.green)
                    .font(.title3)
                
                Text("Drag to Prioritize")
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            
            LazyVStack(spacing: 8) {
                ForEach(tasks) { task in
                    PriorityTaskRow(task: task)
                }
                .onMove(perform: moveTask)
            }
        }
    }
    
    private func moveTask(from source: IndexSet, to destination: Int) {
        tasks.move(fromOffsets: source, toOffset: destination)
        // Update priorities after reordering
        for (index, _) in tasks.enumerated() {
            tasks[index].priority = index + 1
        }
    }
}

struct PriorityTaskRow: View {
    let task: PriorityTask
    
    var body: some View {
        HStack(spacing: 12) {
            Text("#\(task.priority)")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(priorityColor)
                .clipShape(Capsule())
            
            Text(task.description)
                .font(.body)
                .lineLimit(2)
            
            Spacer()
            
            Image(systemName: "line.3.horizontal")
                .foregroundColor(.secondary)
                .font(.caption)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(Color.white)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
        )
    }
    
    private var priorityColor: Color {
        switch task.priority {
        case 1: return .green
        case 2: return .blue
        case 3: return .orange
        default: return .gray
        }
    }
}

struct CalendarPreviewCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Tomorrow's meetings will appear here")
                .font(.caption)
                .foregroundColor(.secondary)
            
            // Mock calendar events
            VStack(spacing: 8) {
                CalendarEventRow(time: "9:00 AM", title: "Team Standup", color: .blue)
                CalendarEventRow(time: "2:00 PM", title: "Client Review", color: .orange)
                CalendarEventRow(time: "4:30 PM", title: "Project Planning", color: .green)
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
        )
    }
}

struct CalendarEventRow: View {
    let time: String
    let title: String
    let color: Color
    
    var body: some View {
        HStack {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            
            Text(time)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.primary)
            
            Spacer()
        }
    }
}

// MARK: - Data Models

struct PriorityTask: Identifiable {
    let id: UUID
    var description: String
    var priority: Int
}

// MARK: - Task Selector Sheet

struct TaskSelectorSheet: View {
    let brainDumpText: String
    @Binding var extractedTasks: [String]
    @Binding var selectedTasks: [String]
    let onComplete: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Select up to 6 tasks")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text("Choose the most important tasks for tomorrow. You can edit them after selection.")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 20)
                
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(extractedTasks, id: \.self) { task in
                            TaskSelectionRow(
                                task: task,
                                isSelected: selectedTasks.contains(task),
                                onToggle: { toggleTask(task) }
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                }
                
                VStack(spacing: 16) {
                    Text("Selected: \(selectedTasks.count)/6")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Button(action: {
                        onComplete()
                        dismiss()
                    }) {
                        Text("Continue with \(selectedTasks.count) tasks")
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .padding(.vertical, 16)
                            .padding(.horizontal, 32)
                            .background(selectedTasks.isEmpty ? Color.gray : Color.blue)
                            .clipShape(Capsule())
                    }
                    .disabled(selectedTasks.isEmpty)
                }
                .padding(.horizontal, 20)
            }
            .navigationTitle("Select Tasks")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
    
    private func toggleTask(_ task: String) {
        if selectedTasks.contains(task) {
            selectedTasks.removeAll { $0 == task }
        } else if selectedTasks.count < 6 {
            selectedTasks.append(task)
        }
    }
}

struct TaskSelectionRow: View {
    let task: String
    let isSelected: Bool
    let onToggle: () -> Void
    
    var body: some View {
        Button(action: onToggle) {
            HStack {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .blue : .gray)
                    .font(.title3)
                
                Text(task)
                    .font(.body)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.leading)
                
                Spacer()
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(isSelected ? Color.blue.opacity(0.1) : Color.white)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue.opacity(0.3) : Color.gray.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    EveningBrainDumpView()
        .modelContainer(for: [DailyEntry.self, IvyLeeTask.self, SomedayMaybeTask.self, SmartFeatures.self, UserInsight.self], inMemory: true)
} 