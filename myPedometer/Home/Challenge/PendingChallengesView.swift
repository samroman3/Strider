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
                        PendingChallengeRow(challenge: challenge, userRecord: (challengeViewModel.userSettingsManager.user?.recordId)!, onCancel: { challengeViewModel.cancelChallenge(challenge.wrappedValue) }, onResend: {challengeViewModel.resendChallenge(challenge.wrappedValue)})
                    }
                }
            }
        }
    }
}

struct PendingChallengeRow: View {
    @Binding var challenge: PendingChallenge
    var userRecord: String
    var onCancel: () -> Void
    var onResend: () -> Void
    
    var body: some View {
        VStack {
            Text("Goal: \(challenge.challengeDetails.goalSteps) steps")
                .padding()
            Text("Ends: \(challenge.challengeDetails.endTime, formatter: DateFormatterService.shared.shortItemFormatter())")
            HStack {
                    Button(action: {
                        onResend()
                    }) {
                        Text("Resend")
                            .padding()
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                Button(action: {
                        onCancel()
                    }) {
                        Text("Cancel")
                            .padding()
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                    .padding(.horizontal)
            }
        }
        .frame(width: 300, height: 150)
        .background(AppTheme.darkerGray)
        .cornerRadius(8)
        .padding()
    }
}

#Preview {
    PendingChallengesView()
}
