//
//  ActiveChallengeDetailView.swift
//  myPedometer
//
//  Created by Sam Roman on 3/24/24.
//

import SwiftUI

struct LiveChallengeView: View {
    // Dummy data TODO: Setup with live data
    let mySteps: Int = 10300
    let theirSteps: Int = 5989
    let goal: Int = 10000
            
    var challengeDetails: ChallengeDetails

    var body: some View {
        VStack {
            Text("GOAL: \(goal)")
                .font(.title2)
                .foregroundColor(.white)
                .padding(.top, 4)

            Text("ENDS: Today @ 10 PM")
                .foregroundColor(.gray)
                .padding(.bottom, 30)

            HStack(spacing: 0) {
                // Bar for the other participant
                BarGoalView(challengeDetails: challengeDetails, alignLeft: false)

                // Divider between the bars
                Divider()
                    .background(Color.white)

                // Bar for the current user
                BarGoalView(challengeDetails: challengeDetails, alignLeft: true)
            }

            // User info and steps
            HStack {
                VStack {
                    // Other participant info and steps
                    Text("\(mySteps)")
                        .font(.title)
                        .foregroundColor(.white)
                    Text("Me")
                        .foregroundColor(.gray)
                }
                Spacer()
                VStack {
                    // Current user info and steps
                    Text("\(theirSteps)")
                        .font(.title)
                        .foregroundColor(.white)
                    Text("Max")
                        .foregroundColor(.gray)
                }
            }
            .padding(.horizontal)
        }
        .background(Color.black)
    }
}
