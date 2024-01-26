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
                // Display today's log
                if let todayLog = viewModel.todayLog {
                    let detailView = DetailView(viewModel: DetailViewModel(dataStore: viewModel.dataStore, pedometerDataProvider: viewModel.dataStore.pedometerManager, date: Date(), weeklyAvg: viewModel.weeklyAverageSteps, liveDataManager: viewModel.liveDataManager))
                    NavigationLink(destination: detailView) {
                        DayCardView(liveDataManager: viewModel.liveDataManager, log: todayLog)
                    }
                }

                // Display historical logs
                ForEach(viewModel.stepDataList, id: \.self) { log in
                    let detailView = DetailView(viewModel: DetailViewModel(dataStore: viewModel.dataStore, pedometerDataProvider: viewModel.dataStore.pedometerManager, date: log.date ?? Date(), weeklyAvg: viewModel.weeklyAverageSteps, liveDataManager: viewModel.liveDataManager))
                    NavigationLink(destination: detailView) {
                        DayCardView(log: log)
                    }
                }
            }
            .navigationBarTitle("mySteps")
        }
    }
}

