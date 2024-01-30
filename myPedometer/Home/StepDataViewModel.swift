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
    @Published var hourlyAverageSteps: [HourlySteps] = []
    @Published var weeklyAverageSteps: Int = 0
    @Published var todayLog: DailyLog?
    @Published var dailyGoal: Int
    @Published var error: UserFriendlyError?

    private var cancellables = Set<AnyCancellable>()
    
    // The pedometer data provider (either real or mock)
    var pedometerDataProvider: PedometerDataProvider & PedometerDataObservable
    
    // Initializer
    init(pedometerDataProvider: PedometerDataProvider & PedometerDataObservable) {
        self.pedometerDataProvider = pedometerDataProvider
    
        // Retrieve and set the daily goal
        self.dailyGoal = UserDefaultsHandler.shared.retrieveDailyGoal() ?? 0
        
        //Retrieve step data from provider
        loadData(provider: pedometerDataProvider)
        
        //Setup error subscription
        self.pedometerDataProvider.errorPublisher
                .compactMap { $0 } // Filter out nil errors
                .sink { [weak self] error in
                        self?.handleError(error)
                }
                .store(in: &cancellables)
    }
    
    // Error Handler
    private func handleError(_ error: Error) {
        self.error = UserFriendlyError(error: error) // Pass the error to the view model
    }
    
    //Load initial data
    func loadData(provider: PedometerDataProvider & PedometerDataObservable) {
        pedometerDataProvider.loadStepData { logs, hours, error in
            if let error = error {
                self.handleError(error)
            }
            self.stepDataList = logs
            self.hourlyAverageSteps = hours
            self.calculateWeeklySteps()
        }
    }
    
    //Calculate weekly average steps
   func calculateWeeklySteps() {
        let totalSteps = stepDataList.reduce(0) { $0 + Int($1.totalSteps) }
        let averageSteps = totalSteps / max(stepDataList.count, 1)
        self.weeklyAverageSteps = averageSteps
    }
    
    //Check if log falls in today
    func isToday(log: DailyLog) -> Bool {
        let calendar = Calendar.current
        return calendar.isDateInToday(log.date ?? Date())
    }
    
    
}
