//
//  AppTheme.swift
//  myPedometer
//
//  Created by Sam Roman on 3/13/24.
//


import SwiftUI

class AppTheme {
    // Green Gradient
    static let greenGradient = LinearGradient(
        gradient: Gradient(colors: [Color.green, Color.blue, Color.mint]),
        startPoint: .leading,
        endPoint: .trailing
    )

    // Red Gradient
    static let redGradient = LinearGradient(
        gradient: Gradient(colors: [Color.yellow, Color.orange, Color.red]),
        startPoint: .leading,
        endPoint: .trailing
    )
    
    static let darkerGray = Color(red: 28 / 255, green: 28 / 255, blue: 28 / 255)
    
    static let darkGray = Color(red: 94 / 255, green: 94 / 255, blue: 94 / 255)

}


