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
    //TodayView
    @Published var todayLog: DailyLog?
    @Published var dailyStepGoal: Int
    @Published var caloriesBurned: Double = 0
    @Published var todaySteps: Int = 0
    @Published var dailyCalGoal: Int
    
    // WeekView
    @Published var stepDataList: [DailyLog] = []
    @Published var hourlyAverageSteps: [HourlySteps] = []
    @Published var weeklyAverageSteps: Int = 0
    
    
    //AwardsView
    @Published var lifeTimeSteps: Double = 0
    @Published var personalBestDate: String = ""
    
    //Steps
    @Published var threeKStepsReached: Bool = false
    @Published var fiveKStepsReached: Bool = false
    @Published var tenKStepsReached: Bool = false
    @Published var twentyKStepsReached: Bool = false
    @Published var thirtyKStepsReached: Bool = false
    @Published var fortyKStepsReached: Bool = false
    @Published var fiftyKStepsReached: Bool = false
    
    //Calories
    @Published var fiveHundredCalsReached: Bool = false
    @Published var thousandCalsReached: Bool = false
    
    
    
    // Add a property for calories burned
    
    @Published var error: UserFriendlyError?
    
    
    private var cancellables = Set<AnyCancellable>()
    
    // The pedometer data provider (either real or mock)
    var pedometerDataProvider: PedometerDataProvider & PedometerDataObservable
    
    // Initializer
    init(pedometerDataProvider: PedometerDataProvider & PedometerDataObservable) {
        self.pedometerDataProvider = pedometerDataProvider
        
        // Retrieve and set the daily goal
        self.dailyStepGoal = UserDefaultsHandler.shared.retrieveDailyStepGoal() ?? 0
        self.dailyCalGoal = UserDefaultsHandler.shared.retrieveDailyCalGoal() ?? 0
        
        //Retrieve step data from provider
        loadData(provider: pedometerDataProvider)
        
        //Setup error subscription
        self.pedometerDataProvider.errorPublisher
            .compactMap { $0 } // Filter out nil errors
            .sink { [weak self] error in
                self?.handleError(error)
            }
            .store(in: &cancellables)
        
        pedometerDataProvider.todayLogPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] value in
                guard let strongSelf = self else { return }
                
                if let todayLog = value, strongSelf.isToday(log: todayLog) {
                    strongSelf.todayLog = todayLog
                    strongSelf.todaySteps = Int(todayLog.totalSteps)
                    strongSelf.calculateCaloriesBurned()
                }
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
            DispatchQueue.main.async {
                self.stepDataList = logs
                self.calculateCaloriesBurned()
                self.calculateWeeklySteps()
            }
        }
    }
    
    //    Calculate weekly average steps
    func calculateWeeklySteps() {
        let totalSteps = stepDataList.reduce(0) { $0 + Int($1.totalSteps) }
        let averageSteps = totalSteps / max(stepDataList.count, 1)
        self.weeklyAverageSteps = averageSteps
    }
    
    // Calculate approximate calories burned
    func calculateCaloriesBurned() {
        self.caloriesBurned = Double(todaySteps) * 0.04
    }
    
    //Check if log falls in today
    func isToday(log: DailyLog) -> Bool {
        let calendar = Calendar.current
        return calendar.isDateInToday(log.date ?? Date())
    }
    
    func updatePersonalBestDate() {
        let stepBest = stepDataList.max(by: { $0.totalSteps < $1.totalSteps })
        let calorieBest = stepDataList.max(by: { $0.caloriesBurned < $1.caloriesBurned })
        
        // Assuming DailyLog has a `caloriesBurned` property. If not, you'll need to calculate or track this separately.
        // This example also assumes you have a way to compare which record is the overall best if they're not the same day.
        
        var bestRecord: DailyLog?
        
        if let stepBest = stepBest, let calorieBest = calorieBest {
            // Determine which record is the "best" based on a criteria. Here, arbitrarily choosing steps but you could choose more complex logic.
            bestRecord = stepBest.totalSteps >= calorieBest.totalSteps ? stepBest : calorieBest
        } else {
            // Fallback to whichever is not nil, if either is nil.
            bestRecord = stepBest ?? calorieBest
        }
        
        if let bestRecord = bestRecord, let date = bestRecord.date {
            // Format the date as a string. Customize the date format as needed.
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .medium // Or any other format you prefer
            dateFormatter.timeStyle = .none
            self.personalBestDate = dateFormatter.string(from: date)
        }
    }
}
