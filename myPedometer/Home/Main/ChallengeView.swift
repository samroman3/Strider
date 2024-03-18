//
//  ChallengeView.swift
//  myPedometer
//
//  Created by Sam Roman on 3/13/24.
//

import SwiftUI

struct MainChallengeView: View {
    @EnvironmentObject var challengeViewModel: ChallengeViewModel
    @State private var showCreateChallenge = false

    var body: some View {
            VStack {
                if challengeViewModel.challenges.isEmpty {
                    Button(action: {
                        showCreateChallenge.toggle()
                    }) {
                        Text("Create a Challenge")
                    }
                    .sheet(isPresented: $showCreateChallenge) {
                        CreateChallengeView(challengeViewModel: challengeViewModel)
                    }
                } else {
                    List(challengeViewModel.challenges) { challenge in
                        ChallengeRowView(challenge: challenge)
                    }
                }
            }
            .onAppear {
                // Load active challenges
                challengeViewModel.loadActiveChallenges()
            }
    }
}

struct ChallengeRowView: View {
    let challenge: Challenge

    var body: some View {
        // Your challenge row UI
        Text("Challenge Details")
    }
}

struct CreateChallengeView: View {
    @StateObject var challengeViewModel: ChallengeViewModel
    @State private var participants: [User] = []
    @State private var goal: Int = 0 // Placeholder for the goal
    @State private var endTime = Date() // Placeholder for the end time

    var body: some View {
        VStack {
            // UI to add participants
            Text("Add Participants:")
                // Add UI elements to add participants, like a list or picker
                // Example:
                // ForEach(participants, id: \.id) { participant in
                //     Text(participant.name)
                // }
            
            // UI to set challenge details
            VStack {
                // Goal TextField
                TextField("Enter Goal", value: $goal, formatter: NumberFormatter())
                    .padding()
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.numberPad)
                
                // End Time DatePicker
                DatePicker("End Time", selection: $endTime, in: Date()..., displayedComponents: .date)
                    .padding()
            }
            
            // Button to create the challenge
            Button("Create") {
                createChallenge()
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(8)
        }
        .padding()
        .navigationTitle("Create Challenge")
    }
    
    private func createChallenge() {
        // Perform validation checks before creating the challenge
        guard goal > 0 else {
            // Display an alert or message for invalid goal
            return
        }
        
        // Call the ViewModel method to create the challenge
//        challengeViewModel.createChallenge(goal: goal, endTime: endTime, participants: participants)
    }
}



struct InviteView: View {
    @StateObject var challengeViewModel: ChallengeViewModel
    @State private var searchQuery: String = ""

    var body: some View {
        VStack {
            // UI to search for other users and send invites
        }
        .navigationTitle("Invite Users")
    }
}


struct ChallengeView: View {
    // Dummy data
    let mySteps: Int = 10300
    let theirSteps: Int = 5989
    let goal: Int = 10000

    var body: some View {
        VStack {
            Text("GOAL: \(goal)")
                .font(.title2)
                .foregroundColor(.white)
                .padding(.top, 4)

            Text("ENDS: Today @ 10 PM")
                .foregroundColor(.gray)
                .padding(.bottom, 30)

            HStack(spacing: 0) {
                // Bar for the other participant
                BarGoalView(challenge: true, alignLeft: false)
                
                // Divider between the bars
                Divider()
                    .background(Color.white)

                // Bar for the current user
                BarGoalView(challenge: true, alignLeft: true)
            }

            // User info and steps
            HStack {
                VStack {
                    // Other participant info and steps
                    Text("\(mySteps)")
                        .font(.title)
                        .foregroundColor(.white)
                    Text("Me")
                        .foregroundColor(.gray)
                }
                Spacer()
                VStack {
                    // Current user info and steps
                    Text("\(theirSteps)")
                        .font(.title)
                        .foregroundColor(.white)
                    Text("Max")
                        .foregroundColor(.gray)
                }
            }
            .padding(.horizontal)
        }
        .background(Color.black)
    }
}

struct PendingChallengesView: View {
    @ObservedObject var challengeViewModel: ChallengeViewModel
    
    var body: some View {
        List {
            ForEach(challengeViewModel.pendingChallenges) { challenge in
                PendingChallengeRow(challenge: challenge)
                    .swipeActions {
                        Button("Accept") {
                            challengeViewModel.acceptChallenge(challenge)
                        }
                        .tint(.green)
                        
                        Button("Decline") {
                            challengeViewModel.declineChallenge(challenge)
                        }
                        .tint(.red)
                    }
            }
        }
        .navigationTitle("Pending Challenges")
        .onAppear {
            challengeViewModel.loadPendingChallenges()
        }
    }
}

struct PendingChallengeRow: View {
    let challenge: Challenge
    
    var body: some View {
        // Simplified; adjust according to your data model and desired UI
        HStack {
            VStack(alignment: .leading) {
                Text(challenge.title) // Assuming 'title' is a property of 'Challenge'
                    .font(.headline)
                Text("Goal: \(challenge.goalSteps)")
                    .font(.subheadline)
            }
            Spacer()
            Text("Ends \(challenge.endTime, formatter: itemFormatter)")
                .font(.caption)
        }
    }
}

private let itemFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .short
    return formatter
}()

struct ChallengeBarGoalView: View {
    var progress: Double
    var alignLeft: Bool
    var layers: Int = 10 // The number of bars to display
    
    // Define the gradient to be used for filling the bars
    let fillGradient = LinearGradient(
        gradient: Gradient(colors: [.white, .blue, .purple]),
        startPoint: .top,
        endPoint: .bottom
    )
    
    var body: some View {
        GeometryReader { geometry in
            let barWidth = geometry.size.width / CGFloat(layers)
            let fillHeight = geometry.size.height * CGFloat(progress)
            
            ZStack(alignment: alignLeft ? .bottom : .top) {
                ForEach(0..<layers) { layer in
                    RoundedRectangle(cornerRadius: 4)
                        .fill(fillGradient)
                        .frame(width: barWidth, height: geometry.size.height / CGFloat(layers))
                        // The bars are positioned to fill from the bottom or from the top based on alignLeft
                        .offset(y: alignLeft ? 0 : (fillHeight - geometry.size.height / CGFloat(layers) * CGFloat(layer + 1)))
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height, alignment: alignLeft ? .bottomLeading : .bottomTrailing)
        }
    }
}

// Preview for the ChallengeBarGoalView
struct ChallengeBarGoalView_Previews: PreviewProvider {
    static var previews: some View {
        ChallengeBarGoalView(progress: 0.5, alignLeft: true)
            .frame(width: 100, height: 300)
            .previewLayout(.sizeThatFits)
    }
}


// Preview for the ChallengeView
struct ChallengeView_Previews: PreviewProvider {
    static var previews: some View {
        ChallengeView()
    }
}


