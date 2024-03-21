//
//  MainChallengeView.swift
//  myPedometer
//
//  Created by Sam Roman on 3/13/24.
//

import SwiftUI

struct DummyChallenge: Identifiable {
    let id = UUID()
    var goalSteps: Int
    var currentSteps: [Int]
    var status: ChallengeStatus
    var participants: [String]
    var winner: Int? 
}

enum ChallengeStatus {
    case sent, received, active, completed, denied
}

struct MainChallengeView: View {
    @EnvironmentObject var challengeViewModel: ChallengeViewModel
    @State private var showCreateChallenge = false

    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack {
                    PendingChallengesView()
                    ActiveChallengesView()
                    PastChallengesView()
                }
            }
            .navigationTitle("Challenges")
            .navigationBarItems(trailing: Button(action: {
                showCreateChallenge.toggle()
            }) {
                Image(systemName: "plus")
            })
        }.sheet(isPresented: $showCreateChallenge) {
            CreateChallengeView(challengeViewModel: _challengeViewModel)
        }
    }
}

struct PendingChallengesView: View {
    // Dummy data for previewing
    var pendingChallenges: [DummyChallenge] = [
        .init(goalSteps: 10000, currentSteps: [], status: .sent, participants: ["Alice", "Bob"]),
        .init(goalSteps: 15000, currentSteps: [], status: .received, participants: ["Charlie", "Dave"])
    ]
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Pending Challenges")
                .font(.headline)
                .padding(.leading)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(pendingChallenges) { challenge in
                        PendingChallengeRow(challenge: challenge)
                    }
                }
            }
        }
    }
}

struct PendingChallengeRow: View {
    var challenge: DummyChallenge
    
    var body: some View {
        VStack {
            Text("Goal: \(challenge.goalSteps)")
                .padding()
            
            HStack {
                if challenge.status == .sent {
                    Button("Cancel") {
                        // Implement cancellation logic
                    }
                    Button("Resend") {
                        // Implement resend logic
                    }
                } else if challenge.status == .received {
                    Button("Accept") {
                        // Implement accept logic
                    }
                    Button("Deny") {
                        // Implement deny logic
                    }
                }
            }
        }
        .frame(width: 200, height: 150)
        .background(Color.gray.opacity(0.2))
        .cornerRadius(8)
        .padding()
    }
}

struct ActiveChallengesView: View {
    // Dummy data for previewing
    var activeChallenges: [DummyChallenge] = [
        .init(goalSteps: 10000, currentSteps: [8000, 7500], status: .active, participants: ["User1", "User2"]),
        .init(goalSteps: 15000, currentSteps: [14000, 10000], status: .active, participants: ["User3", "User4"])
    ]
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Active Challenges")
                .font(.headline)
                .padding(.leading)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(activeChallenges) { challenge in
                        ActiveChallengeRow(challenge: challenge)
                    }
                }
            }
        }
    }
}

struct ActiveChallengeRow: View {
    var challenge: DummyChallenge
    
    var body: some View {
        VStack{
            HStack {
                ForEach(0..<challenge.participants.count, id: \.self) { index in
                    // Placeholder for participant profile images
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 50, height: 50)
                        .overlay(Text("\(challenge.currentSteps[index])"))
                        .padding(4)
                    
                    if index == 0 {
                        // Highlight the current user with a ring
                        Circle().stroke(Color.green, lineWidth: 2)
                            .frame(width: 58, height: 58)
                    }
                }
                
                Text("Goal: \(challenge.goalSteps)")
            }
        }
        .frame(width: 200, height: 200)
        .background(Color.gray.opacity(0.2))
        .cornerRadius(8)
        .padding()
    }
}

struct PastChallengesView: View {
    // Dummy data for previewing
    var pastChallenges: [DummyChallenge] = [
        .init(goalSteps: 10000, currentSteps: [10000, 7500], status: .completed, participants: ["User1", "User2"], winner: 0),
        .init(goalSteps: 15000, currentSteps: [14000, 15000], status: .completed, participants: ["User3", "User4"], winner: 1)
    ]
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Past Challenges")
                .font(.headline)
                .padding(.leading)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(pastChallenges) { challenge in
                        PastChallengeRow(challenge: challenge)
                    }
                }
            }
        }
    }
}

struct PastChallengeRow: View {
    var challenge: DummyChallenge
    
    var body: some View {
        VStack {
            if let winnerIndex = challenge.winner {
                ZStack {
                    ForEach(0..<challenge.participants.count, id: \.self) { index in
                        if index == winnerIndex {
                            Circle()
                                .fill(Color.green)
                                .frame(width: 60, height: 60)
                                .overlay(Text("Winner"))
                                .zIndex(1) // Ensure the winner is on top
                        } else {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 50, height: 50)
                                .offset(x: -20, y: 0) // Peek from behind the winner
                                .zIndex(0)
                        }
                    }
                }
            }
            
            Text("Goal: \(challenge.goalSteps)")
        }
        .frame(width: 200, height: 200)
        .background(Color.gray.opacity(0.2))
        .cornerRadius(8)
        .padding()
    }
}


struct CreateChallengeView: View {
    @EnvironmentObject var challengeViewModel: ChallengeViewModel
    @State private var goal: Int = 0
    @State private var endTime = Date()

    var body: some View {
        VStack {
            TextField("Enter Goal", value: $goal, formatter: NumberFormatter())
                .padding()
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(.numberPad)
                
            DatePicker("End Time", selection: $endTime, in: Date()..., displayedComponents: .date)
                .padding()
            
            Button("Create and Share") {
                // Call the ViewModel method to create and then share the challenge
                challengeViewModel.createAndShareChallenge(goal: Int32(goal), endTime: endTime)
            }
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(8)
        }
        .padding()
        .navigationTitle("Create Challenge")
    }
}

//struct InviteView: View {
//    @StateObject var challengeViewModel: ChallengeViewModel
//    @State private var searchQuery: String = ""
//
//    var body: some View {
//        VStack {
//            // UI to search for other users and send invites
//        }
//        .navigationTitle("Invite Users")
//    }
//}
//
//
//struct ChallengeView: View {
//    // Dummy data
//    let mySteps: Int = 10300
//    let theirSteps: Int = 5989
//    let goal: Int = 10000
//
//    var body: some View {
//        VStack {
//            Text("GOAL: \(goal)")
//                .font(.title2)
//                .foregroundColor(.white)
//                .padding(.top, 4)
//
//            Text("ENDS: Today @ 10 PM")
//                .foregroundColor(.gray)
//                .padding(.bottom, 30)
//
//            HStack(spacing: 0) {
//                // Bar for the other participant
//                BarGoalView(challenge: true, alignLeft: false)
//                
//                // Divider between the bars
//                Divider()
//                    .background(Color.white)
//
//                // Bar for the current user
//                BarGoalView(challenge: true, alignLeft: true)
//            }
//
//            // User info and steps
//            HStack {
//                VStack {
//                    // Other participant info and steps
//                    Text("\(mySteps)")
//                        .font(.title)
//                        .foregroundColor(.white)
//                    Text("Me")
//                        .foregroundColor(.gray)
//                }
//                Spacer()
//                VStack {
//                    // Current user info and steps
//                    Text("\(theirSteps)")
//                        .font(.title)
//                        .foregroundColor(.white)
//                    Text("Max")
//                        .foregroundColor(.gray)
//                }
//            }
//            .padding(.horizontal)
//        }
//        .background(Color.black)
//    }
//}
//
//struct PendingChallengesView: View {
//    @ObservedObject var challengeViewModel: ChallengeViewModel
//    
//    var body: some View {
//        List {
//            ForEach(challengeViewModel.pendingChallenges) { challenge in
//                PendingChallengeRow(challenge: challenge)
//                    .swipeActions {
//                        Button("Accept") {
//                            challengeViewModel.acceptChallenge(challenge)
//                        }
//                        .tint(.green)
//                        
//                        Button("Decline") {
//                            challengeViewModel.declineChallenge(challenge)
//                        }
//                        .tint(.red)
//                    }
//            }
//        }
//        .navigationTitle("Pending Challenges")
//        .onAppear {
//            challengeViewModel.loadPendingChallenges()
//        }
//    }
//}
//
//struct PendingChallengeRow: View {
//    let challenge: Challenge
//    
//    var body: some View {
//        HStack {
//            VStack(alignment: .leading) {
//                Text("Challenge")
//                    .font(.headline)
//                Text("Goal: \(challenge.goalSteps)")
//                    .font(.subheadline)
//            }
//            Spacer()
//            Text("Ends ...")
//                .font(.caption)
//        }
//    }
//}
//
//private let itemFormatter: DateFormatter = {
//    let formatter = DateFormatter()
//    formatter.dateStyle = .short
//    formatter.timeStyle = .short
//    return formatter
//}()
//
//struct ChallengeBarGoalView: View {
//    var progress: Double
//    var alignLeft: Bool
//    var layers: Int = 10 // The number of bars to display
//    
//    // Define the gradient to be used for filling the bars
//    let fillGradient = LinearGradient(
//        gradient: Gradient(colors: [.white, .blue, .purple]),
//        startPoint: .top,
//        endPoint: .bottom
//    )
//    
//    var body: some View {
//        GeometryReader { geometry in
//            let barWidth = geometry.size.width / CGFloat(layers)
//            let fillHeight = geometry.size.height * CGFloat(progress)
//            
//            ZStack(alignment: alignLeft ? .bottom : .top) {
//                ForEach(0..<layers) { layer in
//                    RoundedRectangle(cornerRadius: 4)
//                        .fill(fillGradient)
//                        .frame(width: barWidth, height: geometry.size.height / CGFloat(layers))
//                        // The bars are positioned to fill from the bottom or from the top based on alignLeft
//                        .offset(y: alignLeft ? 0 : (fillHeight - geometry.size.height / CGFloat(layers) * CGFloat(layer + 1)))
//                }
//            }
//            .frame(width: geometry.size.width, height: geometry.size.height, alignment: alignLeft ? .bottomLeading : .bottomTrailing)
//        }
//    }
//}

// Preview for the ChallengeBarGoalView
//struct ChallengeBarGoalView_Previews: PreviewProvider {
//    static var previews: some View {
//        ChallengeBarGoalView(progress: 0.5, alignLeft: true)
//            .frame(width: 100, height: 300)
//            .previewLayout(.sizeThatFits)
//    }
//}
//
//
//// Preview for the ChallengeView
//struct ChallengeView_Previews: PreviewProvider {
//    static var previews: some View {
//        ChallengeView()
//    }
//}
