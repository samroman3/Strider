//
//  PastChallengesView.swift
//  myPedometer
//
//  Created by Sam Roman on 3/24/24.
//

import SwiftUI

struct PastChallengesView: View {
    // Dummy data for previewing
    var pastChallenges: [DummyChallenge] = [
        .init(goalSteps: 10000, currentSteps: [10000, 7500], status: .completed, participants: ["User1", "User2"], winner: 0),
        .init(goalSteps: 15000, currentSteps: [14000, 15000], status: .completed, participants: ["User3", "User4"], winner: 1)
    ]
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Past")
                .font(.headline)
                .padding(.leading)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(pastChallenges) { challenge in
                        PastChallengeRow(challenge: challenge)
                    }
                }
            }
        }
    }
}

struct PastChallengeRow: View {
    var challenge: DummyChallenge
    
    var body: some View {
        VStack {
            if let winnerIndex = challenge.winner {
                ZStack {
                    ForEach(0..<challenge.participants.count, id: \.self) { index in
                        if index == winnerIndex {
                            Circle()
                                .fill(Color.green)
                                .frame(width: 60, height: 60)
                                .overlay(Text("Winner")
                                .foregroundColor(.white))
                                .zIndex(1)
                        } else {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 50, height: 50)
                                .offset(x: -20, y: 0) 
                                .zIndex(0)
                        }
                    }
                }
            }
            
            Text("Goal: \(challenge.goalSteps)")
                .foregroundColor(.white)
        }
        .frame(width: 200, height: 200)
        .background(AppTheme.darkerGray)
        .cornerRadius(8)
        .padding()
    }
}
