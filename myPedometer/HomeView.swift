//
//  HomeView.swift
//  myPedometer
//
//  Created by Sam Roman on 1/24/24.
//
import SwiftUI
struct HomeView: View {
    @ObservedObject var viewModel: StepDataViewModel
    
    @State var dailyGoalViewIsPresented: Bool = false
    
    var body: some View {
        NavigationView {
            VStack {
                HStack {
                    Spacer()
                    Button(action: {
                        dailyGoalViewIsPresented.toggle() // Toggle the State variable to show/hide the pop-up
                    }) {
                        Text("Set Daily Goal: \n \(viewModel.dailyGoal)")
                        Image(systemName: viewModel.isGoalMet ? "flag.checkered.circle.fill" : "flag.checkered.circle") // Use "flag.fill" when the goal is met, "flag" otherwise
                    }
                }
                List {
                    ForEach(viewModel.stepDataList, id: \.self) { log in
                        NavigationLink(destination: Group {
                            // Check if the provider conforms to both PedometerDataProvider and PedometerDataObservable
                            if let pedometerManager = viewModel.pedometerDataProvider as? PedometerManager {
                                LazyView { DetailView(viewModel: DetailViewModel(pedometerDataProvider: pedometerManager, date: log.date ?? Date(), weeklyAvg: viewModel.weeklyAverageSteps), log: log.date != viewModel.todayLog?.date ? viewModel.todayLog! : log) }
                            } else {
                                // Handle the case where the provider is not a PedometerManager (e.g., a mock provider)
                                Text("Details not available")
                            }
                        }) {
                            if log.date != viewModel.todayLog?.date {
                                DayCardView(log: log, isToday: false)
                            } else {
                                DayCardView(log: viewModel.todayLog!, isToday: true)
                            }
                        }
                    }
                }
                .navigationBarTitle("mySteps")
                .sheet(isPresented: $dailyGoalViewIsPresented) {
                    // Present the DailyGoalView as a pop-up sheet
                    DailyGoalView(viewModel: viewModel)
                }
            }
        }
    }
}

struct DailyGoalView: View {
    @ObservedObject var viewModel: StepDataViewModel
    @State private var newGoal: String = ""
    
    var body: some View {
        VStack {
            Spacer()
            Text("\(viewModel.dailyGoal)")
                .font(.title)
            Image(systemName: "flag.fill") // Use "flag.fill" to represent a filled flag
                .resizable()
                .frame(width: 100, height: 100)
                .foregroundColor(viewModel.isGoalMet ? .green : .gray) // Change the flag color based on the goal status
            Text(viewModel.isGoalMet ? "Goal Met! 🎉" : "Goal Not Met 😔")
                .font(.headline)
                .foregroundColor(viewModel.isGoalMet ? .green : .red) // Change text color based on the goal status
            Spacer()
            
            Text("Set your daily goal here")
                .font(.title3)
                .padding()
            TextField("Enter your daily goal", text: $newGoal)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(.numberPad)
                .padding()
            
            Button(action: {
                if let goal = Int(newGoal) {
                    viewModel.pedometerDataProvider.storeDailyGoal(goal)
                }
                
            }) {
                Text("Confirm")
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            Spacer()
        }
    }
}

struct LazyView<Content: View>: View {
    let build: () -> Content
    var body: some View {
        build()
    }
}
