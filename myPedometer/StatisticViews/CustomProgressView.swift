//
//  CustomProgressView.swift
//  myPedometer
//
//  Created by Sam Roman on 1/28/24.
//

import SwiftUI

struct CustomProgressView: View {
    var totalSteps: Int
    var dailyGoal: Int
    var barColor: Color
    
    var body: some View {
        ProgressView(value: Double(min(totalSteps, dailyGoal)), total: Double(dailyGoal))
            .progressViewStyle(LinearProgressViewStyle(tint: barColor))
        Text("Goal: \(dailyGoal) steps")
            .foregroundColor(barColor)
    }
}

#Preview {
    CustomProgressView(totalSteps: 2500, dailyGoal: 5000, barColor: .blue)
}

