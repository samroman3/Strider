//
//  PendingChallengesView.swift
//  myPedometer
//
//  Created by Sam Roman on 3/24/24.
//

import SwiftUI

struct PendingChallengesView: View {
    @EnvironmentObject var challengeViewModel: ChallengeViewModel
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Pending Challenges")
                .font(.headline)
                .padding(.leading)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach($challengeViewModel.pendingChallenges) { challenge in
                        PendingChallengeRow(challenge: challenge, userRecord: (challengeViewModel.userSettingsManager.user?.recordId)!, onDeny: { challengeViewModel.declineChallenge(challenge.wrappedValue) }, onAccept: {challengeViewModel.acceptChallenge(challenge.wrappedValue)})
                    }
                }
            }
        }
    }
}

struct PendingChallengeRow: View {
    @Binding var challenge: ChallengeDetails
    var userRecord: String
    var onDeny: () -> Void
    var onAccept: () -> Void
    var isCreator: Bool {
        return challenge.participants[0].id == userRecord
       }
    
    var body: some View {
        VStack {
            Text("Goal: \(challenge.goalSteps)")
                .padding()
            
            HStack {
                if !isCreator {
                    Button(action: {
                        onAccept()
                    }) {
                        Text("Accept" )
                            .padding()
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                }
                Button(action: {
                        onDeny()
                    }) {
                        Text(isCreator ? "Cancel" : "Decline")
                            .padding()
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                    .padding(.horizontal)
            }
        }
        .frame(width: 200, height: 150)
        .background(AppTheme.darkerGray)
        .cornerRadius(8)
        .padding()
    }
}

#Preview {
    PendingChallengesView()
}
