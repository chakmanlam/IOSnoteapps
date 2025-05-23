import SwiftUI
import UIKit

// MARK: - Enhanced Settings View
struct EnhancedSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - Haptic Feedback
    private func provideFeedback() {
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
    }
    
    var body: some View {
        ZStack {
            // Match the main background
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.98, green: 0.97, blue: 0.95),
                    Color(red: 0.96, green: 0.94, blue: 0.91)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // App Header
                    appHeaderSection
                    
                    // Philosophy Section
                    philosophySection
                    
                    // Settings Options
                    settingsOptionsSection
                    
                    // App Information
                    appInfoSection
                    
                    Spacer(minLength: 100) // Extra space for tab bar
                }
                .padding(20)
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.large)
    }
    
    // MARK: - App Header Section
    private var appHeaderSection: some View {
        VStack(spacing: 16) {
            // App icon and name
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.1))
                        .frame(width: 80, height: 80)
                    
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 36))
                        .foregroundColor(.blue)
                }
                
                VStack(spacing: 4) {
                    Text("AINotes")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("Mental Clarity Through Subtraction")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    // MARK: - Philosophy Section
    private var philosophySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("The Subtraction Philosophy")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            Text("Brain Dump isn't about adding more to your life. It's about creating mental freedom through intentional subtraction and focused execution.")
                .font(.body)
                .foregroundColor(.secondary)
                .lineSpacing(4)
        }
        .padding(20)
        .background(Color.white.opacity(0.8))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 3)
        .shadow(color: .black.opacity(0.04), radius: 1, x: 0, y: 1)
    }
    
    // MARK: - Settings Options Section
    private var settingsOptionsSection: some View {
        VStack(spacing: 0) {
            settingsRow(
                icon: "bell",
                title: "Ritual Reminders",
                subtitle: "Gentle nudges for your daily practice",
                color: .orange
            )
            
            Divider().padding(.horizontal, 20)
            
            settingsRow(
                icon: "moon",
                title: "Focus Mode",
                subtitle: "Minimize distractions during rituals",
                color: .purple
            )
            
            Divider().padding(.horizontal, 20)
            
            settingsRow(
                icon: "chart.bar",
                title: "Progress Tracking",
                subtitle: "Monitor your mental clarity journey",
                color: .green
            )
            
            Divider().padding(.horizontal, 20)
            
            settingsRow(
                icon: "icloud",
                title: "Data & Sync",
                subtitle: "Backup and synchronization settings",
                color: .blue
            )
            
            Divider().padding(.horizontal, 20)
            
            settingsRow(
                icon: "questionmark.circle",
                title: "About Brain Dump",
                subtitle: "Learn more about the subtraction approach",
                color: .mint
            )
        }
        .background(Color.white.opacity(0.8))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 3)
        .shadow(color: .black.opacity(0.04), radius: 1, x: 0, y: 1)
    }
    
    // MARK: - App Information Section
    private var appInfoSection: some View {
        VStack(spacing: 12) {
            HStack {
                Text("App Information")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            
            VStack(spacing: 8) {
                infoRow(title: "Version", value: "1.0.0")
                infoRow(title: "Build", value: "2025.1")
                infoRow(title: "iOS Version", value: "18.0+")
            }
        }
    }
    
    // MARK: - Helper Views
    private func settingsRow(icon: String, title: String, subtitle: String, color: Color) -> some View {
        Button(action: {
            provideFeedback()
            // Settings action placeholder
        }) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.2))
                        .frame(width: 36, height: 36)
                    
                    Image(systemName: icon)
                        .font(.system(size: 18))
                        .foregroundColor(color)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(20)
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel("\(title). \(subtitle)")
        .accessibilityHint("Double tap to access \(title.lowercased()) settings")
    }
    
    private func infoRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.primary)
        }
    }
}

#Preview {
    NavigationStack {
        EnhancedSettingsView()
    }
} 