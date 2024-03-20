//
//  SharedChallengeDetailView.swift
//  myPedometer
//
//  Created by Sam Roman on 3/19/24.
//

import SwiftUI

struct SharedChallengeDetailView: View {
    var challengeDetails: ChallengeDetails
    var onAccept: () -> Void
    var onDecline: () -> Void

    var body: some View {
        VStack {
            Text("You've been invited to a Challenge!")
                .font(.headline)
                .padding()

            Text("Goal Steps: \(challengeDetails.goalSteps)")
                .padding()

            // Display participants
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(challengeDetails.participants) { participant in
                        VStack {
                            if let imageData = participant.photoData, let uiImage = UIImage(data: imageData) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 60, height: 60)
                                    .clipShape(Circle())
                            }
                            Text(participant.userName ?? "Unknown")
                        }
                    }
                }
            }

            HStack {
                Button(action: onAccept) {
                    Text("Accept")
                        .foregroundColor(.white)
                        .frame(minWidth: 0, maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .cornerRadius(10)
                }

                Button(action: onDecline) {
                    Text("Decline")
                        .foregroundColor(.white)
                        .frame(minWidth: 0, maxWidth: .infinity)
                        .padding()
                        .background(Color.red)
                        .cornerRadius(10)
                }
            }
            .padding()

            Text("Ends: \(challengeDetails.endTime, formatter: itemFormatter)")
                .padding()
        }
        .padding()
    }
}

private let itemFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .short
    return formatter
}()


#Preview {
    SharedChallengeDetailView(challengeDetails: ChallengeDetails(startTime: Date(), endTime: Date(), goalSteps: 3000, active: false, participants: [], recordId: ""), onAccept: {}, onDecline: {})
}
