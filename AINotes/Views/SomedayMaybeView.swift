//
//  SomedayMaybeView.swift
//  Brain Dump
//
//  Created by AI Assistant on 5/23/25.
//

import SwiftUI
import SwiftData

struct SomedayMaybeView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack {
                Text("Someday/Maybe Management")
                    .font(BrainDumpTheme.titleFont)
                    .foregroundColor(BrainDumpTheme.textColor)
                
                Text("Detailed view coming soon...")
                    .font(BrainDumpTheme.bodyFont)
                    .foregroundColor(BrainDumpTheme.textColor.opacity(0.7))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(BrainDumpTheme.backgroundColor)
            .navigationTitle("Someday/Maybe")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(BrainDumpTheme.actionColor)
                }
            }
        }
    }
}

#Preview {
    SomedayMaybeView()
} 