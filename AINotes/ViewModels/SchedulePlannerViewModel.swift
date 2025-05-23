//
//  SchedulePlannerViewModel.swift
//  AINotes
//
//  Created by AI Assistant on 5/23/25.
//

import Foundation
import SwiftData
import SwiftUI

@Observable
class SchedulePlannerViewModel {
    var modelContext: ModelContext
    var currentEntry: DailyEntry?
    
    // Schedule entries for the current day
    var scheduleEntries: [ScheduleEntry] = []
    
    // UI state
    var selectedTimeSlot: Date?
    var isCreatingEntry: Bool = false
    var isEditingEntry: Bool = false
    var editingEntry: ScheduleEntry?
    
    // Form state for creating/editing entries
    var entryTitle: String = ""
    var entryStartTime: Date = Date()
    var entryEndTime: Date = Date().addingTimeInterval(3600) // Default 1 hour
    var entryColor: String = "#A3BFCB" // Default sage color
    var entryNotes: String = ""
    
    // Time slot configuration
    let startHour: Int = 6  // 6 AM
    let endHour: Int = 21   // 9 PM
    let slotDuration: TimeInterval = 1800 // 30 minutes
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        loadOrCreateTodaysEntry()
        loadTodaysScheduleEntries()
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
    
    func loadTodaysScheduleEntries() {
        guard let entry = currentEntry else { 
            print("❌ No current entry found")
            return 
        }
        
        // Use direct relationship access - this is the correct SwiftData approach
        scheduleEntries = entry.scheduleEntries.sorted { $0.time < $1.time }
        print("📅 Loaded \(scheduleEntries.count) schedule entries via relationship")
    }
    
    // MARK: - Time Slot Management
    
    func timeSlots() -> [Date] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var slots: [Date] = []
        
        for hour in startHour...endHour {
            for minute in stride(from: 0, to: 60, by: 30) {
                if let timeSlot = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: today) {
                    slots.append(timeSlot)
                }
            }
        }
        
        return slots
    }
    
    func isCurrentTimeSlot(_ timeSlot: Date) -> Bool {
        let now = Date()
        let nextSlot = timeSlot.addingTimeInterval(slotDuration)
        return timeSlot <= now && now < nextSlot
    }
    
    func isTimeSlotOccupied(_ timeSlot: Date) -> Bool {
        return scheduleEntries.contains { entry in
            let entryStart = entry.time
            let entryEnd = entry.endTime
            return timeSlot < entryEnd && timeSlot.addingTimeInterval(slotDuration) > entryStart
        }
    }
    
    func entriesForTimeSlot(_ timeSlot: Date) -> [ScheduleEntry] {
        return scheduleEntries.filter { entry in
            let entryStart = entry.time
            let entryEnd = entry.endTime
            return timeSlot < entryEnd && timeSlot.addingTimeInterval(slotDuration) > entryStart
        }
    }
    
    func entriesStartingInTimeSlot(_ timeSlot: Date) -> [ScheduleEntry] {
        return scheduleEntries.filter { entry in
            let entryStart = entry.time
            let slotEnd = timeSlot.addingTimeInterval(slotDuration)
            
            // Entry starts within this time slot
            return entryStart >= timeSlot && entryStart < slotEnd
        }
    }
    
    // MARK: - Schedule Entry CRUD Operations
    
    func startCreatingEntry(at timeSlot: Date) {
        selectedTimeSlot = timeSlot
        entryStartTime = timeSlot
        entryEndTime = timeSlot.addingTimeInterval(3600) // Default 1 hour
        entryTitle = ""
        entryColor = "#A3BFCB"
        entryNotes = ""
        isCreatingEntry = true
    }
    
    func startEditingEntry(_ entry: ScheduleEntry) {
        editingEntry = entry
        entryTitle = entry.taskDescription
        entryStartTime = entry.time
        entryEndTime = entry.endTime
        entryColor = entry.color
        entryNotes = "" // Add notes field to ScheduleEntry model if needed
        isEditingEntry = true
    }
    
    func saveScheduleEntry() {
        guard !entryTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              let dailyEntry = currentEntry else { 
            print("❌ Save failed: empty title or no daily entry")
            return 
        }
        
        print("💾 Saving schedule entry:")
        print("  - Title: \(entryTitle)")
        print("  - Start: \(entryStartTime)")
        print("  - End: \(entryEndTime)")
        
        if isEditingEntry, let entry = editingEntry {
            // Update existing entry
            entry.taskDescription = entryTitle.trimmingCharacters(in: .whitespacesAndNewlines)
            entry.time = entryStartTime
            entry.endTime = entryEndTime
            entry.color = entryColor
            print("  - Updated existing entry")
        } else {
            // Create new entry
            let newEntry = ScheduleEntry(
                time: entryStartTime,
                endTime: entryEndTime,
                description: entryTitle.trimmingCharacters(in: .whitespacesAndNewlines),
                color: entryColor
            )
            
            // Set up bidirectional relationship
            newEntry.dailyEntry = dailyEntry
            dailyEntry.scheduleEntries.append(newEntry)
            modelContext.insert(newEntry)
            
            print("  - Created new entry and saved")
        }
        
        saveContext()
        loadTodaysScheduleEntries()
        cancelEntryEditing()
    }
    
    func deleteScheduleEntry(_ entry: ScheduleEntry) {
        modelContext.delete(entry)
        saveContext()
        loadTodaysScheduleEntries()
    }
    
    func cancelEntryEditing() {
        isCreatingEntry = false
        isEditingEntry = false
        editingEntry = nil
        selectedTimeSlot = nil
        entryTitle = ""
        entryNotes = ""
    }
    
    // MARK: - Helper Methods
    
    private func saveContext() {
        do {
            try modelContext.save()
            print("✅ Context saved successfully")
        } catch {
            print("❌ Failed to save context: \(error)")
        }
    }
    
    func formattedTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    func formattedTimeRange(start: Date, duration: TimeInterval) -> String {
        let end = start.addingTimeInterval(duration)
        return "\(formattedTime(start)) - \(formattedTime(end))"
    }
    
    // MARK: - Computed Properties
    
    var currentTimePosition: CGFloat {
        let now = Date()
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: now)
        
        guard let startTime = calendar.date(bySettingHour: startHour, minute: 0, second: 0, of: startOfDay),
              let endTime = calendar.date(bySettingHour: endHour + 1, minute: 0, second: 0, of: startOfDay) else {
            return 0
        }
        
        let totalDuration = endTime.timeIntervalSince(startTime)
        let currentDuration = now.timeIntervalSince(startTime)
        
        return CGFloat(currentDuration / totalDuration)
    }
    
    var isWithinScheduleHours: Bool {
        let now = Date()
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: now)
        return hour >= startHour && hour <= endHour
    }
} 