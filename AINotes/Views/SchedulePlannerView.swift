//
//  SchedulePlannerView.swift
//  AINotes
//
//  Created by AI Assistant on 5/23/25.
//

import SwiftUI
import SwiftData

struct SchedulePlannerView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: SchedulePlannerViewModel?
    @State private var showingCreateEntry = false
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                LazyVStack(spacing: 0) {
                    if let viewModel = viewModel {
                        // Header Section
                        headerSection(viewModel)
                        
                        // Time Slots Grid
                        timeSlotGrid(viewModel: viewModel, geometry: geometry)
                    } else {
                        ProgressView("Loading schedule...")
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
                .padding(.bottom, BrainDumpTheme.largePadding)
            }
        }
        .background(BrainDumpTheme.backgroundColor)
        .navigationTitle("Schedule Planner")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingCreateEntry) {
            if let viewModel = viewModel {
                ScheduleEntryFormView(viewModel: viewModel)
            }
        }
        .onAppear {
            if viewModel == nil {
                viewModel = SchedulePlannerViewModel(modelContext: modelContext)
            } else {
                // Refresh data when view appears
                viewModel?.loadTodaysScheduleEntries()
            }
        }
        .onChange(of: showingCreateEntry) { _, isShowing in
            // Refresh data when form is dismissed
            if !isShowing {
                viewModel?.loadTodaysScheduleEntries()
            }
        }
    }
    
    // MARK: - Header Section
    private func headerSection(_ viewModel: SchedulePlannerViewModel) -> some View {
        VStack(spacing: BrainDumpTheme.smallPadding) {
            Text("Schedule Planner 📅")
                .font(BrainDumpTheme.titleFont)
                .foregroundColor(BrainDumpTheme.textColor)
                .fontWeight(.medium)
            
            Text(Date().formatted(.dateTime.weekday(.wide).month().day()))
                .font(BrainDumpTheme.captionFont)
                .foregroundColor(BrainDumpTheme.textColor.opacity(0.7))
            
            Text("Plan your day with visual time blocking")
                .font(BrainDumpTheme.captionFont)
                .foregroundColor(BrainDumpTheme.accentColor)
                .italic()
                .multilineTextAlignment(.center)
                .padding(.top, BrainDumpTheme.tinyPadding)
        }
        .padding(.horizontal, BrainDumpTheme.standardPadding)
        .padding(.vertical, BrainDumpTheme.standardPadding)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    BrainDumpTheme.cardBackgroundColor,
                    BrainDumpTheme.cardBackgroundColor.opacity(0.95)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .cornerRadius(BrainDumpTheme.cornerRadius)
        .shadow(color: BrainDumpTheme.textColor.opacity(0.08), radius: 6, x: 0, y: 3)
        .padding(.horizontal, BrainDumpTheme.standardPadding)
        .padding(.vertical, BrainDumpTheme.smallPadding)
    }
    
    // MARK: - Time Slot Grid
    private func timeSlotGrid(viewModel: SchedulePlannerViewModel, geometry: GeometryProxy) -> some View {
        let timeSlots = viewModel.timeSlots()
        let slotHeight: CGFloat = 60
        let timeWidth: CGFloat = 70
        let scheduleWidth = geometry.size.width - timeWidth - BrainDumpTheme.standardPadding * 2
        
        return LazyVStack(spacing: 0) {
            ForEach(Array(timeSlots.enumerated()), id: \.offset) { index, timeSlot in
                HStack(spacing: 0) {
                    // Time Label
                    timeLabel(for: timeSlot, viewModel: viewModel)
                        .frame(width: timeWidth)
                    
                    // Schedule Area
                    scheduleSlot(
                        timeSlot: timeSlot,
                        viewModel: viewModel,
                        width: scheduleWidth,
                        height: slotHeight
                    )
                }
                .frame(height: slotHeight)
                
                // Divider line
                if index < timeSlots.count - 1 {
                    HStack(spacing: 0) {
                        Spacer()
                            .frame(width: timeWidth)
                        
                        Rectangle()
                            .fill(BrainDumpTheme.textColor.opacity(0.1))
                            .frame(height: 0.5)
                            .frame(width: scheduleWidth)
                    }
                }
            }
        }
        .padding(.horizontal, BrainDumpTheme.standardPadding)
        .background(BrainDumpTheme.cardBackgroundColor)
        .cornerRadius(BrainDumpTheme.cornerRadius)
        .shadow(color: BrainDumpTheme.textColor.opacity(0.08), radius: 4, x: 0, y: 2)
        .padding(.horizontal, BrainDumpTheme.standardPadding)
        .overlay(
            // Current time indicator
            currentTimeIndicator(
                viewModel: viewModel,
                timeSlots: timeSlots,
                slotHeight: slotHeight,
                timeWidth: timeWidth,
                scheduleWidth: scheduleWidth
            )
        )
    }
    
    // MARK: - Time Label
    private func timeLabel(for timeSlot: Date, viewModel: SchedulePlannerViewModel) -> some View {
        let isCurrentSlot = viewModel.isCurrentTimeSlot(timeSlot)
        let isOnTheHour = Calendar.current.component(.minute, from: timeSlot) == 0
        
        return VStack {
            if isOnTheHour {
                Text(viewModel.formattedTime(timeSlot))
                    .font(.system(size: 14, weight: isCurrentSlot ? .semibold : .medium))
                    .foregroundColor(
                        isCurrentSlot ? BrainDumpTheme.actionColor : BrainDumpTheme.textColor.opacity(0.8)
                    )
            } else {
                Text("")
                    .font(.system(size: 14))
            }
            Spacer()
        }
        .frame(maxHeight: .infinity)
        .padding(.trailing, BrainDumpTheme.tinyPadding)
    }
    
    // MARK: - Schedule Slot
    private func scheduleSlot(
        timeSlot: Date,
        viewModel: SchedulePlannerViewModel,
        width: CGFloat,
        height: CGFloat
    ) -> some View {
        let isCurrentSlot = viewModel.isCurrentTimeSlot(timeSlot)
        let isOccupied = viewModel.isTimeSlotOccupied(timeSlot)
        let entries = viewModel.entriesStartingInTimeSlot(timeSlot) // Only entries that START in this slot
        
        return ZStack(alignment: .leading) {
            // Background
            Rectangle()
                .fill(
                    isCurrentSlot ? 
                    BrainDumpTheme.actionColor.opacity(0.1) : 
                    BrainDumpTheme.cardBackgroundColor
                )
                .overlay(
                    Rectangle()
                        .stroke(
                            isCurrentSlot ? 
                            BrainDumpTheme.actionColor.opacity(0.3) : 
                            Color.clear,
                            lineWidth: 2
                        )
                )
            
            // Schedule entries (only those that start in this slot)
            if !entries.isEmpty {
                ForEach(Array(entries.enumerated()), id: \.offset) { index, entry in
                    scheduleEntryView(
                        entry: entry, 
                        viewModel: viewModel,
                        slotHeight: height,
                        baseTimeSlot: timeSlot
                    )
                    .offset(x: CGFloat(index * 4)) // Slight offset for overlapping entries
                }
            }
        }
        .frame(width: width, height: height)
        .contentShape(Rectangle())
        .onTapGesture {
            if !isOccupied {
                viewModel.startCreatingEntry(at: timeSlot)
                showingCreateEntry = true
            }
        }
    }
    
    // MARK: - Schedule Entry View
    private func scheduleEntryView(
        entry: ScheduleEntry,
        viewModel: SchedulePlannerViewModel,
        slotHeight: CGFloat,
        baseTimeSlot: Date
    ) -> some View {
        // Calculate how many slots this entry spans
        let entryDuration = entry.endTime.timeIntervalSince(entry.time)
        let slotsSpanned = entryDuration / viewModel.slotDuration
        let entryHeight = CGFloat(slotsSpanned) * slotHeight
        
        return HStack(spacing: BrainDumpTheme.tinyPadding) {
            // Color indicator
            RoundedRectangle(cornerRadius: 2)
                .fill(Color(hex: entry.color))
                .frame(width: 4)
            
            VStack(alignment: .leading, spacing: 2) {
                // Entry text
                Text(entry.taskDescription)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(BrainDumpTheme.textColor)
                    .lineLimit(nil) // Allow multiple lines for longer entries
                    .truncationMode(.tail)
                
                // Time range for longer entries
                if slotsSpanned > 1 {
                    Text("\(viewModel.formattedTime(entry.time)) - \(viewModel.formattedTime(entry.endTime))")
                        .font(.system(size: 10))
                        .foregroundColor(BrainDumpTheme.textColor.opacity(0.7))
                }
            }
            
            Spacer()
        }
        .padding(.horizontal, BrainDumpTheme.tinyPadding)
        .padding(.vertical, 4)
        .frame(height: entryHeight)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Color(hex: entry.color).opacity(0.15))
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color(hex: entry.color).opacity(0.4), lineWidth: 1)
                )
        )
        .onTapGesture {
            viewModel.startEditingEntry(entry)
            showingCreateEntry = true
        }
    }
    
    // MARK: - Current Time Indicator
    private func currentTimeIndicator(
        viewModel: SchedulePlannerViewModel,
        timeSlots: [Date],
        slotHeight: CGFloat,
        timeWidth: CGFloat,
        scheduleWidth: CGFloat
    ) -> some View {
        Group {
            if viewModel.isWithinScheduleHours {
                let position = calculateCurrentTimePosition(
                    viewModel: viewModel,
                    timeSlots: timeSlots,
                    slotHeight: slotHeight
                )
                
                HStack(spacing: 0) {
                    Spacer()
                        .frame(width: timeWidth)
                    
                    HStack {
                        Circle()
                            .fill(BrainDumpTheme.actionColor)
                            .frame(width: 8, height: 8)
                        
                        Rectangle()
                            .fill(BrainDumpTheme.actionColor)
                            .frame(height: 2)
                    }
                    .frame(width: scheduleWidth)
                }
                .offset(y: position)
            }
        }
    }
    
    private func calculateCurrentTimePosition(
        viewModel: SchedulePlannerViewModel,
        timeSlots: [Date],
        slotHeight: CGFloat
    ) -> CGFloat {
        let now = Date()
        
        // Find the closest time slot
        guard let firstSlot = timeSlots.first else { return 0 }
        
        // Calculate minutes since first slot
        let minutesSinceStart = now.timeIntervalSince(firstSlot) / 60
        let slotDurationInMinutes = viewModel.slotDuration / 60
        
        // Calculate position
        let slotsFromStart = minutesSinceStart / slotDurationInMinutes
        return CGFloat(slotsFromStart) * slotHeight - CGFloat(timeSlots.count) * slotHeight / 2
    }
}

// MARK: - Schedule Entry Form View
struct ScheduleEntryFormView: View {
    @Bindable var viewModel: SchedulePlannerViewModel
    @Environment(\.dismiss) private var dismiss
    
    private let predefinedColors = [
        "#A3BFCB", // Sage
        "#D1A3C7", // Accent 
        "#C7A3D1", // Action
        "#87CEEB", // Sky blue
        "#98FB98", // Pale green
        "#FFB6C1", // Light pink
        "#F0E68C", // Khaki
        "#DDA0DD", // Plum
    ]
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    TextField("Task or event", text: $viewModel.entryTitle)
                    
                    // Custom start time picker with 30-minute intervals
                    HStack {
                        Text("Start time")
                        Spacer()
                        customTimePicker(
                            selectedTime: $viewModel.entryStartTime,
                            onChange: { newTime in
                                viewModel.entryStartTime = newTime
                                // Ensure end time is at least 30 minutes after start time
                                if viewModel.entryEndTime <= viewModel.entryStartTime {
                                    viewModel.entryEndTime = viewModel.entryStartTime.addingTimeInterval(1800) // 30 minutes
                                }
                            }
                        )
                    }
                    
                    // Custom end time picker with 30-minute intervals
                    HStack {
                        Text("End time")
                        Spacer()
                        customTimePicker(
                            selectedTime: $viewModel.entryEndTime,
                            onChange: { newTime in
                                viewModel.entryEndTime = newTime
                                // Ensure end time is after start time
                                if viewModel.entryEndTime <= viewModel.entryStartTime {
                                    viewModel.entryEndTime = viewModel.entryStartTime.addingTimeInterval(1800) // 30 minutes
                                }
                            }
                        )
                    }
                }
                
                Section("Color") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4)) {
                        ForEach(predefinedColors, id: \.self) { color in
                            Circle()
                                .fill(Color(hex: color))
                                .frame(width: 40, height: 40)
                                .overlay(
                                    Circle()
                                        .stroke(
                                            viewModel.entryColor == color ? 
                                            BrainDumpTheme.textColor : Color.clear,
                                            lineWidth: 3
                                        )
                                )
                                .onTapGesture {
                                    viewModel.entryColor = color
                                }
                        }
                    }
                }
            }
            .navigationTitle(viewModel.isEditingEntry ? "Edit Entry" : "New Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        viewModel.cancelEntryEditing()
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        viewModel.saveScheduleEntry()
                        dismiss()
                    }
                    .disabled(viewModel.entryTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
    
    // MARK: - Helper Functions
    
    private func customTimePicker(selectedTime: Binding<Date>, onChange: @escaping (Date) -> Void) -> some View {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: selectedTime.wrappedValue)
        let currentHour = components.hour ?? 12
        let currentMinute = components.minute ?? 0
        
        // Round current minute to nearest 30-minute interval for display
        let displayMinute = currentMinute < 15 ? 0 : (currentMinute < 45 ? 30 : 0)
        let adjustedHour = currentMinute >= 45 ? (currentHour + 1) % 24 : currentHour
        
        return HStack {
            // Hour picker
            Picker("Hour", selection: Binding(
                get: { adjustedHour },
                set: { newHour in
                    if let newDate = calendar.date(bySettingHour: newHour, minute: displayMinute, second: 0, of: selectedTime.wrappedValue) {
                        onChange(newDate)
                    }
                }
            )) {
                ForEach(0..<24, id: \.self) { hour in
                    Text(formatHour(hour))
                        .tag(hour)
                }
            }
            .pickerStyle(.wheel)
            .frame(width: 80)
            
            Text(":")
                .font(.title2)
                .fontWeight(.medium)
            
            // Minute picker (only 00 and 30)
            Picker("Minute", selection: Binding(
                get: { displayMinute },
                set: { newMinute in
                    if let newDate = calendar.date(bySettingHour: adjustedHour, minute: newMinute, second: 0, of: selectedTime.wrappedValue) {
                        onChange(newDate)
                    }
                }
            )) {
                Text("00").tag(0)
                Text("30").tag(30)
            }
            .pickerStyle(.wheel)
            .frame(width: 60)
        }
        .frame(height: 120)
    }
    
    private func formatHour(_ hour: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h a"
        let date = Calendar.current.date(bySettingHour: hour, minute: 0, second: 0, of: Date()) ?? Date()
        return formatter.string(from: date)
    }
    
    private func roundToNearestHalfHour(_ date: Date) -> Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        
        guard let hour = components.hour, let minute = components.minute else { return date }
        
        // Round to nearest 30-minute mark
        let roundedMinute = (minute < 15) ? 0 : (minute < 45) ? 30 : 0
        let adjustedHour = (minute >= 45) ? hour + 1 : hour
        
        return calendar.date(bySettingHour: adjustedHour, minute: roundedMinute, second: 0, of: date) ?? date
    }
} 