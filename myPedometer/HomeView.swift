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
                    NavigationLink(destination: DetailView(viewModel: DetailViewModel(pedometerDataProvider: viewModel.pedometerDataProvider, date: log.date ?? Date(), weeklyAvg: viewModel.weeklyAverageSteps))) {
                        if log.date != viewModel.todayLog?.date {
                            DayCardView(log: log, isToday: false)
                        } else {
                            DayCardView(log: log, isToday: true)
                        }
                    }
                }
            }
            .navigationBarTitle("mySteps")
        }
    }
}

