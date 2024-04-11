//
//  ActiveChallengeDetailView.swift
//  myPedometer
//
//  Created by Sam Roman on 3/24/24.
//

import SwiftUI

struct LiveChallengeView: View {
    @EnvironmentObject var challengeViewModel: ChallengeViewModel
    var challengeDetails: ChallengeDetails

    private var currentUser: ParticipantDetails? {
        challengeDetails.participants.first { $0.id == challengeViewModel.userSettingsManager.user?.recordId }
    }

    private var competitor: ParticipantDetails? {
        challengeDetails.participants.first { $0.id != challengeViewModel.userSettingsManager.user?.recordId }
    }

    var body: some View {
        VStack(spacing: 10) {
            goalSection
            
            HStack(spacing: 0) {
                // Bar for the current user
                if let currentUser = currentUser {
                    BarGoalView(challengeDetails: challengeDetails, alignLeft: false, otherParticipant: nil)
                }

                // Divider between the bars
                Divider()
                    .background(.secondary)

                // Bar for the other participant
                if let otherParticipant = competitor {
                    BarGoalView(challengeDetails: challengeDetails, alignLeft: true, otherParticipant: otherParticipant)
                }
            }
            .padding(.horizontal)

            participantInfo
        }
        .cornerRadius(20)
        .shadow(radius: 10)
        .onAppear {
            challengeViewModel.updateStepsAndInfo(for: challengeDetails)
        }
    }

    private var goalSection: some View {
        VStack {
            Text(DateFormatterService.shared.relativeTimeLeftFormatter(date: challengeDetails.endTime))
                .bold()
                .foregroundColor(AppTheme.darkGray)
            Text("Goal: \(challengeDetails.goalSteps) steps")
                .font(.headline)

            Text("Ends: \(challengeDetails.endTime, formatter: DateFormatterService.shared.shortItemFormatter())")
        }
    }

    private var participantInfo: some View {
        HStack {
            Spacer()
            participantView(participant: currentUser, label: "Me")
            Spacer()
            participantView(participant: competitor, label: competitor?.userName ?? "Competitor")
            Spacer()
        }
    }

    private func participantView(participant: ParticipantDetails?, label: String) -> some View {
        VStack {
            if let participant = participant, let image = UIImage(data: participant.photoData ?? Data()) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 60, height: 60)
                    .clipShape(Circle())
            }
            Text(label)
                .font(.title)
                .padding(.top, 2)
            Text("\(participant?.steps ?? 0)")
                .font(.headline)
            Text("steps")
                .font(.headline)
        }
    }
}
