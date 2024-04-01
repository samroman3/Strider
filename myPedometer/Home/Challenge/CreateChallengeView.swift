//
//  CreateChallengeView.swift
//  myPedometer
//
//  Created by Sam Roman on 3/24/24.
//

import SwiftUI

struct CreateChallengeView: View {
    @EnvironmentObject var challengeViewModel: ChallengeViewModel
    @State private var goal: Int = 100
    @State private var endTime = Date()
    @Binding var isPresented: Bool
    @Environment(\.colorScheme) var colorScheme
    // States for inline alert messages
    @State private var goalAlertMessage: String? = nil
    @State private var endTimeAlertMessage: String? = nil
    
    @FocusState private var isGoalTextFieldFocused: Bool

    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 10) {
                    goalSection
                    endTimeSection
                    
                    // Create Challenge Button
                    Button(action: {
                        // Clear previous alert messages
                        goalAlertMessage = nil
                        endTimeAlertMessage = nil
                        
                        // Validate and create challenge
                        if validateChallenge(endTime: endTime, goalSteps: goal) {
                            HapticFeedbackProvider.impact()
                            challengeViewModel.createAndShareChallenge(goal: Int32(goal), endTime: endTime)
                            isPresented = false
                        }
                    }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Create")
                                .font(.title)
                                .fontWeight(.bold)
                        }
                        .padding()
                        .foregroundColor(.white)
                        .background(AppTheme.purpleGradient)
                        .cornerRadius(20)
                        .shadow(radius: 2)
                    }
                }
            }
            .navigationTitle("Create Challenge")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        withAnimation(.default) {
                            isPresented = false
                        }
                    }
                }
            }
        }
    }
    
    private var goalSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "shoe")
                    .foregroundColor(.blue)
                Text("Steps Goal:")
                    .font(.headline)
            }
            HStack{
                TextField("Enter Goal", value: $goal, formatter: NumberFormatter())
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .focused($isGoalTextFieldFocused)
                    .keyboardType(.numberPad)
                    .shadow(radius: 2, x: 2)
                if isGoalTextFieldFocused {
                    Button("Done") {
                        isGoalTextFieldFocused = false
                    }.dismissKeyboardOnTap()
                }
            }
            // Inline alert for goal validation
            if let message = goalAlertMessage {
                Text(message)
                    .foregroundColor(.red)
                    .font(.caption)
            }
        }
        .padding()
    }
    
    private var endTimeSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "clock")
                    .foregroundColor(.purple)
                Text("End Time:")
                    .font(.headline)
            }
            DatePicker("Select End Date and Time", selection: $endTime, in: Date()..., displayedComponents: [.date, .hourAndMinute])
                .datePickerStyle(GraphicalDatePickerStyle())
                .background(colorScheme == .dark ? AppTheme.darkerGray : .white)
                .clipShape(.rect(cornerRadius: 10))
                .shadow(radius: 2, x: 2)
            
            // Inline alert for end time validation
            if let message = endTimeAlertMessage {
                Text(message)
                    .foregroundColor(.red)
                    .font(.caption)
            }
        }
        .padding()
    }
    
    func validateChallenge(endTime: Date, goalSteps: Int) -> Bool {
        let currentTime = Date()
        let minimumEndTime = Calendar.current.date(byAdding: .hour, value: 1, to: currentTime)!
        let minimumGoalSteps = 100
        var isValid = true

        if endTime <= minimumEndTime {
            endTimeAlertMessage = "Challenge end time must be at least an hour out from current time."
            isValid = false
        }
        if goalSteps < minimumGoalSteps {
            goalAlertMessage = "Challenge goal must be at least 100 steps."
            isValid = false
        }

        return isValid
    }
}


