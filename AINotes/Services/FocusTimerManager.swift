//
//  FocusTimerManager.swift
//  AINotes
//
//  Created by AI Assistant on 5/23/25.
//

import Foundation
import SwiftUI
import AVFoundation
import Combine

@Observable
class FocusTimerManager {
    // MARK: - Timer State
    var isRunning = false
    var isPaused = false
    var timeRemaining: TimeInterval = 1500 // 25 minutes default
    var timerMode: TimerMode = .focus
    var currentSession = 1
    var completedSessions = 0
    
    // MARK: - Pomodoro Configuration
    var focusDuration: TimeInterval = 1500 // 25 minutes
    var shortBreakDuration: TimeInterval = 300 // 5 minutes
    var longBreakDuration: TimeInterval = 900 // 15 minutes
    var longBreakInterval = 4 // Every 4 sessions
    
    // MARK: - Background Sound
    var enableBackgroundSound = false
    var selectedBackgroundSound: BackgroundSound = .none
    var backgroundVolume: Float = 0.3
    
    // MARK: - Notifications & Feedback
    var enableNotifications = true
    var enableHapticFeedback = true
    var autoStartBreaks = false
    var autoStartNextSession = false
    
    // MARK: - Private Properties
    private var timer: Timer?
    private var audioPlayer: AVAudioPlayer?
    private var tickSoundPlayer: AVAudioPlayer?
    private var completionSoundPlayer: AVAudioPlayer?
    
    // MARK: - Current Task
    var currentTask: IvyLeeTask?
    var taskStartTime: Date?
    var sessionNotes: String = ""
    
    init() {
        setupAudioSession()
        loadUserPreferences()
    }
    
    // MARK: - Timer Control Methods
    
    func startTimer(for task: IvyLeeTask? = nil) {
        if let task = task {
            currentTask = task
            taskStartTime = Date()
        }
        
        isRunning = true
        isPaused = false
        
        if timeRemaining <= 0 {
            resetCurrentSession()
        }
        
        startBackgroundSound()
        provideFeedback(.start)
        
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.timerTick()
        }
    }
    
    func pauseTimer() {
        isPaused = true
        isRunning = false
        timer?.invalidate()
        timer = nil
        stopBackgroundSound()
        provideFeedback(.pause)
    }
    
    func resumeTimer() {
        guard isPaused else { return }
        startTimer()
    }
    
    func stopTimer() {
        isRunning = false
        isPaused = false
        timer?.invalidate()
        timer = nil
        stopBackgroundSound()
        resetCurrentSession()
        provideFeedback(.stop)
        
        // Clear current task
        currentTask = nil
        taskStartTime = nil
        sessionNotes = ""
    }
    
    func skipToBreak() {
        guard timerMode == .focus else { return }
        completeCurrentSession()
    }
    
    func skipBreak() {
        guard timerMode != .focus else { return }
        completeCurrentSession()
    }
    
    // MARK: - Private Timer Methods
    
    private func timerTick() {
        timeRemaining -= 1
        
        if timeRemaining <= 0 {
            completeCurrentSession()
        } else if timeRemaining <= 10 && timerMode == .focus {
            // Play tick sound for last 10 seconds of focus session
            playTickSound()
        }
    }
    
    private func completeCurrentSession() {
        timer?.invalidate()
        timer = nil
        isRunning = false
        isPaused = false
        
        stopBackgroundSound()
        playCompletionSound()
        provideFeedback(.complete)
        
        // Move to next phase
        switch timerMode {
        case .focus:
            completedSessions += 1
            
            if completedSessions % longBreakInterval == 0 {
                startLongBreak()
            } else {
                startShortBreak()
            }
            
        case .shortBreak, .longBreak:
            startNextFocusSession()
        }
        
        // Send notification
        if enableNotifications {
            sendNotification()
        }
        
        // Auto-start next session if enabled
        if (timerMode != .focus && autoStartBreaks) || (timerMode == .focus && autoStartNextSession) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                self.startTimer()
            }
        }
    }
    
    private func startShortBreak() {
        timerMode = .shortBreak
        timeRemaining = shortBreakDuration
    }
    
    private func startLongBreak() {
        timerMode = .longBreak
        timeRemaining = longBreakDuration
    }
    
    private func startNextFocusSession() {
        timerMode = .focus
        timeRemaining = focusDuration
        currentSession += 1
    }
    
    private func resetCurrentSession() {
        timeRemaining = timerMode == .focus ? focusDuration : 
                       timerMode == .shortBreak ? shortBreakDuration : longBreakDuration
    }
    
    // MARK: - Audio Methods
    
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to setup audio session: \(error)")
        }
    }
    
    private func startBackgroundSound() {
        guard enableBackgroundSound, selectedBackgroundSound != .none else { return }
        
        guard let soundURL = selectedBackgroundSound.soundURL else { return }
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
            audioPlayer?.numberOfLoops = -1 // Loop indefinitely
            audioPlayer?.volume = backgroundVolume
            audioPlayer?.play()
        } catch {
            print("Failed to play background sound: \(error)")
        }
    }
    
    private func stopBackgroundSound() {
        audioPlayer?.stop()
        audioPlayer = nil
    }
    
    private func playTickSound() {
        // Play subtle tick sound for focus countdown
        guard let tickURL = Bundle.main.url(forResource: "tick", withExtension: "wav") else { return }
        
        do {
            tickSoundPlayer = try AVAudioPlayer(contentsOf: tickURL)
            tickSoundPlayer?.volume = 0.1
            tickSoundPlayer?.play()
        } catch {
            print("Failed to play tick sound: \(error)")
        }
    }
    
    private func playCompletionSound() {
        guard let completionURL = Bundle.main.url(forResource: "completion", withExtension: "wav") else { return }
        
        do {
            completionSoundPlayer = try AVAudioPlayer(contentsOf: completionURL)
            completionSoundPlayer?.volume = 0.5
            completionSoundPlayer?.play()
        } catch {
            print("Failed to play completion sound: \(error)")
        }
    }
    
    // MARK: - Feedback Methods
    
    private func provideFeedback(_ type: FeedbackType) {
        guard enableHapticFeedback else { return }
        
        switch type {
        case .start:
            let impact = UIImpactFeedbackGenerator(style: .medium)
            impact.impactOccurred()
        case .pause:
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
        case .stop:
            let impact = UIImpactFeedbackGenerator(style: .heavy)
            impact.impactOccurred()
        case .complete:
            let notification = UINotificationFeedbackGenerator()
            notification.notificationOccurred(.success)
        }
    }
    
    private func sendNotification() {
        // Request notification permission and send appropriate notification
        // This would be implemented with proper notification handling
    }
    
    // MARK: - Computed Properties
    
    var formattedTimeRemaining: String {
        let minutes = Int(timeRemaining) / 60
        let seconds = Int(timeRemaining) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    var progressPercentage: Double {
        let totalDuration = timerMode == .focus ? focusDuration :
                           timerMode == .shortBreak ? shortBreakDuration : longBreakDuration
        return 1.0 - (timeRemaining / totalDuration)
    }
    
    var timerState: TimerState {
        if isRunning {
            return .running
        } else if isPaused {
            return .paused
        } else if timeRemaining <= 0 {
            return .completed
        } else {
            return .stopped
        }
    }
    
    var currentPhaseDisplayText: String {
        switch timerMode {
        case .focus:
            return "Focus Session \(currentSession)"
        case .shortBreak:
            return "Short Break"
        case .longBreak:
            return "Long Break"
        }
    }
    
    var sessionSummary: String {
        return "Completed: \(completedSessions) sessions"
    }
    
    // MARK: - User Preferences
    
    func updateFocusDuration(_ duration: TimeInterval) {
        focusDuration = duration
        if timerMode == .focus && !isRunning {
            timeRemaining = duration
        }
        saveUserPreferences()
    }
    
    func updateShortBreakDuration(_ duration: TimeInterval) {
        shortBreakDuration = duration
        if timerMode == .shortBreak && !isRunning {
            timeRemaining = duration
        }
        saveUserPreferences()
    }
    
    func updateLongBreakDuration(_ duration: TimeInterval) {
        longBreakDuration = duration
        if timerMode == .longBreak && !isRunning {
            timeRemaining = duration
        }
        saveUserPreferences()
    }
    
    func updateBackgroundSound(_ sound: BackgroundSound) {
        selectedBackgroundSound = sound
        if isRunning {
            stopBackgroundSound()
            startBackgroundSound()
        }
        saveUserPreferences()
    }
    
    private func saveUserPreferences() {
        UserDefaults.standard.set(focusDuration, forKey: "FocusTimerDuration")
        UserDefaults.standard.set(shortBreakDuration, forKey: "ShortBreakDuration")
        UserDefaults.standard.set(longBreakDuration, forKey: "LongBreakDuration")
        UserDefaults.standard.set(selectedBackgroundSound.rawValue, forKey: "BackgroundSound")
        UserDefaults.standard.set(backgroundVolume, forKey: "BackgroundVolume")
        UserDefaults.standard.set(enableBackgroundSound, forKey: "EnableBackgroundSound")
        UserDefaults.standard.set(enableNotifications, forKey: "EnableNotifications")
        UserDefaults.standard.set(enableHapticFeedback, forKey: "EnableHapticFeedback")
        UserDefaults.standard.set(autoStartBreaks, forKey: "AutoStartBreaks")
        UserDefaults.standard.set(autoStartNextSession, forKey: "AutoStartNextSession")
        UserDefaults.standard.set(longBreakInterval, forKey: "LongBreakInterval")
    }
    
    private func loadUserPreferences() {
        focusDuration = UserDefaults.standard.double(forKey: "FocusTimerDuration")
        if focusDuration <= 0 { focusDuration = 1500 } // Default 25 minutes
        
        shortBreakDuration = UserDefaults.standard.double(forKey: "ShortBreakDuration")
        if shortBreakDuration <= 0 { shortBreakDuration = 300 } // Default 5 minutes
        
        longBreakDuration = UserDefaults.standard.double(forKey: "LongBreakDuration")
        if longBreakDuration <= 0 { longBreakDuration = 900 } // Default 15 minutes
        
        let soundRawValue = UserDefaults.standard.string(forKey: "BackgroundSound") ?? "none"
        selectedBackgroundSound = BackgroundSound(rawValue: soundRawValue) ?? .none
        
        backgroundVolume = UserDefaults.standard.float(forKey: "BackgroundVolume")
        if backgroundVolume <= 0 { backgroundVolume = 0.3 }
        
        enableBackgroundSound = UserDefaults.standard.bool(forKey: "EnableBackgroundSound")
        enableNotifications = UserDefaults.standard.bool(forKey: "EnableNotifications")
        enableHapticFeedback = UserDefaults.standard.bool(forKey: "EnableHapticFeedback")
        autoStartBreaks = UserDefaults.standard.bool(forKey: "AutoStartBreaks")
        autoStartNextSession = UserDefaults.standard.bool(forKey: "AutoStartNextSession")
        
        longBreakInterval = UserDefaults.standard.integer(forKey: "LongBreakInterval")
        if longBreakInterval <= 0 { longBreakInterval = 4 }
        
        timeRemaining = focusDuration
    }
}

// MARK: - Supporting Enums

enum TimerMode: String, CaseIterable {
    case focus = "Focus"
    case shortBreak = "Short Break"
    case longBreak = "Long Break"
    
    var emoji: String {
        switch self {
        case .focus: return "🎯"
        case .shortBreak: return "☕"
        case .longBreak: return "🌅"
        }
    }
    
    var color: Color {
        switch self {
        case .focus: return .blue
        case .shortBreak: return .green
        case .longBreak: return .orange
        }
    }
}

enum BackgroundSound: String, CaseIterable {
    case none = "none"
    case rain = "rain"
    case forest = "forest"
    case ocean = "ocean"
    case cafe = "cafe"
    case whitenoise = "whitenoise"
    case fireplace = "fireplace"
    
    var displayName: String {
        switch self {
        case .none: return "None"
        case .rain: return "Rain"
        case .forest: return "Forest"
        case .ocean: return "Ocean"
        case .cafe: return "Café"
        case .whitenoise: return "White Noise"
        case .fireplace: return "Fireplace"
        }
    }
    
    var soundURL: URL? {
        guard self != .none else { return nil }
        return Bundle.main.url(forResource: rawValue, withExtension: "mp3")
    }
    
    var icon: String {
        switch self {
        case .none: return "speaker.slash"
        case .rain: return "cloud.rain"
        case .forest: return "tree"
        case .ocean: return "water.waves"
        case .cafe: return "cup.and.saucer"
        case .whitenoise: return "speaker.wave.3"
        case .fireplace: return "flame"
        }
    }
}

enum FeedbackType {
    case start, pause, stop, complete
} 