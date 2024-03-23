//
//  MainChallengeView.swift
//  myPedometer
//
//  Created by Sam Roman on 3/13/24.
//

import SwiftUI

extension Color {
    static let primaryColor = Color(red: 0.2, green: 0.6, blue: 0.9)
    static let secondaryColor = Color(red: 0.1, green: 0.4, blue: 0.7)
    static let backgroundColor = Color(red: 0.1, green: 0.1, blue: 0.1)
    static let accentColor = Color(red: 0.9, green: 0.7, blue: 0.3)
}

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
        ScrollView {
            VStack {
                Spacer()
                if !challengeViewModel.pendingChallenges.isEmpty {
                    PendingChallengesView()
                        .environmentObject(challengeViewModel)
                }
                ActiveChallengesView()
                    .environmentObject(challengeViewModel)
                    .padding(.vertical)
                PastChallengesView()
                    .padding(.vertical)
                Spacer()
            }
        }
        .navigationBarItems(trailing: Button(action: {
            showCreateChallenge.toggle()
        }) {
            Image(systemName: "plus.circle")
                .font(.title2)
                .foregroundStyle(.white)
        })
        .background(.black)
        .sheet(isPresented: $challengeViewModel.presentShareController, content: {
            CloudSharingControllerRepresentable(share: $challengeViewModel.share.wrappedValue, container: $challengeViewModel.container.wrappedValue)
        }).sheet(isPresented: $showCreateChallenge) {
            CreateChallengeView(challengeViewModel: _challengeViewModel)
        }
    }
}

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
                        PendingChallengeRow(challenge: challenge)
                    }
                }
            }
        }
    }
}

struct PendingChallengeRow: View {
    @Binding var challenge: ChallengeDetails
    
    var body: some View {
        VStack {
            Text("Goal: \(challenge.goalSteps)")
                .padding()
            
            HStack {
                
                if challenge.status == "Sent" {
                    Button(action: {
                        // Cancel logic here
                    }) {
                        Text("Cancel")
                            .padding()
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                    .padding(.horizontal)
                    Button(action: {
                        // Accept or resend logic here
                    }) {
                        Text(challenge.status == "Received" ? "Accept" : "Resend")
                            .padding()
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                }
            }
        }
        .frame(width: 200, height: 150)
        .background(AppTheme.darkerGray)
        .cornerRadius(8)
        .padding()
    }
}


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
        NavigationLink(destination: ActiveChallengeDetailView(challengeDetails: challenge)) {
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
        .buttonStyle(PlainButtonStyle()) // Removes the default button styling applied to navigation links
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
                                .overlay(Text("Winner")
                                    .foregroundColor(.white))
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
                .foregroundColor(.white)
        }
        .frame(width: 200, height: 200)
        .background(AppTheme.darkerGray)
        .cornerRadius(8)
        .padding()
    }
}


struct CreateChallengeView: View {
    @EnvironmentObject var challengeViewModel: ChallengeViewModel
    @State private var goal: Int = 0
    @State private var endTime = Date()

    var body: some View {
        VStack(spacing: 20) {
            Text("Set Up Your Challenge")
                .font(.title)
                .foregroundStyle(.white)
                .fontWeight(.bold)
                .padding(.top)

            VStack(alignment: .leading, spacing: 8) {
                Text("Goal Steps:")
                    .font(.headline)
                TextField("Enter Goal", value: $goal, formatter: NumberFormatter())
                    .padding()
                    .background(Color(UIColor.systemBackground))
                    .cornerRadius(10)
                    .shadow(radius: 2)
                    .keyboardType(.numberPad)
            }
            .padding(.horizontal)

            VStack(alignment: .leading, spacing: 8) {
                Text("End Time:")
                    .font(.headline)
                DatePicker("Select End Date", selection: $endTime, in: Date()..., displayedComponents: [.date, .hourAndMinute])
                    .datePickerStyle(GraphicalDatePickerStyle())
                    .padding()
                    .background(Color(UIColor.systemBackground))
                    .cornerRadius(10)
                    .shadow(radius: 2)
            }
            .padding(.horizontal)

            Spacer()

            Button(action: {
                challengeViewModel.createAndShareChallenge(goal: Int32(goal), endTime: endTime)
            }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Create and Share")
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding()
                .background(Color.blue)
                .cornerRadius(10)
                .shadow(radius: 2)
            }
            .padding(.bottom)
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground).edgesIgnoringSafeArea(.all))
        .navigationTitle("Create Challenge")
    }
}

struct MainChallengeView_Previews: PreviewProvider {
    static var previews: some View {
        MainChallengeView()
            .environmentObject(ChallengeViewModel())
    }
}

struct ActiveChallengeDetailView: View {
    // Dummy data
    let mySteps: Int = 10300
    let theirSteps: Int = 5989
    let goal: Int = 10000
            
    var challengeDetails: ChallengeDetails

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
                BarGoalView(challengeDetails: challengeDetails, alignLeft: false)

                // Divider between the bars
                Divider()
                    .background(Color.white)

                // Bar for the current user
                BarGoalView(challengeDetails: challengeDetails, alignLeft: true)
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
//
//// Preview for the ChallengeView
//struct ActiveChallengeView_Previews: PreviewProvider {
//    static var previews: some View {
//        ActiveChallengeView()
//    }
//}
