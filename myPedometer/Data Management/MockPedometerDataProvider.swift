//
//  MockPedometerDataProvider.swift
//  myPedometer
//
//  Created by Sam Roman on 1/24/24.
//
import Foundation
import Combine
import CoreData

class MockPedometerDataProvider: PedometerDataProvider, PedometerDataObservable {
    
    
    
    private var context: NSManagedObjectContext
    
    @Published var todayLog: DailyLog?
    @Published var stepDataList: [DailyLog] = []
    @Published var detailData: DetailData?
    
    private var timer: Timer?
    var dailyAverageHourlySteps: [HourlySteps] = []
    
    var stepDataListPublisher: Published<[DailyLog]>.Publisher { $stepDataList }
    var todayLogPublisher: Published<DailyLog?>.Publisher { $todayLog }
    var detailDataPublisher: Published<DetailData?>.Publisher { $detailData }
    var errorPublisher = PassthroughSubject<Error, Never>()
    
    
    
    // MARK: - Properties for Simulation
    var shouldSimulateError: Bool
    
    // MARK: - Initialization
    
    init(context: NSManagedObjectContext, shouldSimulateError: Bool = false) {
        self.context = context
        self.shouldSimulateError = shouldSimulateError
        setupInitialMockData()
        loadTodayLog()
        startPedometerUpdates()
    }
    
    
    // MARK: - Setup Mock Data
    
    private func setupInitialMockData() {
        let today = Date()
        for dayBack in 0..<7 {
            if let date = Calendar.current.date(byAdding: .day, value: -dayBack, to: today) {
                createMockDailyLog(for: date)
            }
        }
        stepDataList[stepDataList.count - 1].totalSteps = Int32(10000) // Set specific step count for test
        dailyAverageHourlySteps = self.calculateHourlyAverageSteps(stepData: stepDataList)
        detailData = nil
    }
    
    
    
    func loadStepData(completion: @escaping ([DailyLog], [HourlySteps], Error?) -> Void) {
        if shouldSimulateError {
            let error = NSError(domain: "MockPedometerDataProvider", code: 1, userInfo: [NSLocalizedDescriptionKey: "Simulated error in loadStepData"])
            errorPublisher.send(error)
            completion([],[], error)
        }
        completion(self.stepDataList, self.calculateHourlyAverageSteps(stepData: stepDataList), nil)
    }
    
    
    private func createMockDailyLog(for date: Date) {
        let dailyLog = DailyLog(context: context)
        dailyLog.date = date
        dailyLog.totalSteps = Int32.random(in: 1000...10000)
        dailyLog.flightsAscended = Int32.random(in: 0...20)
        dailyLog.flightsDescended = Int32.random(in: 0...20)
        createHourlyData(for: dailyLog)
        stepDataList.append(dailyLog)
    }
    
    private func createHourlyData(for dailyLog: DailyLog) {
        for hour in 0..<24 {
            let hourlyData = HourlyStepData(context: context)
            hourlyData.hour = Int16(hour)
            hourlyData.stepCount = Int32.random(in: 100...500)
            dailyLog.addToHourlyStepData(hourlyData)
        }
    }
    
    func createMockDailyLog(for date: Date, totalSteps: Int32? = nil, flightsAscended: Int32? = nil, flightsDescended: Int32? = nil) -> DailyLog {
        let dailyLog = DailyLog(context: context)
        dailyLog.date = date
        dailyLog.totalSteps = totalSteps ?? Int32.random(in: 1000...10000)
        dailyLog.flightsAscended = flightsAscended ?? Int32.random(in: 0...20)
        dailyLog.flightsDescended = flightsDescended ?? Int32.random(in: 0...20)
        createHourlyData(for: dailyLog)
        return dailyLog
    }
    
    func fetchDetailData(for date: Date) {
        if shouldSimulateError {
            let error = NSError(domain: "MockPedometerDataProvider", code: 1, userInfo: [NSLocalizedDescriptionKey: "Simulated error in fetchDetailData"])
            self.errorPublisher.send(error)
            return
        }
        
        let log = stepDataList.first { $0.date == date }
        let hourlySteps = (log?.hourlyStepData?.allObjects as? [HourlyStepData])?.sorted(by: { $0.hour < $1.hour }).map { HourlySteps(hour: Int($0.hour), steps: Int($0.stepCount)) } ?? []
        let dailyGoal = UserDefaultsHandler.shared.retrieveDailyGoal() ?? 0
        let newDetailData = DetailData(
            hourlySteps: hourlySteps,
            flightsAscended: Int(log?.flightsAscended ?? 0),
            flightsDescended: Int(log?.flightsDescended ?? 0),
            goalAchievementStatus: Int(log?.totalSteps ?? 0) >= dailyGoal ? .achieved : .notAchieved,
            dailySteps: Int(log?.totalSteps ?? 0),
            dailyGoal: dailyGoal
        )
        
        DispatchQueue.main.async {
            self.detailData = newDetailData
        }
    }
    
    
    
    // MARK: - Simulate Pedometer Updates
    
    func startPedometerUpdates() {
        timer?.invalidate() // Invalidate any existing timer
        timer = Timer.scheduledTimer(withTimeInterval: 25.0, repeats: true) { [weak self] _ in
            self?.simulateStepIncrement()
        }
    }
    
    private func simulateStepIncrement() {
        guard let todayLog = todayLog else { return }
        
        // Create a new HourlyStepData instance and associate it with todayLog
        let hourlyStepData = HourlyStepData(context: context)
        hourlyStepData.date = Date()
        hourlyStepData.stepCount = 3
        hourlyStepData.dailyLog = todayLog
        
        // Increment totalSteps of todayLog
        context.perform {
            todayLog.totalSteps += 3
            self.updateTodayLogInList()
            self.saveContextIfNeeded()
        }
    }
    
    private func updateTodayLogInList() {
        guard let todayLog = todayLog else { return }
        if let index = stepDataList.firstIndex(where: { $0.date == todayLog.date }) {
            stepDataList[index] = todayLog
            loadTodayLog()
        }
    }
    // MARK: - Core Data Handling
    
    private func saveContextIfNeeded() {
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                print("Error saving context: \(error)")
            }
        }
    }
    
    private func loadTodayLog() {
        let calendar = Calendar.current
        todayLog = stepDataList.first { calendar.isDateInToday($0.date ?? Date()) }
    }
    
    // MARK: - PedometerDataProvider Implementation
    
    func fetchSteps(for date: Date, completion: @escaping (Int, Error?) -> Void) {
        if shouldSimulateError {
            let error = NSError(domain: "MockPedometerDataProvider", code: 1, userInfo: [NSLocalizedDescriptionKey: "Simulated error in fetchSteps"])
            errorPublisher.send(error)
            completion(0, error)
            return
        }
        
        let steps = stepDataList.first { $0.date == date }?.totalSteps ?? 0
        completion(Int(steps), nil)
    }
    
    func fetchHourlyStepData(for date: Date, completion: @escaping ([Int]) -> Void) {
        if shouldSimulateError {
            let error = NSError(domain: "MockPedometerDataProvider", code: 1, userInfo: [NSLocalizedDescriptionKey: "Simulated error in fetchHourlyStepData"])
            errorPublisher.send(error)
            completion([])
            return
        }
        
        // Normalize the date to the start of the day
        let normalizedDate = Calendar.current.startOfDay(for: date)
        
        if let dailyLog = stepDataList.first(where: { $0.date == normalizedDate }),
           let hourlyData = dailyLog.hourlyStepData?.allObjects as? [HourlyStepData] {
            let sortedHourlyData = hourlyData.sorted(by: { $0.hour < $1.hour })
            let hourlySteps = sortedHourlyData.map { Int($0.stepCount) }
            // Ensure that there are 24 data points
            let completeHourlySteps = hourlySteps + Array(repeating: 0, count: 24 - hourlySteps.count)
            completion(completeHourlySteps)
        } else {
            // If no data for the date, return an array of 0s
            completion(Array(repeating: 0, count: 24))
        }
    }
    
    func fetchFlights(for date: Date, completion: @escaping (Int32, Int32, Error?) -> Void) {
        if shouldSimulateError {
            let error = NSError(domain: "MockPedometerDataProvider", code: 1, userInfo: [NSLocalizedDescriptionKey: "Simulated error in fetchFlights"])
            errorPublisher.send(error)
            completion(0, 0, error)
            return
        }
        let log = stepDataList.first { $0.date == date }
        completion(log?.flightsAscended ?? 0, log?.flightsDescended ?? 0, nil)
    }
    
    func getDetailData(for date: Date, completion: @escaping (DetailData?, Error?) -> Void) {
        if shouldSimulateError {
            let error = NSError(domain: "MockPedometerDataProvider", code: 1, userInfo: [NSLocalizedDescriptionKey: "Simulated error in getDetailData"])
            errorPublisher.send(error)
            completion(nil, error)
            return
        }
        let log = stepDataList.first { $0.date == date }
        let hourlySteps = (log?.hourlyStepData?.allObjects as? [HourlyStepData])?.sorted(by: { $0.hour < $1.hour }).map { HourlySteps(hour: Int($0.hour), steps: Int($0.stepCount)) } ?? []
        let dailyGoal = UserDefaultsHandler.shared.retrieveDailyGoal() ?? 0
        let detailData = DetailData(
            hourlySteps: hourlySteps,
            flightsAscended: Int(log?.flightsAscended ?? 0),
            flightsDescended: Int(log?.flightsDescended ?? 0),
            goalAchievementStatus: Int(log?.totalSteps ?? 0) >= dailyGoal ? .achieved : .notAchieved,
            dailySteps: Int(log?.totalSteps ?? 0),
            dailyGoal: dailyGoal
        )
        completion(detailData,nil)
    }
    
    func calculateHourlyAverageSteps(stepData: [DailyLog]) -> [HourlySteps] {
        var hourlyStepSums = Array(repeating: 0, count: 24)
        var dayCount = 0
        
        for dailyLog in stepData {
            
            if let hourlyData = dailyLog.hourlyStepData as? Set<HourlyStepData> {
                for data in hourlyData {
                    hourlyStepSums[Int(data.hour)] += Int(data.stepCount)
                }
            }
            dayCount += 1
        }
        
        guard dayCount > 0 else { return [] }
        
        return hourlyStepSums.enumerated().map { HourlySteps(hour: $0.offset, steps: $0.element / dayCount) }
    }
    
    //MARK: Daily Goal
    
    func retrieveDailyGoal() -> Int {
        return UserDefaults.standard.integer(forKey: "dailyStepGoal")
    }
    
    func storeDailyGoal(_ goal: Int) {
        UserDefaults.standard.set(goal, forKey: "dailyStepGoal")
    }
}

