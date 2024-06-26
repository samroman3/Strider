//
//  StepDataViewModel.swift
//  myPedometer
//
//  Created by Sam Roman on 1/24/24.
//

import Foundation
import CoreMotion
import Combine

final class StepDataViewModel: ObservableObject {
    private var cloudKitManager: CloudKitManager
    private var userSettingsManager: UserSettingsManager
    
    //Today View
    @Published var todayLog: DailyLog?
    @Published var dailyStepGoal: Int
    @Published var caloriesBurned: Double = 0
    @Published var todaySteps: Int = 0
    @Published var dailyCalGoal: Int
    
    // Week View
    @Published var stepDataList: [DailyLog] = []
    @Published var hourlyAverageSteps: [HourlySteps] = []
    @Published var weeklyAverageSteps: Int = 0
    
    
    //Awards View
    @Published var lifeTimeSteps: Int = 0
    @Published var personalBestDate: String = ""
    @Published var stepsRecord: Int = 0
    @Published var calRecord: Int = 0
    
    //Steps
    @Published var fiveKStepsReached: Bool = false
    @Published var tenKStepsReached: Bool = false
    @Published var twentyKStepsReached: Bool = false
    @Published var thirtyKStepsReached: Bool = false
    @Published var fortyKStepsReached: Bool = false
    @Published var fiftyKStepsReached: Bool = false
    
    //Calories
    @Published var fiveHundredCalsReached: Bool = false
    @Published var thousandCalsReached: Bool = false
    
    @Published var error: UserFriendlyError?
    
    @Published var animatedStepCount: Int = 0
    
    private var lastRefreshDate: Date?
    
    // Method to check if we should refresh
    private func shouldRefresh() -> Bool {
        guard let lastRefreshDate = lastRefreshDate else { return true }
        return Date().timeIntervalSince(lastRefreshDate) > 30 // 30 seconds
    }
    
    // Trigger the count up animation for the step count
    private func animateStepCount(to finalValue: Int) {
        // Reset animatedStepCount to 0 for re-animation - need to only animate on first launch
        //           animatedStepCount = 0
        
        // Determine the animation duration and step increment
        let animationDuration = 1.0 // Total duration of the animation in seconds
        let animationStep = 10 // Increment by this step
        
        // Calculate time per step
        let timePerStep = animationDuration / Double(finalValue)
        
        // Use a timer to update animatedStepCount
        Timer.scheduledTimer(withTimeInterval: timePerStep, repeats: true) { timer in
            DispatchQueue.main.async {
                if self.animatedStepCount < finalValue {
                    self.animatedStepCount += animationStep
                } else {
                    timer.invalidate() // Stop the timer if we've reached the final value
                }
            }
        }
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    // The pedometer data provider (either real or mock)
    var pedometerDataProvider: PedometerDataProvider & PedometerDataObservable
    
    // Initializer
    init(pedometerDataProvider: PedometerDataProvider & PedometerDataObservable, userSettingsManager: UserSettingsManager, cloudKitManager: CloudKitManager) {
        self.userSettingsManager = userSettingsManager
        self.pedometerDataProvider = pedometerDataProvider
        self.cloudKitManager = cloudKitManager
        //Retrieve and set the daily goal
        self.dailyStepGoal = userSettingsManager.dailyStepGoal
        self.dailyCalGoal = userSettingsManager.dailyCalGoal
        
        setUpSubscriptions()
        //Retrieve step data from provider
        loadData(provider: pedometerDataProvider)
    }
    
    
    func refreshData() {
        guard shouldRefresh() else { return }
        pedometerDataProvider.loadStepData { [weak self] logs, hourlyAvg, error in
            DispatchQueue.main.async {
                self?.lastRefreshDate = Date()
                if let error = error {
                    self?.handleError(error)
                    return
                }
                guard let todayLog = logs.first(where: { self?.isToday(log: $0) ?? false }) else {
                    return
                }
                
                self?.updateDailyLogWith(log: todayLog)
            }
        }
    }
    
    private func setUpSubscriptions(){
        //Error subscription
        pedometerDataProvider.errorPublisher
            .compactMap { $0 } // Filter out nil errors
            .sink { [weak self] error in
                self?.handleError(error)
            }
            .store(in: &cancellables)
        
        //Today supscription
        pedometerDataProvider.todayLogPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] value in
                guard let strongSelf = self else { return }
                
                if let log = value {
                    strongSelf.updateDailyLogWith(log: log)
                }
            }
            .store(in: &cancellables)
        
        //Subscribe to user variables
        userSettingsManager.$dailyStepGoal
            .receive(on: DispatchQueue.main)
            .assign(to: \.dailyStepGoal, on: self)
            .store(in: &cancellables)
        
        userSettingsManager.$dailyCalGoal
            .receive(on: DispatchQueue.main)
            .assign(to: \.dailyCalGoal, on: self)
            .store(in: &cancellables)
        
        userSettingsManager.$stepsRecord
            .receive(on: DispatchQueue.main)
            .assign(to: \.stepsRecord, on: self)
            .store(in: &cancellables)
        
        userSettingsManager.$calorieRecord
            .receive(on: DispatchQueue.main)
            .assign(to: \.calRecord, on: self)
            .store(in: &cancellables)
        
        userSettingsManager.$lifetimeSteps
            .receive(on: DispatchQueue.main)
            .assign(to: \.lifeTimeSteps, on: self)
            .store(in: &cancellables)
    }
    
    // Error Handler
    private func handleError(_ error: Error) {
        self.error = UserFriendlyError(error: error) // Pass the error to the view model
    }
    
    //Load initial data
    private func loadData(provider: PedometerDataProvider & PedometerDataObservable) {
        pedometerDataProvider.loadStepData { logs, hours, error in
            if let error = error {
                self.handleError(error)
            }
            DispatchQueue.main.async {
                self.lastRefreshDate = Date()
                self.stepDataList = logs
                self.calculateCaloriesBurned()
                self.calculateWeeklySteps()
                self.checkAndUpdateMilestones()
            }
        }
    }
    
    private func checkAndUpdateMilestones() {
        // Step Milestones
        fiveKStepsReached = todaySteps >= 5_000
        tenKStepsReached = todaySteps >= 10_000
        twentyKStepsReached = todaySteps >= 20_000
        thirtyKStepsReached = todaySteps >= 30_000
        fortyKStepsReached = todaySteps >= 40_000
        fiftyKStepsReached = todaySteps >= 50_000
        
        // Calorie Milestones
        fiveHundredCalsReached = caloriesBurned >= 500
        thousandCalsReached = caloriesBurned >= 1_000
    }
    
    // Calculate weekly average steps
    private func calculateWeeklySteps() {
        let totalSteps = stepDataList.reduce(0) { $0 + Int($1.totalSteps) }
        let averageSteps = totalSteps / max(stepDataList.count, 1)
        self.weeklyAverageSteps = averageSteps
    }
    
    // Calculate approximate calories burned
    private func calculateCaloriesBurned() {
        self.caloriesBurned = Double(todaySteps) * 0.04
    }
    
    // Check if log falls in today
    func isToday(log: DailyLog) -> Bool {
        let calendar = Calendar.current
        return calendar.isDateInToday(log.date ?? Date())
    }
    
    private func updateDailyLogWith(log: DailyLog) {
        DispatchQueue.main.async { [self] in
            self.todayLog = log
            self.todaySteps = Int(log.totalSteps)
            self.animateStepCount(to: Int(log.totalSteps))
            
            self.calculateCaloriesBurned()
            self.checkAndUpdateMilestones()
            self.userSettingsManager.updateDailyLog(with: self.todaySteps, calories: Int(self.caloriesBurned), date: Date())
            self.lastRefreshDate = Date()
        }
        
        Task {
            await self.cloudKitManager.updateAllActiveChallenges(newSteps: self.todaySteps)
        }
    }
}
