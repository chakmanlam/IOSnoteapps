//
//  FocusTimerView.swift
//  AINotes
//
//  Created by AI Assistant on 5/23/25.
//

import SwiftUI

struct FocusTimerView: View {
    @Bindable var timerManager: FocusTimerManager
    let currentTask: IvyLeeTask?
    @State private var showingSettings = false
    @State private var showingNotes = false
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 30) {
                // Header Section
                headerSection
                
                // Main Timer Circle
                timerCircleSection(geometry: geometry)
                
                // Timer Controls
                timerControlsSection
                
                // Quick Actions
                quickActionsSection
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
        }
        .sheet(isPresented: $showingSettings) {
            FocusTimerSettingsView(timerManager: timerManager)
        }
        .sheet(isPresented: $showingNotes) {
            SessionNotesView(timerManager: timerManager)
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading) {
                    Text(timerManager.currentPhaseDisplayText)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(timerManager.timerMode.color)
                    
                    if let task = currentTask {
                        Text(task.taskDescription)
                            .font(.body)
                            .foregroundColor(.primary)
                            .lineLimit(2)
                    }
                }
                
                Spacer()
                
                Button(action: { showingSettings = true }) {
                    Image(systemName: "gearshape")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
                .accessibilityLabel("Timer settings")
            }
            
            // Session Progress
            HStack(spacing: 4) {
                ForEach(1...4, id: \.self) { session in
                    Circle()
                        .fill(session <= timerManager.completedSessions ? 
                              Color.green : 
                              session == timerManager.currentSession ? 
                              timerManager.timerMode.color : 
                              Color.gray.opacity(0.3))
                        .frame(width: 12, height: 12)
                }
                
                Spacer()
                
                Text(timerManager.sessionSummary)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    // MARK: - Timer Circle Section
    private func timerCircleSection(geometry: GeometryProxy) -> some View {
        let size = min(geometry.size.width - 80, 280)
        
        return ZStack {
            // Background Circle
            Circle()
                .stroke(Color.gray.opacity(0.2), lineWidth: 8)
                .frame(width: size, height: size)
            
            // Progress Circle
            Circle()
                .trim(from: 0, to: timerManager.progressPercentage)
                .stroke(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            timerManager.timerMode.color,
                            timerManager.timerMode.color.opacity(0.6)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: 8, lineCap: .round)
                )
                .frame(width: size, height: size)
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 1), value: timerManager.progressPercentage)
            
            // Timer Display
            VStack(spacing: 8) {
                Text(timerManager.formattedTimeRemaining)
                    .font(.system(size: 48, weight: .light, design: .monospaced))
                    .foregroundColor(.primary)
                
                Text(timerManager.timerMode.emoji)
                    .font(.title)
                
                if timerManager.isRunning {
                    Text("Focus mode")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .opacity(0.8)
                }
            }
        }
    }
    
    // MARK: - Timer Controls Section
    private var timerControlsSection: some View {
        HStack(spacing: 20) {
            // Stop Button
            if timerManager.isRunning || timerManager.isPaused {
                Button(action: { timerManager.stopTimer() }) {
                    Image(systemName: "stop.fill")
                        .font(.title2)
                        .frame(width: 60, height: 60)
                        .background(Color.red.opacity(0.2))
                        .foregroundColor(.red)
                        .clipShape(Circle())
                }
                .accessibilityLabel("Stop timer")
            }
            
            Spacer()
            
            // Main Control Button
            Button(action: { 
                if timerManager.isRunning {
                    timerManager.pauseTimer()
                } else if timerManager.isPaused {
                    timerManager.resumeTimer()
                } else {
                    timerManager.startTimer(for: currentTask)
                }
            }) {
                Image(systemName: timerManager.isRunning ? "pause.fill" : "play.fill")
                    .font(.title)
                    .frame(width: 80, height: 80)
                    .background(timerManager.timerMode.color)
                    .foregroundColor(.white)
                    .clipShape(Circle())
                    .shadow(color: timerManager.timerMode.color.opacity(0.3), radius: 8, x: 0, y: 4)
            }
            .accessibilityLabel(timerManager.isRunning ? "Pause timer" : "Start timer")
            .scaleEffect(timerManager.isRunning ? 1.1 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: timerManager.isRunning)
            
            Spacer()
            
            // Skip Button
            if timerManager.isRunning || timerManager.isPaused {
                Button(action: { 
                    if timerManager.timerMode == .focus {
                        timerManager.skipToBreak()
                    } else {
                        timerManager.skipBreak()
                    }
                }) {
                    Image(systemName: "forward.fill")
                        .font(.title2)
                        .frame(width: 60, height: 60)
                        .background(Color.orange.opacity(0.2))
                        .foregroundColor(.orange)
                        .clipShape(Circle())
                }
                .accessibilityLabel("Skip to next phase")
            }
        }
    }
    
    // MARK: - Quick Actions Section
    private var quickActionsSection: some View {
        HStack(spacing: 16) {
            // Background Sound Toggle
            Button(action: { 
                timerManager.enableBackgroundSound.toggle()
            }) {
                HStack(spacing: 8) {
                    Image(systemName: timerManager.enableBackgroundSound ? 
                          timerManager.selectedBackgroundSound.icon : "speaker.slash")
                        .font(.body)
                    Text(timerManager.enableBackgroundSound ? "Sound On" : "Sound Off")
                        .font(.caption)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(timerManager.enableBackgroundSound ? 
                           Color.blue.opacity(0.2) : Color.gray.opacity(0.2))
                .foregroundColor(timerManager.enableBackgroundSound ? .blue : .secondary)
                .clipShape(Capsule())
            }
            .accessibilityLabel("Toggle background sound")
            
            Spacer()
            
            // Session Notes
            Button(action: { showingNotes = true }) {
                HStack(spacing: 8) {
                    Image(systemName: "note.text")
                        .font(.body)
                    Text("Notes")
                        .font(.caption)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.gray.opacity(0.2))
                .foregroundColor(.secondary)
                .clipShape(Capsule())
            }
            .accessibilityLabel("Add session notes")
            
            Spacer()
            
            // Quick Settings
            Button(action: { showingSettings = true }) {
                HStack(spacing: 8) {
                    Image(systemName: "slider.horizontal.3")
                        .font(.body)
                    Text("Settings")
                        .font(.caption)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.gray.opacity(0.2))
                .foregroundColor(.secondary)
                .clipShape(Capsule())
            }
            .accessibilityLabel("Timer settings")
        }
    }
}

// MARK: - Focus Timer Settings View
struct FocusTimerSettingsView: View {
    @Bindable var timerManager: FocusTimerManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section("Timer Durations") {
                    TimerDurationPicker(
                        title: "Focus Duration",
                        duration: Binding(
                            get: { timerManager.focusDuration },
                            set: { timerManager.updateFocusDuration($0) }
                        )
                    )
                    
                    TimerDurationPicker(
                        title: "Short Break",
                        duration: Binding(
                            get: { timerManager.shortBreakDuration },
                            set: { timerManager.updateShortBreakDuration($0) }
                        )
                    )
                    
                    TimerDurationPicker(
                        title: "Long Break",
                        duration: Binding(
                            get: { timerManager.longBreakDuration },
                            set: { timerManager.updateLongBreakDuration($0) }
                        )
                    )
                }
                
                Section("Background Sound") {
                    Toggle("Enable Background Sound", isOn: $timerManager.enableBackgroundSound)
                    
                    if timerManager.enableBackgroundSound {
                        Picker("Sound", selection: $timerManager.selectedBackgroundSound) {
                            ForEach(BackgroundSound.allCases, id: \.self) { sound in
                                HStack {
                                    Image(systemName: sound.icon)
                                    Text(sound.displayName)
                                }
                                .tag(sound)
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Volume")
                                .font(.subheadline)
                            Slider(value: $timerManager.backgroundVolume, in: 0...1)
                        }
                    }
                }
                
                Section("Notifications & Feedback") {
                    Toggle("Notifications", isOn: $timerManager.enableNotifications)
                    Toggle("Haptic Feedback", isOn: $timerManager.enableHapticFeedback)
                }
                
                Section("Automation") {
                    Toggle("Auto-start Breaks", isOn: $timerManager.autoStartBreaks)
                    Toggle("Auto-start Next Session", isOn: $timerManager.autoStartNextSession)
                }
            }
            .navigationTitle("Focus Timer Settings")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden()
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Timer Duration Picker
struct TimerDurationPicker: View {
    let title: String
    @Binding var duration: TimeInterval
    
    private var minutes: Int {
        Int(duration / 60)
    }
    
    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Picker("", selection: Binding(
                get: { minutes },
                set: { duration = TimeInterval($0 * 60) }
            )) {
                ForEach([5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55, 60], id: \.self) { minute in
                    Text("\(minute) min").tag(minute)
                }
            }
            .pickerStyle(MenuPickerStyle())
        }
    }
}

// MARK: - Session Notes View
struct SessionNotesView: View {
    @Bindable var timerManager: FocusTimerManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                if let task = timerManager.currentTask {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Current Task")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        Text(task.taskDescription)
                            .font(.title3)
                            .fontWeight(.medium)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                }
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("Session Notes")
                        .font(.headline)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                    
                    TextEditor(text: $timerManager.sessionNotes)
                        .font(.body)
                        .padding(12)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(12)
                        .padding(.horizontal)
                }
                
                Spacer()
            }
            .padding(.top, 20)
            .navigationTitle("Session Notes")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden()
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    FocusTimerView(
        timerManager: FocusTimerManager(),
        currentTask: IvyLeeTask(description: "Complete project proposal", priority: 1)
    )
} 