//
//  SharedChallengeDetailView.swift
//  myPedometer
//
//  Created by Sam Roman on 3/19/24.
//

import SwiftUI

struct SharedChallengeDetailView: View {
    @EnvironmentObject var userSettingsManager: UserSettingsManager
    var challengeDetails: ChallengeDetails
    var onAccept: () -> Void
    var onDecline: () -> Void

    var body: some View {
        VStack {
            Text("You've been invited to a Challenge!")
                .font(.title)
                .multilineTextAlignment(.center)
                .padding()

            Text("Goal: \(challengeDetails.goalSteps) steps")
                .font(.title2)
                .padding()
                .multilineTextAlignment(.center)

            Text("Ends: \(challengeDetails.endTime, formatter: DateFormatterService.shared.shortItemFormatter())")
                .padding()

            // Display the challenge
            HStack(alignment: .center, spacing: 20) {
                // Challenger
                participantView(participant:ParticipantDetails(id: challengeDetails.creatorRecordID ?? "", userName: challengeDetails.creatorUserName, photoData: challengeDetails.creatorPhotoData, steps: challengeDetails.creatorSteps ?? 0))

                Image(systemName: "flag.2.crossed")
                    .foregroundStyle(.purple)
                    .font(.largeTitle)
                
                // Current User
                currentUserView()
            }
            .padding(.vertical)

            HStack(spacing: 10) {
                Button("Accept", action: onAccept)
                    .buttonStyle(AppButtonStyle(backgroundColor: AppTheme.purpleGradient))

                Button("Decline", action: onDecline)
                    .buttonStyle(AppButtonStyle(backgroundColor: AppTheme.fullGrayMaterial))
            }
            .padding(.top)
        }
        .padding()
        .background(Color.clear)
        .cornerRadius(20)
        .padding()
        .shadow(radius: 5)
    }
    
    @ViewBuilder
    private func participantView(participant: ParticipantDetails?) -> some View {
        VStack{
            if let participant = participant,
               let imageData = participant.photoData,
               let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 100, height: 100)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.white, lineWidth: 2))
                Text(participant.userName ?? "Unknown")
                    .font(.headline)
                    .multilineTextAlignment(.center)
            } else {
                Image(systemName: "person.fill.questionmark")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 100, height: 100)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.white, lineWidth: 2))
                Text("Unknown Strider")
                    .font(.headline)
                    .multilineTextAlignment(.center)

            }
        }
    }
    
    @ViewBuilder
    private func currentUserView() -> some View {
        VStack{
            if let imageData = userSettingsManager.user?.photoData,
               let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 100, height: 100)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.white, lineWidth: 2))
            } else {
                Image(systemName: "figure.walk.circle")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 100, height: 100)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.white, lineWidth: 2))
            }
            Text(userSettingsManager.user?.userName ?? "You")
                .font(.headline)
                .multilineTextAlignment(.center)

        }
    }
}

//
//#Preview {
//    SharedChallengeDetailView(challengeDetails: ChallengeDetails(id: "", startTime: Date(), endTime: Date(), goalSteps: 3000, status: "Active" , participants: [], recordId: ""), onAccept: {}, onDecline: {})
//}
