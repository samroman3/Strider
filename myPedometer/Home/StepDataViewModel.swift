//
//  StepDataViewModel.swift
//  myPedometer
//
//  Created by Sam Roman on 1/24/24.
//

import Foundation
import CoreMotion
import Combine

class StepDataViewModel: ObservableObject {
    // Published properties to be observed by HomeView
    @Published var stepDataList: [DailyLog] = []
    @Published var weeklyAverageSteps: Int = 0
    @Published var todayLog: DailyLog?
    @Published var dailyGoal: Int
    
    // The pedometer data provider (either real or mock)
    var pedometerDataProvider: PedometerDataProvider & PedometerDataObservable

    // Storage for Combine subscribers
    private var cancellables = Set<AnyCancellable>()

    // Initializer
    init(pedometerDataProvider: PedometerDataProvider & PedometerDataObservable) {
        self.pedometerDataProvider = pedometerDataProvider
        
        // Retrieve and set the daily goal from the data provider
        self.dailyGoal = pedometerDataProvider.retrieveDailyGoal()
        
        // Initialize stepDataList directly from the data provider
        self.stepDataList = pedometerDataProvider.stepDataList
        pedometerDataProvider.stepDataListPublisher
                  .receive(on: DispatchQueue.main)
                  .assign(to: \.stepDataList, on: self)
                  .store(in: &cancellables)
        // Calculate weekly steps and check goal status
        calculateWeeklySteps()
    }

    //Calculate weekly average steps
    private func calculateWeeklySteps(){
        $stepDataList
            .map { logs in
                let totalSteps = logs.reduce(0) { $0 + Int($1.totalSteps) }
                return totalSteps / max(logs.count, 1)
            }
            .receive(on: DispatchQueue.main)
            .assign(to: \.weeklyAverageSteps, on: self)
            .store(in: &cancellables)
    }
    
    //Check if log falls in today
    func isToday(log: DailyLog) -> Bool {
        let calendar = Calendar.current
        return calendar.isDateInToday(log.date ?? Date())
    }
    

}
