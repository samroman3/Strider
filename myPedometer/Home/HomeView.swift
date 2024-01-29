//
//  HomeView.swift
//  myPedometer
//
//  Created by Sam Roman on 1/24/24.
//
import SwiftUI

struct HomeView: View {
    @ObservedObject var viewModel: StepDataViewModel
    @State private var dailyGoalViewIsPresented: Bool = false

    var body: some View {
        NavigationView {
            ScrollView {
                // List of Day Cards
                dayCardList
            }
            .navigationBarTitle("Home", displayMode: .inline)
            .navigationBarItems(trailing: dailyGoalButton)
        }
    }

    // MARK: - Subviews

    /// The list of day cards displayed in the home view
    private var dayCardList: some View {
        VStack(spacing: 15) {
            ForEach(viewModel.stepDataList, id: \.self) { log in
                dayCardView(for: log)
            }
        }
    }

    /// View for displaying the daily goal button
    private var dailyGoalButton: some View {
        Button(action: { dailyGoalViewIsPresented.toggle() }) {
            Image(systemName: "flag.checkered.circle")
                .font(.title2)
        }
        .sheet(isPresented: $dailyGoalViewIsPresented) {
            DailyGoalView(dailyGoal: $viewModel.dailyGoal, viewModel: viewModel)
        }
    }

    // MARK: - Helper Methods

    /// Generates a day card view for a given log
    /// - Parameter log: The `DailyLog` data to create a view for
    /// - Returns: A view representing the day card
    private func dayCardView(for log: DailyLog) -> some View {
        NavigationLink(destination: DetailViewDestination(log: log)) {
            DayCardView(log: log, isToday: viewModel.isToday(log: log), dailyStepGoal: viewModel.pedometerDataProvider.retrieveDailyGoal())
                .padding([.horizontal,.vertical])
                .frame(maxHeight: .infinity)
        }
    }

    /// Creates a destination view for detail view navigation
    /// - Parameter log: The `DailyLog` data for the destination view
    /// - Returns: A `DetailView` for the given log
    @ViewBuilder
    private func DetailViewDestination(log: DailyLog) -> some View {
        LazyView {
            DetailView(viewModel:
                        DetailViewModel(pedometerDataProvider: viewModel.pedometerDataProvider, date: log.date ?? Date(), weeklyAvg: viewModel.weeklyAverageSteps))
        }
    }
}

// MARK: - LazyView Definition

/// A utility view that lazily initializes its content.
struct LazyView<Content: View>: View {
    let build: () -> Content
    var body: some View {
        build()
    }
}
