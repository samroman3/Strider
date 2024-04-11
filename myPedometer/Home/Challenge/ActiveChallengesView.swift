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
            Text("Active")
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
    // Creating dates
    var twoDaysFromNow: Date?
    var todayAtTenThirty: Date?
    var tomorrowAtTenThirty: Date?
    var body: some View {
        NavigationLink(destination: LiveChallengeView(challengeDetails: challenge)) {
            VStack {
                Spacer()
                HStack(spacing: 10) {
                    let leadingParticipantID = challenge.participants.max(by: { $0.steps < $1.steps })?.id
                    ForEach(challenge.participants, id: \.id) { participant in
                        VStack {
                            Text(participant.userName ?? "Unknown")
                                .multilineTextAlignment(.center)
                                .lineLimit(2)
                                .padding(.horizontal)
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
                                    Circle().stroke(Color.purple, lineWidth: 3)
                                        .frame(width: 58, height: 58)
                                    }
                            }
                            Text("\(participant.steps) steps")
                        }
                    }
                }
                Spacer()
                VStack{
                    Text("Goal: \(challenge.goalSteps) steps")
                    Text("\(DateFormatterService.shared.relativeTimeLeftFormatter(date: challenge.details")
                        .multilineTextAlignment(.center)
                }
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
