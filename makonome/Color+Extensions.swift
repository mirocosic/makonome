//
//  Color+Extensions.swift
//  makonome
//
//  Created by Claude on 05.07.2025.
//

import SwiftUI

extension Color {
    // Adaptive Soft Background Colors
    static let softBackground = Color("CustomSoftBackground")
    static let softCardBackground = Color("CustomSoftCardBackground")
    
    // Soft Blue - Muted blue-gray
    static let softBlue = Color(red: 0.4, green: 0.6, blue: 0.8) // Soft steel blue
    static let softBlueAccent = Color(red: 0.5, green: 0.7, blue: 0.9) // Lighter variant
    
    // Soft Green - Sage green
    static let softGreen = Color(red: 0.6, green: 0.8, blue: 0.7) // Muted sage
    static let softGreenAccent = Color(red: 0.7, green: 0.9, blue: 0.8) // Lighter variant
    
    // Soft Red - Coral/salmon
    static let softRed = Color(red: 0.9, green: 0.6, blue: 0.6) // Soft coral
    static let softRedAccent = Color(red: 1.0, green: 0.7, blue: 0.7) // Lighter variant
    
    // Soft Orange - Peach
    static let softOrange = Color(red: 0.9, green: 0.7, blue: 0.5) // Soft peach
    static let softOrangeAccent = Color(red: 1.0, green: 0.8, blue: 0.6) // Lighter variant
    
    // Soft Gray - Warmer grays
    static let softGray = Color(red: 0.6, green: 0.6, blue: 0.6) // Neutral warm gray
    static let softGrayLight = Color(red: 0.7, green: 0.7, blue: 0.7) // Lighter gray
    static let softGrayDark = Color(red: 0.4, green: 0.4, blue: 0.4) // Darker gray
    
    // Soft Yellow - For warnings/caution
    static let softYellow = Color(red: 0.9, green: 0.8, blue: 0.5) // Muted yellow
    
    // Soft Purple - Additional accent option
    static let softPurple = Color(red: 0.7, green: 0.6, blue: 0.8) // Lavender
}

// Background modifier for consistent soft backgrounds
extension View {
    func softBackground() -> some View {
        self.background(Color.softBackground)
    }
    
    func softCardBackground() -> some View {
        self.background(Color.softCardBackground)
    }
}