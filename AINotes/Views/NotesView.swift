//
//  NotesView.swift
//  AINotes
//
//  Created by AI Assistant on 5/23/25.
//

import SwiftUI
import SwiftData

struct NotesView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: NotesViewModel?
    @State private var isShowingQuickCapture = false
    @FocusState private var isEditorFocused: Bool
    
    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                ScrollView {
                    LazyVStack(spacing: 0) {
                        if let viewModel = viewModel {
                            // Header Section
                            headerSection(viewModel)
                            
                            // Notes Editor Section
                            notesEditorSection(viewModel: viewModel, geometry: geometry)
                            
                            // Quick Capture Section
                            quickCaptureSection(viewModel)
                        } else {
                            ProgressView("Loading notes...")
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        }
                    }
                    .padding(.bottom, BrainDumpTheme.largePadding)
                }
            }
        }
        .background(BrainDumpTheme.backgroundColor)
        .navigationTitle("Notes")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if viewModel == nil {
                viewModel = NotesViewModel(modelContext: modelContext)
            } else {
                // Refresh data when view appears
                viewModel?.loadTodaysNotes()
            }
        }
    }
    
    // MARK: - Header Section
    private func headerSection(_ viewModel: NotesViewModel) -> some View {
        VStack(spacing: BrainDumpTheme.smallPadding) {
            Text("Daily Notes 📝")
                .font(BrainDumpTheme.titleFont)
                .foregroundColor(BrainDumpTheme.textColor)
                .fontWeight(.medium)
            
            Text(Date().formatted(.dateTime.weekday(.wide).month().day()))
                .font(BrainDumpTheme.captionFont)
                .foregroundColor(BrainDumpTheme.textColor.opacity(0.7))
            
            Text("Capture your thoughts, ideas, and insights")
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
    
    // MARK: - Notes Editor Section
    private func notesEditorSection(viewModel: NotesViewModel, geometry: GeometryProxy) -> some View {
        VStack(alignment: .leading, spacing: BrainDumpTheme.smallPadding) {
            // Section Header
            HStack {
                Image(systemName: "doc.text")
                    .foregroundColor(BrainDumpTheme.accentColor)
                    .font(.system(size: 18, weight: .medium))
                
                Text("Free-form Notes")
                    .font(BrainDumpTheme.headlineFont)
                    .foregroundColor(BrainDumpTheme.textColor)
                    .fontWeight(.medium)
                
                Spacer()
                
                // Character count
                Text("\(viewModel.notes.count) characters")
                    .font(BrainDumpTheme.captionFont)
                    .foregroundColor(BrainDumpTheme.textColor.opacity(0.6))
            }
            .padding(.horizontal, BrainDumpTheme.standardPadding)
            
            // Text Editor
            VStack(alignment: .leading, spacing: BrainDumpTheme.tinyPadding) {
                TextEditor(text: Binding(
                    get: { viewModel.notes },
                    set: { newValue in
                        viewModel.notes = newValue
                        viewModel.scheduleAutoSave()
                    }
                ))
                .focused($isEditorFocused)
                .font(BrainDumpTheme.bodyFont)
                .foregroundColor(BrainDumpTheme.textColor)
                .background(Color.clear)
                .scrollContentBackground(.hidden)
                .padding(BrainDumpTheme.standardPadding)
                .background(BrainDumpTheme.cardBackgroundColor)
                .cornerRadius(BrainDumpTheme.cornerRadius)
                .overlay(
                    // Placeholder text when empty
                    Group {
                        if viewModel.notes.isEmpty && !isEditorFocused {
                            VStack {
                                HStack {
                                    Text("Start typing your notes here...\n\nCapture thoughts, ideas, meeting notes, or anything that comes to mind. Your notes are automatically saved.")
                                        .font(BrainDumpTheme.bodyFont)
                                        .foregroundColor(BrainDumpTheme.textColor.opacity(0.5))
                                        .padding(BrainDumpTheme.standardPadding)
                                    Spacer()
                                }
                                Spacer()
                            }
                            .allowsHitTesting(false)
                        }
                    }
                )
                .frame(minHeight: 200)
                .onTapGesture {
                    isEditorFocused = true
                }
                
                // Auto-save indicator
                if viewModel.isAutoSaving {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Auto-saving...")
                            .font(BrainDumpTheme.captionFont)
                            .foregroundColor(BrainDumpTheme.textColor.opacity(0.6))
                    }
                    .padding(.horizontal, BrainDumpTheme.standardPadding)
                }
            }
        }
        .padding(.horizontal, BrainDumpTheme.standardPadding)
        .padding(.vertical, BrainDumpTheme.smallPadding)
    }
    
    // MARK: - Quick Capture Section
    private func quickCaptureSection(_ viewModel: NotesViewModel) -> some View {
        VStack(spacing: BrainDumpTheme.smallPadding) {
            HStack {
                Image(systemName: "bolt.fill")
                    .foregroundColor(BrainDumpTheme.actionColor)
                    .font(.system(size: 16, weight: .medium))
                
                Text("Quick Capture")
                    .font(BrainDumpTheme.headlineFont)
                    .foregroundColor(BrainDumpTheme.textColor)
                    .fontWeight(.medium)
                
                Spacer()
            }
            .padding(.horizontal, BrainDumpTheme.standardPadding)
            
            Button(action: {
                viewModel.quickCapture()
                isEditorFocused = true
            }) {
                HStack(spacing: BrainDumpTheme.smallPadding) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 20, weight: .medium))
                    
                    Text("Add Quick Note")
                        .font(BrainDumpTheme.bodyFont)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .medium))
                        .opacity(0.6)
                }
                .foregroundColor(BrainDumpTheme.actionColor)
                .padding(BrainDumpTheme.standardPadding)
                .background(
                    RoundedRectangle(cornerRadius: BrainDumpTheme.cornerRadius)
                        .fill(BrainDumpTheme.actionColor.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: BrainDumpTheme.cornerRadius)
                                .stroke(BrainDumpTheme.actionColor.opacity(0.3), lineWidth: 1)
                        )
                )
            }
            .buttonStyle(PlainButtonStyle())
            .padding(.horizontal, BrainDumpTheme.standardPadding)
        }
        .padding(.vertical, BrainDumpTheme.smallPadding)
    }
}

// MARK: - Preview
#Preview {
    NotesView()
        .modelContainer(for: [DailyEntry.self])
} 