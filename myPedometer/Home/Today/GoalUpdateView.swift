//
//  GoalUpdateView.swift
//  myPedometer
//
//  Created by Sam Roman on 4/3/24.
//

import SwiftUI

struct GoalUpdateView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject private var userSettingsManager: UserSettingsManager
    @State private var editingStepGoal: String = ""
    @State private var editingCalGoal: String = ""
    
    var body: some View {
        ZStack {
            Color.clear.edgesIgnoringSafeArea(.all) // Makes background transparent
            
            VStack {
                Text("Update Goals")
                    .font(.title)
                    .padding()
                
                HStack {
                    goalInputField(iconName: "shoe", placeholder: "Step Goal", binding: $editingStepGoal)
                        .onChange(of: editingStepGoal) { _ in linkGoals(isStepGoalChanged: true) }
                    
                    Text("↔️")
                        .font(.title)
                        .padding()
                    
                    goalInputField(iconName: "flame", placeholder: "Calorie Goal", binding: $editingCalGoal)
                        .onChange(of: editingCalGoal) { _ in linkGoals(isStepGoalChanged: false) }
                }
                .padding()
                
                Button("Save", action: saveGoals)
                    .buttonStyle(AppButtonStyle(backgroundColor: AppTheme.purpleGradient))
                    .padding()
            }
            .padding()
            .background(Color(.systemBackground).opacity(0.9))
            .cornerRadius(20)
            .padding()
            .shadow(radius: 5)
        }
        .onAppear {
            // Initialize editing values
            editingStepGoal = "\(userSettingsManager.dailyStepGoal)"
            editingCalGoal = "\(userSettingsManager.dailyCalGoal)"
        }
    }
    
    func goalInputField(iconName: String, placeholder: String, binding: Binding<String>) -> some View {
        HStack {
            Image(systemName: iconName)
                .foregroundColor(.green)
            TextField(placeholder, text: binding)
                .keyboardType(.numberPad)
        }
    }
    
    func linkGoals(isStepGoalChanged: Bool) {
        if isStepGoalChanged {
            guard let stepGoal = Int(editingStepGoal) else { return }
            let calculatedCalGoal = Int(Double(stepGoal) * 0.04)
            editingCalGoal = String(calculatedCalGoal)
        } else {
            guard let calGoal = Int(editingCalGoal) else { return }
            let calculatedStepGoal = Int(Double(calGoal) / 0.04)
            editingStepGoal = String(calculatedStepGoal)
        }
    }
    
    func saveGoals() {
        if let stepGoal = Int(editingStepGoal), let calGoal = Int(editingCalGoal) {
            userSettingsManager.dailyStepGoal = stepGoal
            userSettingsManager.dailyCalGoal = calGoal
        }
        presentationMode.wrappedValue.dismiss()
    }
}


#Preview {
    GoalUpdateView()
}
