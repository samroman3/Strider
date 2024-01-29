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

struct GoalStatusView: View {
    var status: GoalAchievementStatus

    var body: some View {
        VStack {
            Image(systemName: status == .achieved ? "checkmark.circle" : "xmark.circle")
                .font(.system(size: 20))
                .foregroundColor(status == .achieved ? .green : .red)
            Text(status == .achieved ? "Goal Reached" : "Goal Not Reached")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(status == .achieved ? .green : .red)
        }
    }
}

#Preview {
    //Goal Not Reached
    GoalStatusView(status: .notAchieved)
}

#Preview {
    //Goal Reached
    GoalStatusView(status: .achieved)
}
