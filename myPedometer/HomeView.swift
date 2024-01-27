//
//  HomeView.swift
//  myPedometer
//
//  Created by Sam Roman on 1/24/24.
//
import SwiftUI
struct HomeView: View {
    @ObservedObject var viewModel: StepDataViewModel
    
    var body: some View {
        NavigationView {
            List {
                ForEach(viewModel.stepDataList, id: \.self) { log in
                    NavigationLink(destination: Group {
                        // Check if the provider conforms to both PedometerDataProvider and PedometerDataObservable
                        if let pedometerManager = viewModel.pedometerDataProvider as? PedometerManager {
                            LazyView { DetailView(viewModel: DetailViewModel(pedometerDataProvider: pedometerManager, date: log.date ?? Date(), weeklyAvg: viewModel.weeklyAverageSteps)) }
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
        }
    }
}

struct LazyView<Content: View>: View {
    let build: () -> Content
    var body: some View {
        build()
    }
}
