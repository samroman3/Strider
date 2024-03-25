//
//  CreateChallengeView.swift
//  myPedometer
//
//  Created by Sam Roman on 3/24/24.
//

import SwiftUI

struct CreateChallengeView: View {
    @EnvironmentObject var challengeViewModel: ChallengeViewModel
    @State private var goal: Int = 0
    @State private var endTime = Date()
        
    var body: some View {
        VStack(spacing: 10) {
            
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
                DatePicker("Select End Date and Time", selection: $endTime, in: Date()..., displayedComponents: [.date, .hourAndMinute])
                    .datePickerStyle(GraphicalDatePickerStyle())
                    .padding()
                    .background(Color(UIColor.systemBackground))
                    .cornerRadius(10)
                    .shadow(radius: 2)
            }
            .padding(.horizontal)
            
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
        .sheet(isPresented: $challengeViewModel.presentShareController, content: {
                    CustomShareView(share: $challengeViewModel.share, shareURL: $challengeViewModel.shareURL, details: $challengeViewModel.details)
        })
        .padding(.bottom)
        .background(Color(UIColor.secondarySystemBackground).edgesIgnoringSafeArea(.all))
        .navigationTitle("Create Challenge")
    }
}

