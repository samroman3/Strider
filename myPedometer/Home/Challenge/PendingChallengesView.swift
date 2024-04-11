//
//  PendingChallengesView.swift
//  myPedometer
//
//  Created by Sam Roman on 3/24/24.
//

import SwiftUI

struct PendingChallengesView: View {
    @EnvironmentObject var challengeViewModel: ChallengeViewModel
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Pending")
                .font(.headline)
                .padding([.leading, .top])
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 20) {
                    ForEach($challengeViewModel.pendingChallenges) { challenge in
                        PendingChallengeRow(challenge: challenge,
                                            userRecord: (challengeViewModel.userSettingsManager.user?.recordId)!,
                                            onCancel: { Task { await challengeViewModel.cancelChallenge(challenge.wrappedValue)}},
                                            onResend: { Task { await challengeViewModel.resendChallenge(challenge.wrappedValue)}})
                        .padding(.bottom, 5)
                    }
                }
                .padding(.leading)
            }
        }
        .padding(.bottom)
    }
}

struct PendingChallengeRow: View {
    @Binding var challenge: PendingChallenge
    @Environment(\.colorScheme) var colorScheme
    var userRecord: String
    var onCancel: () -> Void
    var onResend: () -> Void
    
    var body: some View {
        VStack(spacing: 10) {
            Text("Goal: \(challenge.challengeDetails.goalSteps) steps")
                .fontWeight(.semibold)
                .foregroundStyle(colorScheme == .dark ? .white : .black)
            Text("Ends: \(challenge.challengeDetails.endTime, formatter: DateFormatterService.shared.shortItemFormatter())")
                .foregroundStyle(colorScheme == .dark ? .white : .black)
            
            HStack(spacing: 10) {
                Button(action: {
                    HapticFeedbackProvider.impact()
                    onResend()
                }) {
                    Label("Share", systemImage: "square.and.arrow.up")
                        .foregroundStyle(.white)
                }
                .buttonStyle(AppButtonStyle(backgroundColor: AppTheme.purpleGradient))
                
                Button(action: {
                    HapticFeedbackProvider.impact()
                    onCancel()
                }) {
                    Label("Cancel", systemImage: "xmark.circle")
                        .foregroundStyle(.white)
                }
                .buttonStyle(AppButtonStyle(backgroundColor: AppTheme.fullGrayMaterial))
            }
        }
        .padding()
        .frame(width: 280, height: 140)
        .background(colorScheme == .dark ? AppTheme.darkerGray : .white)
        .cornerRadius(12)
        .shadow(radius: 2, x: 0, y: 2)
    }
}


