//
//  Colors.swift
//  BulkMatesApp
//
//  Created on BulkMates Project
//

import SwiftUI

extension Color {
    // MARK: - BulkMates Color Scheme
    
    // Primary Colors
    static let bulkMatesPrimary = Color(hex: "4CAF50")      // Green
    static let bulkMatesSecondary = Color(hex: "45a049")    // Dark Green
    
    // Background Colors
    static let bulkMatesBackground = Color(hex: "f8f9fa")   // Light Gray
    
    // Text Colors
    static let bulkMatesTextDark = Color(hex: "333333")     // Dark
    static let bulkMatesTextMedium = Color(hex: "666666")   // Medium
    static let bulkMatesTextLight = Color(hex: "999999")    // Light
    
    // Additional UI Colors
    static let bulkMatesSuccess = Color(hex: "28a745")
    static let bulkMatesWarning = Color(hex: "ffc107")
    static let bulkMatesError = Color(hex: "dc3545")
    static let bulkMatesInfo = Color(hex: "17a2b8")
    
    // MARK: - Legacy BulkShare Colors (for backward compatibility)
    static let bulkSharePrimary = bulkMatesPrimary
    static let bulkShareSecondary = bulkMatesSecondary
    static let bulkShareBackground = bulkMatesBackground
    static let bulkShareTextDark = bulkMatesTextDark
    static let bulkShareTextMedium = bulkMatesTextMedium
    static let bulkShareTextLight = bulkMatesTextLight
    static let bulkShareSuccess = bulkMatesSuccess
    static let bulkShareWarning = bulkMatesWarning
    static let bulkShareError = bulkMatesError
    static let bulkShareInfo = bulkMatesInfo
}

// MARK: - Color Extension for Hex Support
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
