//
//  NotesViewModel.swift
//  AINotes
//
//  Created by AI Assistant on 5/23/25.
//

import Foundation
import SwiftData
import SwiftUI

@Observable
class NotesViewModel {
    var modelContext: ModelContext
    var currentEntry: DailyEntry?
    
    // Notes state (now maps to executionNotes)
    var notes: String = ""
    var isAutoSaving: Bool = false
    
    // Auto-save debouncing
    private var autoSaveTimer: Timer?
    private let autoSaveDelay: TimeInterval = 1.5 // 1.5 seconds delay
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        loadOrCreateTodaysEntry()
        loadTodaysNotes()
    }
    
    // MARK: - Data Management
    
    func loadOrCreateTodaysEntry() {
        let today = Calendar.current.startOfDay(for: Date())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today) ?? Date()
        
        let descriptor = FetchDescriptor<DailyEntry>(
            predicate: #Predicate<DailyEntry> { entry in
                entry.date >= today && entry.date < tomorrow
            }
        )
        
        do {
            let entries = try modelContext.fetch(descriptor)
            if let existingEntry = entries.first {
                currentEntry = existingEntry
            } else {
                let newEntry = DailyEntry(date: today)
                modelContext.insert(newEntry)
                currentEntry = newEntry
                try modelContext.save()
            }
        } catch {
            print("Failed to load or create today's entry: \(error)")
        }
    }
    
    func loadTodaysNotes() {
        guard let entry = currentEntry else {
            print("❌ No current entry found")
            return
        }
        
        // Load execution notes from the daily entry
        notes = entry.executionNotes
        print("📝 Loaded execution notes: \(notes.count) characters")
    }
    
    // MARK: - Auto-Save Functionality
    
    func scheduleAutoSave() {
        // Cancel any existing timer
        autoSaveTimer?.invalidate()
        
        // Show auto-saving indicator briefly
        withAnimation(.easeInOut(duration: 0.2)) {
            isAutoSaving = true
        }
        
        // Schedule new save after delay
        autoSaveTimer = Timer.scheduledTimer(withTimeInterval: autoSaveDelay, repeats: false) { [weak self] _ in
            self?.saveNotes()
        }
    }
    
    private func saveNotes() {
        guard let entry = currentEntry else {
            print("❌ Cannot save notes: no current entry")
            hideAutoSaveIndicator()
            return
        }
        
        // Update the executionNotes field
        entry.executionNotes = notes
        
        do {
            try modelContext.save()
            print("💾 Execution notes auto-saved: \(notes.count) characters")
        } catch {
            print("❌ Failed to save execution notes: \(error)")
        }
        
        hideAutoSaveIndicator()
    }
    
    private func hideAutoSaveIndicator() {
        DispatchQueue.main.async {
            withAnimation(.easeInOut(duration: 0.2)) {
                self.isAutoSaving = false
            }
        }
    }
    
    // MARK: - Quick Capture
    
    func quickCapture() {
        let currentTime = Date()
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        
        let timestamp = formatter.string(from: currentTime)
        let quickNote = "\n\n--- Quick Note (\(timestamp)) ---\n"
        
        // Add the quick note template to existing notes
        notes += quickNote
        
        // Trigger auto-save
        scheduleAutoSave()
        
        print("⚡ Quick capture added at \(timestamp)")
    }
    
    // MARK: - Cleanup
    
    deinit {
        // Cancel any pending auto-save when view model is deallocated
        autoSaveTimer?.invalidate()
    }
} 