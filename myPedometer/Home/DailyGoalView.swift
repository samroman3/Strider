//
//  DailyGoalView.swift
//  myPedometer
//
//  Created by Sam Roman on 1/28/24.
//

import SwiftUI

struct DailyGoalView: View {
    @Binding var dailyGoal: Int
    @Environment(\.presentationMode) var presentationMode
    @State private var newGoal: String = ""
    var viewModel: StepDataViewModel

    public init(dailyGoal: Binding<Int>, viewModel: StepDataViewModel) {
        self.viewModel = viewModel
        self._dailyGoal = dailyGoal
    }

    var body: some View {
        VStack(spacing: 20) {
            // Display current daily goal
            Text("\(dailyGoal)")
                .font(.title)
                .foregroundColor(.primary)

            // Goal icon
            Image(systemName: "flag.checkered.circle")
            
            // Title for setting a new goal
            Text("Set Daily Goal")
                .font(.headline)
                .foregroundColor(.primary)
                .padding(.top)

            // Input field for new goal
            TextField("Enter your daily goal", text: $newGoal)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(.numberPad)
                .padding([.leading, .trailing, .bottom])

            // Confirm button
            Button(action: updateGoal) {
                Text("Confirm")
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding(.bottom)
        }
        .padding()
        .background(Color(.systemBackground))
    }

    // MARK: - Private Methods

    /// Updates the daily goal and closes the view
    private func updateGoal() {
        if let goal = Int(newGoal) {
            dailyGoal = goal
            viewModel.pedometerDataProvider.storeDailyGoal(goal)
            presentationMode.wrappedValue.dismiss()
        }
    }
}
