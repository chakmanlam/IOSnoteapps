//
//  BrainDumpTheme.swift
//  Brain Dump
//
//  Created by Chak Man Lam on 5/22/25.
//

import SwiftUI

// MARK: - BrainDumpTheme Constants
struct BrainDumpTheme {
    // MARK: - Color Palette
    static let textColor = Color.primary
    static let backgroundColor = Color(.systemBackground)
    static let cardBackgroundColor = Color(.systemGroupedBackground)
    static let surfaceColor = Color(.secondarySystemGroupedBackground)
    static let actionColor = Color.red
    static let sageColor = Color(red: 0.4, green: 0.6, blue: 0.5)
    static let accentColor = Color.blue
    
    // MARK: - Typography
    static let largeFont = Font.system(size: 34, weight: .bold, design: .rounded)
    static let titleFont = Font.system(size: 28, weight: .bold, design: .rounded)
    static let subheadingFont = Font.system(size: 20, weight: .semibold, design: .rounded)
    static let headlineFont = Font.system(size: 18, weight: .semibold, design: .rounded)
    static let bodyFont = Font.system(size: 16, weight: .regular, design: .rounded)
    static let smallBodyFont = Font.system(size: 15, weight: .regular, design: .rounded)
    static let captionFont = Font.system(size: 14, weight: .regular, design: .rounded)
    static let smallFont = Font.system(size: 12, weight: .regular, design: .rounded)
    
    // MARK: - Spacing
    static let tinyPadding: CGFloat = 4
    static let smallPadding: CGFloat = 8
    static let standardPadding: CGFloat = 16
    static let largePadding: CGFloat = 24
    static let extraLargePadding: CGFloat = 32
    
    // MARK: - Corner Radius
    static let smallCornerRadius: CGFloat = 6
    static let cornerRadius: CGFloat = 12
    static let largeCornerRadius: CGFloat = 16
    static let extraLargeCornerRadius: CGFloat = 20
    
    // MARK: - Shadow
    static let shadowRadius: CGFloat = 8
    static let shadowOffset = CGSize(width: 0, height: 4)
    static let shadowOpacity: Double = 0.1
}

// MARK: - View Extensions
extension View {
    func brainDumpCardStyle() -> some View {
        self
            .padding(BrainDumpTheme.standardPadding)
            .background(
                RoundedRectangle(cornerRadius: BrainDumpTheme.largeCornerRadius)
                    .fill(BrainDumpTheme.cardBackgroundColor)
                    .shadow(
                        color: BrainDumpTheme.textColor.opacity(0.08),
                        radius: 6,
                        x: 0,
                        y: 3
                    )
            )
    }
    
    func brainDumpButtonStyle() -> some View {
        self
            .font(BrainDumpTheme.bodyFont)
            .foregroundColor(.white)
            .padding(.horizontal, BrainDumpTheme.standardPadding)
            .padding(.vertical, BrainDumpTheme.smallPadding)
            .background(BrainDumpTheme.accentColor)
            .cornerRadius(BrainDumpTheme.cornerRadius)
    }
    
    func brainDumpSecondaryButtonStyle() -> some View {
        self
            .font(BrainDumpTheme.bodyFont)
            .foregroundColor(BrainDumpTheme.accentColor)
            .padding(.horizontal, BrainDumpTheme.standardPadding)
            .padding(.vertical, BrainDumpTheme.smallPadding)
            .background(
                RoundedRectangle(cornerRadius: BrainDumpTheme.cornerRadius)
                    .stroke(BrainDumpTheme.accentColor, lineWidth: 1)
            )
    }
}

// Color extension for hex support
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
} 