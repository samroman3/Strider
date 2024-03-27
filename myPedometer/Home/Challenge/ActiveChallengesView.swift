//
//  ActiveChallengesView.swift
//  myPedometer
//
//  Created by Sam Roman on 3/24/24.
//

import SwiftUI

struct ActiveChallengesView: View {
    @EnvironmentObject var challengeViewModel: ChallengeViewModel
    var body: some View {
        VStack(alignment: .leading) {
            Text("Active Challenges")
                .font(.headline)
                .padding(.leading)
            ScrollView(.horizontal, showsIndicators: false) {
                if $challengeViewModel.activeChallenges.isEmpty {
                    Text("No Active Challenges")
                        .font(.subheadline)
                        .padding(.leading)
                        .foregroundStyle(.gray)
                }
                HStack {
                    ForEach($challengeViewModel.activeChallenges) { challenge in
                        ActiveChallengeRow(challenge: challenge.wrappedValue)
                    }
                }
            }
        }
    }
}

struct ActiveChallengeRow: View {
    var challenge: ChallengeDetails
    
    var body: some View {
        NavigationLink(destination: LiveChallengeView(challengeDetails: challenge)) {
            VStack {
                Spacer()
                HStack {
                    let leadingParticipantID = challenge.participants.max(by: { $0.steps < $1.steps })?.id
                    ForEach(challenge.participants, id: \.id) { participant in
                        VStack {
                            ZStack{
                                Circle()
                                    .frame(width: 50, height: 50)
                                    .overlay(
                                        Image(uiImage: UIImage(data: participant.photoData ?? Data()) ?? UIImage())
                                            .resizable()
                                            .scaledToFill()
                                    )
                                    .clipShape(Circle())
                                    .padding(4)

                                // Highlight the current winner with a ring
                                if participant.id == leadingParticipantID {
                                    Circle().stroke(Color.yellow, lineWidth: 3)
                                        .frame(width: 58, height: 58)
                                    }
                            }
                            Text(participant.userName ?? "Unknown")
                            Text("\(participant.steps) steps")
                        }
                    }
                }
                Spacer()
                Text("Goal: \(challenge.goalSteps)")
                    .padding()
            }
            .frame(width: 200, height: 250)
            .background(Color.gray.opacity(0.2))
            .cornerRadius(8)
            .padding()
        }
        .buttonStyle(PlainButtonStyle())
    }
}
