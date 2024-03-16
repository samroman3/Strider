//
//  DailyGoalView.swift
//  myPedometer
//
//  Created by Sam Roman on 1/28/24.
//

import SwiftUI

struct DailyGoalView: View {
    @Binding var dailyStepGoal: Int
    @Binding var dailyCalGoal: Int
    @Environment(\.presentationMode) var presentationMode
    @State private var newStepGoal: String = ""
    @State private var newCalGoal: String = ""
    @State private var isUpdating: Bool = false // Tracks when the view is updating goals
    
    public init(dailyStepGoal: Binding<Int>, dailyCalGoal: Binding<Int>) {
        self._dailyStepGoal = dailyStepGoal
        self._dailyCalGoal = dailyCalGoal
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Set Daily Goals")
                .font(.largeTitle)
                .foregroundColor(.primary)
                .animation(.default)
                .transition(.slide)
                .padding(.bottom)
            
            goalInputField(iconName: "shoe", placeholder: "Step Goal", binding: $newStepGoal)
            goalInputField(iconName: "flame", placeholder: "Calorie Goal", binding: $newCalGoal, isCalorie: true)
            
            Spacer()
            
            if isUpdating {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
            } else {
                confirmButton()
            }
        }
        .onAppear {
                    // Auto-load the text fields when the view appears
                    self.newStepGoal = String(self.dailyStepGoal)
                    self.newCalGoal = String(self.dailyCalGoal)
                }
        .padding()
        .background(.clear)
        .alert(isPresented: $isUpdating) { // Simple feedback for updating
            Alert(title: Text("Updating"), message: Text("Please wait..."), dismissButton: .default(Text("OK")))
        }
    }
    
    func goalInputField(iconName: String, placeholder: String, binding: Binding<String>, isCalorie: Bool = false) -> some View {
            VStack{
                HStack{
                    Image(systemName: iconName)
                        .foregroundColor(isCalorie ? .red : .green)
                        .imageScale(.large)
                        .font(.system(size: 25))
                    Text(isCalorie ? "Calories" : "Steps")
                        .font(.title2)
                }
            TextField(placeholder, text: binding)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(.numberPad)
                .padding([.leading, .trailing, .bottom])
            
            if isCalorie {
                Button(action: autoCalculateCalorieGoal) {
                    Text("Auto Calculate Calories")
                        .font(.caption)
                }
            }
        }
    }
    
    func confirmButton() -> some View {
        Button(action: updateGoals) {
            Text("Confirm")
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
        }
        .padding(.bottom)
    }
    
    func autoCalculateCalorieGoal() {
        // Show feedback that the goal was auto-calculated
        withAnimation {
            let dailyStepGoal = self.newStepGoal
            self.dailyCalGoal = Int((Double(dailyStepGoal) ?? 1) * 0.04)
            self.newCalGoal = String(self.dailyCalGoal)
        }
    }
    
    private func updateGoals() {
        isUpdating = true // Show loading state
        if let stepGoal = Int(newStepGoal), let calGoal = Int(newCalGoal) {
            dailyStepGoal = stepGoal
            dailyCalGoal = calGoal
            UserDefaultsHandler.shared.storeDailyStepGoal(stepGoal)
            UserDefaultsHandler.shared.storeDailyCalGoal(calGoal)
        }
        isUpdating = false // Hide loading state
    }
}
