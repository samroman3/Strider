//
//  WeekView.swift
//  myPedometer
//
//  Created by Sam Roman on 1/24/24.
//
import SwiftUI

struct WeekView: View {
    @EnvironmentObject var viewModel: StepDataViewModel
//    @State private var dailyGoalViewIsPresented: Bool = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack {
                    todayCardView // Display the today card
                    
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: 15) {
                            dayCardList
                        }
                    }
                }
            }
        }
    }
    
    
    /// The today card displayed at the top
    private var todayCardView: some View {
        if let todayLog = viewModel.stepDataList.first(where: { viewModel.isToday(log: $0) }) {
            return AnyView(dayCardView(for: todayLog))
        } else {
            return AnyView(EmptyView())
        }
    }
    
    // MARK: - Subviews
    
    /// The list of day cards displayed in the home view
    private var dayCardList: some View {
        ForEach(viewModel.stepDataList.filter { !viewModel.isToday(log: $0) }, id: \.self) { log in
            dayCardView(for: log)
        }
    }
    
    /// View for displaying the daily goal button
//    private var dailyGoalButton: some View {
//        Button(action: { dailyGoalViewIsPresented.toggle() }) {
//            Image(systemName: "flag.checkered.circle")
//                .font(.title2)
//        }
//        .sheet(isPresented: $dailyGoalViewIsPresented) {
//            DailyGoalView(dailyGoal: $viewModel.dailyGoal)
//        }
//    }
    
    // MARK: - Helper Methods
    /// Generates a day card view for a given log
    /// - Parameter log: The `DailyLog` data to create a view for
    /// - Returns: A view representing the day cardqueu
    private func dayCardView(for log: DailyLog) -> some View {
        VStack{
            Text(log.date!, style: .date) 
                  .font(.headline)
                  .padding(.bottom, 2)
            NavigationLink(destination: DetailViewDestination(log: log)) {
                DayCardView(log: log, isToday: viewModel.isToday(log: log), dailyStepGoal: UserDefaultsHandler.shared.retrieveDailyStepGoal() ?? 0)
            }
        }.padding([.horizontal, .vertical], 20)
            .frame(minHeight: 300)
            .cornerRadius(15)
            .shadow(radius: 5)
    }
    
    /// Creates a destination view for detail view navigation
    /// - Parameter log: The `DailyLog` data for the destination view
    /// - Returns: A `DetailView` for the given log
    @ViewBuilder
    private func DetailViewDestination(log: DailyLog) -> some View {
        LazyView {
            DetailView(viewModel:
                        DetailViewModel(pedometerDataProvider: viewModel.pedometerDataProvider, date: log.date ?? Date(), weeklyAvg: viewModel.weeklyAverageSteps, averageHourlySteps: viewModel.hourlyAverageSteps))
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
