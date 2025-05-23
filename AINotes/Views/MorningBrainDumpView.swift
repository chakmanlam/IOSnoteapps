//
//  MorningBrainDumpView.swift
//  Brain Dump
//
//  Created by AI Assistant on 5/23/25.
//

import SwiftUI
import SwiftData

struct MorningBrainDumpView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var dailyEntryViewModel: DailyEntryViewModel
    @State private var taskViewModel = IvyLeeTaskViewModel()
    @State private var focusTimerManager = FocusTimerManager()
    
    // Step management
    @State private var currentStep = 0
    @State private var isCompleted = false
    private let steps = ["Dump", "Process", "Focus"]
    
    // Step 1: DUMP states
    @State private var brainDumpText = ""
    @State private var wordCount = 0
    
    // Step 2: PROCESS states
    @State private var isProcessing = false
    @State private var processingProgress: Double = 0
    @State private var categorizedThoughts: CategorizedThoughts?
    @State private var showProcessingAnimation = false
    
    // Step 3: FOCUS states
    @State private var selectedPriorities: [ProcessedTask] = []
    @State private var morningIntention = ""
    @State private var morningGratitude = ""
    @State private var energyLevel: EnergyLevel = .medium
    @State private var whyMostImportant = ""
    
    // UI states
    @State private var isCompletingSetup = false
    
    init() {
        self._dailyEntryViewModel = State(wrappedValue: DailyEntryViewModel(modelContext: nil))
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Consistent warm gradient background
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
            loadMorningData()
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
                        Image(systemName: "sun.max.fill")
                            .foregroundColor(.orange)
                            .font(.title3)
                        
                        Text("Morning Clarity")
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                    
                    Text("Empty your mind, fill your day")
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
                                .fill(index <= currentStep ? Color.orange : Color.gray.opacity(0.3))
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
                            .fill(index < currentStep ? Color.orange : Color.gray.opacity(0.3))
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
                dumpSection
            case 1:
                processSection
            case 2:
                focusSection
            default:
                EmptyView()
            }
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - Step 1: DUMP Section
    private var dumpSection: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Brain Dump")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text("Let everything flow out - no structure needed, just empty your mind")
                    .font(.body)
                    .foregroundColor(.secondary)
            }
            
            VStack(spacing: 20) {
                // Enhanced Brain Dump Text Area
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "brain.head.profile")
                            .foregroundColor(.purple)
                            .font(.title2)
                        
                        Text("Let it all out...")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Spacer()
                        
                        // Word count
                        Text("\(wordCount) words")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.white.opacity(0.6))
                            .clipShape(Capsule())
                    }
                    
                    TextEditor(text: $brainDumpText)
                        .frame(minHeight: 180)
                        .padding(16)
                        .background(Color.white)
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(
                                    LinearGradient(
                                        colors: [Color.purple.opacity(0.3), Color.orange.opacity(0.3)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 2
                                )
                        )
                        .overlay(
                            Group {
                                if brainDumpText.isEmpty {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("Everything on your mind...")
                                            .foregroundColor(.secondary)
                                            .font(.body)
                                        Text("• Tasks you need to do")
                                            .foregroundColor(.secondary.opacity(0.8))
                                            .font(.caption)
                                        Text("• Things you're worried about")
                                            .foregroundColor(.secondary.opacity(0.8))
                                            .font(.caption)
                                        Text("• Ideas floating around")
                                            .foregroundColor(.secondary.opacity(0.8))
                                            .font(.caption)
                                        Text("• Anything at all...")
                                            .foregroundColor(.secondary.opacity(0.8))
                                            .font(.caption)
                                    }
                                    .padding(20)
                                    .allowsHitTesting(false)
                                }
                            },
                            alignment: .topLeading
                        )
                        .onChange(of: brainDumpText) { _, newValue in
                            updateWordCount(newValue)
                        }
                }
                
                // Quick Capture Buttons
                VStack(alignment: .leading, spacing: 12) {
                    Text("Quick Add:")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 12) {
                        ForEach(QuickCaptureType.allCases, id: \.self) { type in
                            Button(action: { addQuickCapture(type) }) {
                                VStack(spacing: 6) {
                                    Text(type.emoji)
                                        .font(.title2)
                                    Text(type.name)
                                        .font(.caption2)
                                        .fontWeight(.medium)
                                        .lineLimit(1)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color.white.opacity(0.8))
                                .cornerRadius(12)
                                .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
                            }
                            .foregroundColor(.primary)
                        }
                    }
                }
                
                // Encouragement based on word count
                if wordCount > 0 {
                    HStack {
                        Image(systemName: wordCount > 50 ? "checkmark.circle.fill" : "ellipsis.circle.fill")
                            .foregroundColor(wordCount > 50 ? .green : .orange)
                        
                        Text(wordCount > 50 ? "Great! You're really emptying your mind" : "Keep going... let it all out")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                    }
                    .padding(.horizontal, 4)
                }
            }
        }
    }
    
    // MARK: - Step 2: PROCESS Section
    private var processSection: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 8) {
                Text("AI Processing")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text("Let's organize your thoughts into actionable clarity")
                    .font(.body)
                    .foregroundColor(.secondary)
            }
            
            if isProcessing || showProcessingAnimation {
                processingAnimationView
            } else if let categorized = categorizedThoughts {
                categorizedThoughtsView(categorized)
            } else {
                readyToProcessView
            }
        }
    }
    
    // MARK: - Step 3: FOCUS Section
    private var focusSection: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Focus & Intention")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text("Choose your priorities and set your intention for the day")
                    .font(.body)
                    .foregroundColor(.secondary)
            }
            
            VStack(spacing: 20) {
                // Priority Selection
                if !selectedPriorities.isEmpty {
                    prioritySelectionView
                }
                
                // Mindset Setup
                mindsetSetupView
            }
        }
    }
    
    // MARK: - Processing Animation View
    private var processingAnimationView: some View {
        VStack(spacing: 24) {
            // Animated processing indicator
            ZStack {
                Circle()
                    .stroke(Color.purple.opacity(0.3), lineWidth: 6)
                    .frame(width: 100, height: 100)
                
                Circle()
                    .trim(from: 0, to: processingProgress)
                    .stroke(Color.purple, lineWidth: 6)
                    .frame(width: 100, height: 100)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.5), value: processingProgress)
                
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 32))
                    .foregroundColor(.purple)
                    .scaleEffect(isProcessing ? 1.1 : 1.0)
                    .animation(.easeInOut(duration: 1).repeatForever(autoreverses: true), value: isProcessing)
            }
            
            VStack(spacing: 8) {
                Text("Processing your thoughts...")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text("Categorizing and organizing")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .background(Color.white.opacity(0.6))
        .cornerRadius(16)
    }
    
    // MARK: - Ready to Process View
    private var readyToProcessView: some View {
        VStack(spacing: 20) {
            VStack(spacing: 12) {
                Image(systemName: "wand.and.rays")
                    .font(.system(size: 40))
                    .foregroundColor(.purple)
                
                Text("Ready to organize your thoughts")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text("AI will categorize everything you dumped")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button(action: startProcessing) {
                HStack {
                    Image(systemName: "brain.head.profile")
                    Text("Process My Thoughts")
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
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .background(Color.white.opacity(0.6))
        .cornerRadius(16)
    }
    
    // MARK: - Priority Selection View
    private var prioritySelectionView: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "target")
                    .foregroundColor(.orange)
                    .font(.title3)
                
                Text("Your Top Priorities")
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            
            Text("Drag to reorder. Choose your top 3 most important tasks.")
                .font(.caption)
                .foregroundColor(.secondary)
            
            LazyVStack(spacing: 8) {
                ForEach(Array(selectedPriorities.enumerated()), id: \.element.id) { index, task in
                    PriorityTaskCard(task: task, priority: index + 1)
                }
                .onMove(perform: movePriority)
            }
            
            // Why most important
            if !selectedPriorities.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Why is #1 most important today?")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    TextField("This will help me...", text: $whyMostImportant, axis: .vertical)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .lineLimit(2...4)
                }
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.6))
        .cornerRadius(16)
    }
    
    // MARK: - Mindset Setup View
    private var mindsetSetupView: some View {
        VStack(spacing: 20) {
            // Energy Check
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "bolt.fill")
                        .foregroundColor(.yellow)
                    Text("How's your energy?")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                
                HStack(spacing: 12) {
                    ForEach(EnergyLevel.allCases, id: \.self) { level in
                        Button(action: { energyLevel = level }) {
                            VStack(spacing: 6) {
                                Text(level.emoji)
                                    .font(.title2)
                                Text(level.rawValue.capitalized)
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
            
            // Intention
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "target")
                        .foregroundColor(.mint)
                    Text("Today I intend to...")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                
                TextField("be focused and productive", text: $morningIntention, axis: .vertical)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .lineLimit(1...3)
            }
            
            // Gratitude
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "heart.fill")
                        .foregroundColor(.pink)
                    Text("I'm grateful for...")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                
                TextField("something that brings you joy", text: $morningGratitude, axis: .vertical)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .lineLimit(1...3)
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.6))
        .cornerRadius(16)
    }
    
    // MARK: - Completion Section
    private var completionSection: some View {
        VStack(spacing: 32) {
            VStack(spacing: 16) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 64))
                    .foregroundColor(.green)
                
                Text("Mind Clear, Day Focused")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text("Your brain dump is organized.\nYour priorities are set.\nTime to make it happen!")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            
            // Today's top priority
            if let topPriority = selectedPriorities.first {
                VStack(spacing: 12) {
                    Text("Today's #1 Priority")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    HStack {
                        Text("#1")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.orange)
                            .clipShape(Capsule())
                        
                        Text(topPriority.title)
                            .font(.body)
                            .fontWeight(.medium)
                        
                        Spacer()
                    }
                    .padding(.vertical, 16)
                    .padding(.horizontal, 20)
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(12)
                }
            }
            
            Button(action: { dismiss() }) {
                HStack {
                    Image(systemName: "sun.max.fill")
                        .font(.body)
                    Text("Start My Day")
                        .fontWeight(.medium)
                }
                .foregroundColor(.white)
                .padding(.vertical, 16)
                .padding(.horizontal, 32)
                .background(Color.orange)
                .clipShape(Capsule())
                .shadow(color: .orange.opacity(0.3), radius: 6, x: 0, y: 3)
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
                    completeMorningSetup()
                }
            }) {
                HStack(spacing: 8) {
                    if currentStep == steps.count - 1 && isCompletingSetup {
                        ProgressView()
                            .scaleEffect(0.7)
                            .tint(.white)
                    } else {
                        Image(systemName: currentStep < steps.count - 1 ? "chevron.right" : "checkmark.circle.fill")
                            .font(.system(size: 14, weight: .medium))
                    }
                    
                    Text(currentStep < steps.count - 1 ? "Continue" : "Complete Morning Setup")
                        .font(.system(size: 15, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.vertical, 12)
                .padding(.horizontal, 20)
                .background(
                    Group {
                        if canProceed {
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.orange.opacity(0.9),
                                    Color.orange
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        } else {
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.gray.opacity(0.7),
                                    Color.gray.opacity(0.8)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        }
                    }
                )
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.white.opacity(0.3),
                                    Color.clear
                                ]),
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 0.5
                        )
                )
                .shadow(
                    color: canProceed ? Color.orange.opacity(0.4) : Color.black.opacity(0.1),
                    radius: canProceed ? 8 : 2,
                    x: 0,
                    y: canProceed ? 4 : 1
                )
                .scaleEffect(isCompletingSetup ? 0.95 : 1.0)
                .animation(.easeInOut(duration: 0.1), value: isCompletingSetup)
            }
            .disabled(!canProceed || (currentStep == steps.count - 1 && isCompletingSetup))
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 24)
    }
    
    // MARK: - Helper Functions
    private var canProceed: Bool {
        switch currentStep {
        case 0: return !brainDumpText.trimmingCharacters(in: .whitespaces).isEmpty
        case 1: return categorizedThoughts != nil
        case 2: return canCompleteSetup
        default: return true
        }
    }
    
    private var canCompleteSetup: Bool {
        !morningIntention.trimmingCharacters(in: .whitespaces).isEmpty &&
        !morningGratitude.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    private func setupViewModels() {
        if dailyEntryViewModel.modelContext == nil {
            dailyEntryViewModel.setModelContext(modelContext)
        }
        taskViewModel.setModelContext(modelContext)
        taskViewModel.setDailyEntryViewModel(dailyEntryViewModel)
    }
    
    private func loadMorningData() {
        if let entry = dailyEntryViewModel.currentEntry {
            morningGratitude = entry.morningGratitude
            morningIntention = entry.morningIntention
            energyLevel = entry.morningEnergyCheck
            brainDumpText = entry.brainDumpText ?? ""
            updateWordCount(brainDumpText)
        }
    }
    
    private func updateWordCount(_ text: String) {
        wordCount = text.split(separator: " ").count
    }
    
    private func addQuickCapture(_ type: QuickCaptureType) {
        let prefix = brainDumpText.isEmpty ? "" : "\n"
        brainDumpText += "\(prefix)\(type.prompt) "
        updateWordCount(brainDumpText)
    }
    
    private func startProcessing() {
        isProcessing = true
        showProcessingAnimation = true
        processingProgress = 0
        
        // Simulate processing with animation
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            processingProgress += 0.02
            if processingProgress >= 1.0 {
                timer.invalidate()
                
                // Simulate AI processing delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    finishProcessing()
                }
            }
        }
    }
    
    private func finishProcessing() {
        // Mock categorized thoughts for now - in real implementation, this would call AI service
        categorizedThoughts = CategorizedThoughts(
            highPriorityTasks: [
                ProcessedTask(id: UUID(), title: "Complete project proposal", category: .task),
                ProcessedTask(id: UUID(), title: "Call dentist for appointment", category: .task),
                ProcessedTask(id: UUID(), title: "Review team feedback", category: .task)
            ],
            scheduledItems: [
                ProcessedTask(id: UUID(), title: "Team meeting at 2 PM", category: .scheduled)
            ],
            ideas: [
                ProcessedTask(id: UUID(), title: "App feature for notifications", category: .idea)
            ],
            worries: [
                ProcessedTask(id: UUID(), title: "Budget concerns for next quarter", category: .worry)
            ]
        )
        
        selectedPriorities = Array(categorizedThoughts?.highPriorityTasks.prefix(3) ?? [])
        isProcessing = false
        showProcessingAnimation = false
    }
    
    private func categorizedThoughtsView(_ categorized: CategorizedThoughts) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Your thoughts, organized:")
                .font(.headline)
                .fontWeight(.semibold)
            
            if !categorized.highPriorityTasks.isEmpty {
                CategorySection(title: "🎯 High Priority Tasks", items: categorized.highPriorityTasks)
            }
            
            if !categorized.scheduledItems.isEmpty {
                CategorySection(title: "📅 Scheduled Items", items: categorized.scheduledItems)
            }
            
            if !categorized.ideas.isEmpty {
                CategorySection(title: "💡 Ideas to Capture", items: categorized.ideas)
            }
            
            if !categorized.worries.isEmpty {
                CategorySection(title: "😰 Worries to Address", items: categorized.worries)
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.6))
        .cornerRadius(16)
    }
    
    private func movePriority(from source: IndexSet, to destination: Int) {
        selectedPriorities.move(fromOffsets: source, toOffset: destination)
    }
    
    private func energyLevelColor(_ level: EnergyLevel) -> Color {
        switch level {
        case .low: return .orange
        case .medium: return .yellow
        case .high: return .green
        }
    }
    
    private func completeMorningSetup() {
        isCompletingSetup = true
        
        Task {
            // Save all data
            await saveMorningData()
            
            // Mark ritual as completed
            dailyEntryViewModel.completeMorningRitual()
            
            // Small delay for UX
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            
            await MainActor.run {
                isCompletingSetup = false
                isCompleted = true
            }
        }
    }
    
    private func saveMorningData() async {
        guard let entry = dailyEntryViewModel.currentEntry else { return }
        
        await MainActor.run {
            entry.morningGratitude = morningGratitude
            entry.morningIntention = morningIntention
            entry.morningEnergyCheck = energyLevel
            entry.brainDumpText = brainDumpText
            entry.whyMostImportant = whyMostImportant
            
            // Convert selectedPriorities to IvyLeeTask objects
            if !selectedPriorities.isEmpty {
                // Clear existing tasks for today to avoid duplicates
                entry.taskQueue.removeAll { !$0.isCompleted }
                
                // Create IvyLeeTask objects from selected priorities
                for (index, priorityTask) in selectedPriorities.enumerated() {
                    let newTask = IvyLeeTask(
                        description: priorityTask.title,
                        priority: index + 1,
                        reasoning: index == 0 ? whyMostImportant : "Morning brain dump priority #\(index + 1)"
                    )
                    newTask.dailyEntry = entry
                    entry.taskQueue.append(newTask)
                }
                
                // Update task view model to reflect new tasks
                taskViewModel.refreshTasks()
            }
            
            dailyEntryViewModel.saveContext()
        }
    }
}

// MARK: - Supporting Views and Models

struct CategorySection: View {
    let title: String
    let items: [ProcessedTask]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
            
            ForEach(items) { item in
                Text("• \(item.title)")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .padding(.leading, 8)
            }
        }
    }
}

struct PriorityTaskCard: View {
    let task: ProcessedTask
    let priority: Int
    
    var body: some View {
        HStack(spacing: 12) {
            Text("#\(priority)")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(priorityColor)
                .clipShape(Capsule())
            
            Text(task.title)
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
        switch priority {
        case 1: return .green
        case 2: return .blue
        case 3: return .orange
        default: return .gray
        }
    }
}

// MARK: - Data Models

enum QuickCaptureType: String, CaseIterable {
    case task = "Task"
    case call = "Call"
    case email = "Email"
    case idea = "Idea"
    case worry = "Worry"
    
    var emoji: String {
        switch self {
        case .task: return "📝"
        case .call: return "📞"
        case .email: return "📧"
        case .idea: return "💡"
        case .worry: return "😰"
        }
    }
    
    var name: String {
        return rawValue
    }
    
    var prompt: String {
        switch self {
        case .task: return "TASK:"
        case .call: return "CALL:"
        case .email: return "EMAIL:"
        case .idea: return "IDEA:"
        case .worry: return "WORRY:"
        }
    }
}

struct ProcessedTask: Identifiable {
    let id: UUID
    let title: String
    let category: TaskCategory
}

enum TaskCategory {
    case task, scheduled, idea, worry
}

struct CategorizedThoughts {
    let highPriorityTasks: [ProcessedTask]
    let scheduledItems: [ProcessedTask]
    let ideas: [ProcessedTask]
    let worries: [ProcessedTask]
}

#Preview {
    MorningBrainDumpView()
        .modelContainer(for: [DailyEntry.self, IvyLeeTask.self, SomedayMaybeTask.self, SmartFeatures.self, UserInsight.self], inMemory: true)
} 