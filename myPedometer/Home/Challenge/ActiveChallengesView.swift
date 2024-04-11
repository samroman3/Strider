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
                .padding([.leading, .top])
            if challengeViewModel.activeChallenges.isEmpty {
                Text("Tap + to start a new challenge!")
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(8)
                    .padding()
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 20) {
                        ForEach(challengeViewModel.activeChallenges, id: \.recordId) { challenge in
                            ActiveChallengeCard(challenge: challenge)
                        }
                    }
                    .padding()
                }
            }
        }
    }
}

struct ActiveChallengeCard: View {
    var challenge: ChallengeDetails
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        NavigationLink(destination: LiveChallengeView(challengeDetails: challenge)) {
            VStack {
                // Display the leading participant
                if let leadingParticipant = leadingParticipant {
                    ParticipantIconView(participant: leadingParticipant, isLeading: true)
                }
                
                // Display other participants
                ForEach(nonLeadingParticipants) { participant in
                    ParticipantIconView(participant: participant, isLeading: false)
                }
                
                Divider().padding(.vertical)
                Spacer()
                // Display challenge goal and time remaining
                HStack {
                    Text("Goal: \(challenge.goalSteps) steps")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(DateFormatterService.shared.relativeTimeLeftFormatter(date: challenge.endTime))")
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .frame(minWidth: 300, maxHeight: 250)
            .cornerRadius(12)
            .background(colorScheme == .dark ? AppTheme.darkerGray : .white)
            .cornerRadius(12)
            .shadow(radius: 2, x: 0, y: 2)
        }.tint(.primary)
    }
    
    // Compute the leading participant
    var leadingParticipant: ParticipantDetails? {
        challenge.participants.max(by: { $0.steps < $1.steps })
    }
    
    // Compute the non-leading participants
    var nonLeadingParticipants: [ParticipantDetails] {
        guard let leading = leadingParticipant else { return challenge.participants }
        return challenge.participants.filter { $0.id != leading.id }
    }
}

struct ParticipantIconView: View {
    var participant: ParticipantDetails
    var isLeading: Bool
    
    var body: some View {
        HStack {
            ZStack {
                Circle()
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(uiImage: UIImage(data: participant.photoData ?? Data()) ?? UIImage(systemName: "person.fill")!)
                            .resizable()
                            .scaledToFill()
                    )
                    .clipShape(Circle())
                    .padding(isLeading ? -3 : 0)

                if isLeading {
                    Circle().stroke(AppTheme.purpleGradient, lineWidth: 2)
                        .frame(width: 46, height: 46)
                }
            }
            .frame(width: 50, height: 50)
            Text(participant.userName ?? "Unknown")
                .font(.subheadline)
                .padding(.leading, 4)
            Spacer()
            if isLeading {
                VStack(alignment: .trailing) {
                    Text("\(participant.steps) steps")
                        .font(.headline)
                    Text("Leading")
                        .font(.caption)
                        .foregroundColor(.purple)
                }
            } else {
                Text("\(participant.steps) steps")
                    .font(.headline)
            }
        }
    }
}
