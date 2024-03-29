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
    
    //Gray Gradient
    static let grayMaterialGradient = LinearGradient(
        gradient: Gradient(colors: [darkGray,darkerGray]),
        startPoint: .leading,
        endPoint: .trailing
    )
    
    //Gray Gradient
    static let fullGrayMaterial = LinearGradient(
        gradient: Gradient(colors: [darkGray,darkGray]),
        startPoint: .leading,
        endPoint: .trailing
    )
    
    //Purple Gradient
    static let purpleGradient = LinearGradient(
        gradient: Gradient(colors:[Color.blue, Color.purple]),
        startPoint: .leading,
        endPoint: .trailing)
    
    
    static let darkerGray = Color(red: 28 / 255, green: 28 / 255, blue: 28 / 255)
    
    static let darkGray = Color(red: 94 / 255, green: 94 / 255, blue: 94 / 255)

}

struct AppButtonStyle: ButtonStyle {
    var backgroundColor: LinearGradient
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(.white)
            .padding()
            .background(backgroundColor)
            .cornerRadius(12)
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
    }
}


