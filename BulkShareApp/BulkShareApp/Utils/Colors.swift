//
//  Colors.swift
//  BulkShareApp
//
//  Created on BulkShare Project
//

import SwiftUI

extension Color {
    // MARK: - BulkShare Color Scheme
    
    // Primary Colors
    static let bulkSharePrimary = Color(hex: "4CAF50")      // Green
    static let bulkShareSecondary = Color(hex: "45a049")    // Dark Green
    
    // Background Colors
    static let bulkShareBackground = Color(hex: "f8f9fa")   // Light Gray
    
    // Text Colors
    static let bulkShareTextDark = Color(hex: "333333")     // Dark
    static let bulkShareTextMedium = Color(hex: "666666")   // Medium
    static let bulkShareTextLight = Color(hex: "999999")    // Light
    
    // Additional UI Colors
    static let bulkShareSuccess = Color(hex: "28a745")
    static let bulkShareWarning = Color(hex: "ffc107")
    static let bulkShareError = Color(hex: "dc3545")
    static let bulkShareInfo = Color(hex: "17a2b8")
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
