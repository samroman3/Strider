//
//  GoalStatusView.swift
//  myPedometer
//
//  Created by Sam Roman on 1/28/24.
//

import SwiftUI

enum GoalAchievementStatus {
    case achieved
    case notAchieved
}

enum GoalType {
    case calorie
    case steps
}

struct GoalStatusView: View {
    var status: GoalAchievementStatus
    var type: GoalType
    
    private var iconBaseName: String {
        switch type {
        case .calorie:
            return "flame.circle"
        case .steps:
            return "shoe.circle"
        }
    }
    
    private var icon: Image {
        Image(systemName: status == .achieved ? "\(iconBaseName).fill" : iconBaseName)
    }
    
    private var iconGradient: LinearGradient {
        switch type {
        case .calorie:
            return AppTheme.redGradient
        case .steps:
            return AppTheme.greenGradient
        }
    }
    
    var body: some View {
        VStack {
            if status == .achieved {
                icon
                    .font(.system(size: 28))
                    .foregroundStyle(.clear) // Use clear here to allow the background to show through
                    .background(iconGradient.mask(icon.font(.system(size: 28))))
            } else {
                icon
                    .font(.system(size: 28))
                    .foregroundColor(.gray) // Not achieved, so we use a gray color
            }
            
            Text(type == .calorie ? "Calorie Goal" : "Steps Goal")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(type == .calorie ? .red : .blue)
            
            Text(status == .achieved ? "Reached" : "Not Reached")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(status == .achieved ? .green : .gray)
        }
    }
}

// Preview code for SwiftUI previews
struct GoalStatusView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            GoalStatusView(status: .notAchieved, type: .calorie)
            GoalStatusView(status: .achieved, type: .calorie)
            Spacer()
            GoalStatusView(status: .notAchieved, type: .steps)
            GoalStatusView(status: .achieved, type: .steps)
        }
    }
}
