//
//  ProgressCircleView.swift
//  myPedometer
//
//  Created by Sam Roman on 1/24/24.
//

import SwiftUI

struct ProgressCircleView: View {
    var percentage: Double
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(lineWidth: 10)
                .opacity(0.3)
                .foregroundColor(Color.blue)
            
            Circle()
                .trim(from: 0.0, to: CGFloat(min(self.percentage, 1.0)))
                .stroke(style: StrokeStyle(lineWidth: 10, lineCap: .round, lineJoin: .round))
                .foregroundColor(Color.blue)
                .rotationEffect(Angle(degrees: 270.0))
            
            Text(String(format: "%.0f%%", min(self.percentage, 1.0) * 100.0))
                .font(.title2)
                .bold()
        }
        .frame(width: 100, height: 100)
    }
}

#Preview {
    ProgressCircleView(percentage: 0.75)
}

