//
//  PastChallengesView.swift
//  myPedometer
//
//  Created by Sam Roman on 3/24/24.
//

import SwiftUI

struct PastChallengesView: View {
    var pastChallenges: [DummyChallenge] = []

    var body: some View {
        VStack(alignment: .leading) {
            Text("Past")
                .font(.headline)
                .padding(.leading)
            
            ScrollView(.horizontal, showsIndicators: false) {
                if pastChallenges.isEmpty {
                    Text("No Past Challenges")
                        .font(.subheadline)
                        .padding(.leading)
                        .foregroundStyle(.gray)
                } else {
                    HStack {
                        ForEach(pastChallenges) { challenge in
                            PastChallengeRow(challenge: challenge)
                        }
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
