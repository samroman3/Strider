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
                List {
                    ForEach(viewModel.stepDataList, id: \.self) { log in
                        NavigationLink(destination: DetailViewDestination(log: log)) {
                            DayCardView(log: log, isToday: viewModel.isToday(log: log))
                        }
                    }
                }
                .navigationBarTitle("mySteps", displayMode: .inline)
                .navigationBarItems(trailing: dailyGoalButton)
                .sheet(isPresented: $dailyGoalViewIsPresented) {
                    DailyGoalView(dailyGoal: $viewModel.dailyGoal, viewModel: viewModel)
                }
            }
        }
    }
    
    private var dailyGoalButton: some View {
        Button(action: { dailyGoalViewIsPresented.toggle() }) {
            VStack{
                Image(systemName:"flag.checkered.circle")
                    .font(.title2)
            }
        }
    }
    
    
    @ViewBuilder
    private func DetailViewDestination(log: DailyLog) -> some View {
        LazyView {
            DetailView(viewModel:
                        DetailViewModel(pedometerDataProvider: viewModel.pedometerDataProvider, date: log.date ?? Date(), weeklyAvg: viewModel.weeklyAverageSteps))
        }
    }
}

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
            Text("\(dailyGoal)")
                .font(.title)
                .foregroundColor(.primary)

            Image(systemName: viewModel.isGoalMet ? "flag.checkered.circle.fill" : "flag.checkered.circle")
            
            Text("Set Daily Goal")
                .font(.headline)
                .foregroundColor(.primary)
                .padding(.top)

            TextField("Enter your daily goal", text: $newGoal)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(.numberPad)
                .padding([.leading, .trailing, .bottom])

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

    private func updateGoal() {
        if let goal = Int(newGoal) {
            dailyGoal = goal
            viewModel.pedometerDataProvider.storeDailyGoal(goal)
            presentationMode.wrappedValue.dismiss()
        }
    }
}

struct LazyView<Content: View>: View {
    let build: () -> Content
    var body: some View {
        build()
    }
}
