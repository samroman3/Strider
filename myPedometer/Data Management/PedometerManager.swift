//
//  PedometerManager.swift
//  myPedometer
//
//  Created by Sam Roman on 1/24/24.
//

import SwiftUI
import CoreMotion
import CoreData
import Combine

protocol PedometerDataProvider {
    func fetchSteps(for date: Date, completion: @escaping (Int, Error?) -> Void)
    func fetchHourlyStepData(for date: Date, completion: @escaping ([Int]) -> Void)
    func fetchFlights(for date: Date, completion: @escaping (Int32, Int32, Error?) -> Void)
    func getDetailData(for date: Date, completion: @escaping (DetailData) -> Void)
    func calculateHourlyAverageSteps(stepData: [DailyLog]) -> [HourlySteps]
    func loadStepData(completion: @escaping ([DailyLog], [HourlySteps]) -> Void)
    var stepDataList: [DailyLog] { get }
    var dailyAverageHourlySteps: [HourlySteps] { get }
    
    
}

protocol PedometerDataObservable {
    var todayLogPublisher: Published<DailyLog?>.Publisher { get }
}

class PedometerManager: ObservableObject, PedometerDataProvider, PedometerDataObservable {
    
    
    let pedometer = CMPedometer()
    private var context: NSManagedObjectContext
    var startOfDay = Date()
    @ObservedObject var dataStore: PedometerDataStore
    @Published var todayLog: DailyLog?
    @Published var stepDataList: [DailyLog] = []
    @Published var dailyAverageHourlySteps: [HourlySteps] = []
    var todayLogPublisher: Published<DailyLog?>.Publisher { $todayLog }
    
    init(context: NSManagedObjectContext, dataStore: PedometerDataStore) {
        self.context = context
        self.dataStore = dataStore
        startOfDay = Calendar.current.startOfDay(for: Date())
        checkDateAndLoadData()
        startPedometerUpdates()
        loadTodayLog()
    }
    
    
    //MARK: Initial Data Setup
    
    private func checkDateAndLoadData() {
        let currentDate = Calendar.current.startOfDay(for: Date())
        let defaults = UserDefaults.standard
        if let lastOpenedDate = UserDefaultsHandler.shared.retrieveLastOpenedDate(),
           !Calendar.current.isDate(lastOpenedDate, inSameDayAs: currentDate) {
            loadStepData { logs, hourlyAvg in
                self.stepDataList = logs
                self.dailyAverageHourlySteps = hourlyAvg
            }
        }
        UserDefaultsHandler.shared.storeLastOpenedDate(currentDate)
        self.setDefaultDailyGoalIfNeeded()
    }
    
    //Pedometer Start
    func startPedometerUpdates() {
        if CMPedometer.isStepCountingAvailable() {
            pedometer.startUpdates(from: startOfDay) { data, error in
                guard let data = data, error == nil else { return }
                print("\(data.numberOfSteps.intValue)")
                self.todayLog?.totalSteps = data.numberOfSteps.int32Value
                self.todayLog?.flightsAscended = data.floorsAscended?.int32Value ?? 0
                self.todayLog?.flightsDescended = data.floorsDescended?.int32Value ?? 0
            }
        } else {
            print("Step counting / Pedometer not supported on this device")
        }
    }
    
    func loadStepData(completion: @escaping ([DailyLog], [HourlySteps]) -> Void) {
        var fetchedLogs = [DailyLog]()
        
        let dispatchGroup = DispatchGroup()
        
        for daysBack in 0..<7 {
            dispatchGroup.enter()
            let date = Calendar.current.date(byAdding: .day, value: -daysBack, to: Date())!
            
            fetchOrCreateLog(for: date) { log in
                fetchedLogs.append(log)
                dispatchGroup.leave()
            }
        }
        
        dispatchGroup.notify(queue: DispatchQueue.main) {
            let sortedLogs = fetchedLogs.sorted { $0.date ?? Date() > $1.date ?? Date() }
            let hourlyAverage = self.calculateHourlyAverageSteps(stepData: sortedLogs)
            completion(sortedLogs,hourlyAverage)
        }
    }
    
    
    func setDefaultDailyGoalIfNeeded() {
        let defaults = UserDefaults.standard
        if  UserDefaultsHandler.shared.retrieveDailyGoal() == nil {
            // Key does not exist, set the default value
            UserDefaultsHandler.shared.storeDailyGoal(8000)
        }
    }
    
    func loadTodayLog() {
        let today = Calendar.current.startOfDay(for: Date())
        dataStore.fetchOrCreateDailyLog(for: today) { [weak self] log in
            DispatchQueue.main.async {
                self?.todayLog = log
            }
        }
    }
    private func fetchOrCreateLog(for date: Date, completion: @escaping (DailyLog) -> Void) {
        dataStore.fetchOrCreateDailyLog(for: date) { [weak self] dailyLog in
            guard let self = self else { return }
            
            if self.needsUpdating(log: dailyLog) {
                self.fetchHistoricalData(for: dailyLog, date: date) { dailyLog in
                    completion(dailyLog)
                }
            } else {
                completion(dailyLog)
            }
        }
    }
    
    //Fetches historical data from pedometer to build a dailyLog
    private func fetchHistoricalData(for dailyLog: DailyLog, date: Date, completion: @escaping (DailyLog) -> Void) {
        fetchSteps(for: date) { [weak self] steps, error in
            guard let self = self, error == nil else {
                print("Error fetching steps: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            
            dailyLog.totalSteps = Int32(steps)
            
            self.fetchFlights(for: date) { ascended, descended, error in
                guard error == nil else {
                    print("Error fetching flights: \(error?.localizedDescription ?? "Unknown error")")
                    return
                }
                
                dailyLog.flightsAscended = Int32(ascended)
                dailyLog.flightsDescended = Int32(descended)
                
                self.fetchHourlyStepData(for: date) { hourlySteps in
                    // Update the hourly step data
                    // Remove existing hourly step data
                    if let existingSteps = dailyLog.hourlyStepData as? Set<HourlyStepData> {
                        existingSteps.forEach { dailyLog.removeFromHourlyStepData($0) }
                    }
                    
                    // Add new hourly step data
                    hourlySteps.enumerated().forEach { hour, steps in
                        let hourlyData = HourlyStepData(context: self.context)
                        hourlyData.hour = Int16(hour)
                        hourlyData.stepCount = Int32(steps)
                        dailyLog.addToHourlyStepData(hourlyData)
                    }
                    
                    DispatchQueue.main.async {
                        self.saveContextIfNeeded()
                        completion(dailyLog)  // Call the completion handler with the updated daily log
                    }
                }
            }
        }
    }
    
    //MARK: Live Data Handling
    private func updateTodayLog(steps: Int, flightsAscended: Int, flightsDescended: Int) {
        guard let todayLog = todayLog else { return }
        
        todayLog.totalSteps = Int32(steps)
        todayLog.flightsAscended = Int32(flightsAscended)
        todayLog.flightsDescended = Int32(flightsDescended)
        
        // Update hourly steps
        updateHourlySteps(for: todayLog)
        
        // Save context if it has changes
        saveContextIfNeeded()
    }
    
    private func updateHourlySteps(for dailyLog: DailyLog) {
        guard let date = dailyLog.date else { return }
        
        fetchHourlyStepData(for: date) { [weak self] hourlySteps in
            guard let self = self else { return }
            
            // Asynchronously update the main context
            DispatchQueue.main.async {
                // Remove existing hourly step data
                if let existingHourlySteps = dailyLog.hourlyStepData as? Set<HourlyStepData> {
                    existingHourlySteps.forEach(self.context.delete)
                }
                
                // Add new hourly step data
                hourlySteps.enumerated().forEach { hour, steps in
                    let hourlyStepData = HourlyStepData(context: self.context)
                    hourlyStepData.hour = Int16(hour)
                    hourlyStepData.stepCount = Int32(steps)
                    hourlyStepData.dailyLog = dailyLog
                    dailyLog.addToHourlyStepData(hourlyStepData)
                }
                
                // Save the context if it has changes
                self.saveContextIfNeeded()
            }
        }
    }
    
    
    
    private func needsUpdating(log: DailyLog) -> Bool {
        return log.hourlyStepData == nil || log.flightsAscended == 0 || log.flightsDescended == 0
    }
    
    private func saveContextIfNeeded() {
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                print("Error saving context: \(error)")
            }
        }
    }
    
    //MARK: Pedometer Queries
    
    func fetchFlights(for date: Date, completion: @escaping (Int32, Int32, Error?) -> Void) {
        guard CMPedometer.isFloorCountingAvailable() else {
            completion(0, 0, NSError(domain: "CMPedometer", code: 0, userInfo: [NSLocalizedDescriptionKey: "Floor counting not available."]))
            return
        }
        
        let startOfDay = Calendar.current.startOfDay(for: date)
        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!
        
        pedometer.queryPedometerData(from: startOfDay, to: endOfDay) { data, error in
            let stepsAscended = data?.floorsAscended?.intValue ?? 0
            let stepsDescended = data?.floorsDescended?.intValue ?? 0
            completion(Int32(stepsAscended), Int32(stepsDescended), error)
        }
    }
    
    func fetchSteps(for date: Date, completion: @escaping (Int, Error?) -> Void) {
        guard CMPedometer.isStepCountingAvailable() else {
            completion(0, NSError(domain: "CMPedometer", code: 0, userInfo: [NSLocalizedDescriptionKey: "Step counting not available."]))
            return
        }
        
        let startOfDay = Calendar.current.startOfDay(for: date)
        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!
        
        pedometer.queryPedometerData(from: startOfDay, to: endOfDay) { data, error in
            if let error = error {
                completion(0, error)
                return
            }
            let stepCount = data?.numberOfSteps.intValue ?? 0
            completion(stepCount, nil)
        }
    }
    
    func fetchHourlyStepData(for date: Date, completion: @escaping ([Int]) -> Void) {
        guard CMPedometer.isStepCountingAvailable() else {
            completion([])
            return
        }
        
        var hourlySteps: [Int] = Array(repeating: 0, count: 24)
        let group = DispatchGroup()
        
        for hour in 0..<24 {
            group.enter()
            let startDate = Calendar.current.date(bySettingHour: hour, minute: 0, second: 0, of: date)!
            let endDate = Calendar.current.date(byAdding: .hour, value: 1, to: startDate)!
            
            pedometer.queryPedometerData(from: startDate, to: endDate) { data, error in
                defer { group.leave() }
                
                if let data = data, error == nil {
                    hourlySteps[hour] = data.numberOfSteps.intValue
                }
                print("Error fetching hourly step data, \(error?.localizedDescription ?? "Unknown error")")
            }
        }
        
        group.notify(queue: .main) {
            completion(hourlySteps)
        }
    }
    
    //MARK: DetailView Methods
    // Fetches or creates a DailyLog, then updates it with hourly steps, flights, and goal status.
    func getDetailData(for date: Date, completion: @escaping (DetailData) -> Void) {
        dataStore.fetchOrCreateDailyLog(for: date) { [weak self] dailyLog in
            guard let self = self else { return }
            
            // Retrieve the daily goal from user defaults or set a default value
            let dailyStepGoal = UserDefaultsHandler.shared.retrieveDailyGoal() ?? 8000
            
            // If it's not today, we can use the data already in the dailyLog
            if !Calendar.current.isDateInToday(date) {
                let existingHourlySteps = (dailyLog.hourlyStepData as? Set<HourlyStepData>)?.sorted { $0.hour < $1.hour }.map {
                    HourlySteps(hour: Int($0.hour), steps: Int($0.stepCount))
                } ?? []
                let detailData = DetailData(
                    hourlySteps: existingHourlySteps,
                    flightsAscended: Int(dailyLog.flightsAscended),
                    flightsDescended: Int(dailyLog.flightsDescended),
                    goalAchievementStatus: dailyLog.totalSteps >= dailyStepGoal ? .achieved : .notAchieved,
                    dailySteps: Int(dailyLog.totalSteps),
                    dailyGoal: dailyStepGoal
                )
                DispatchQueue.main.async {
                    completion(detailData)
                }
            } else {
                // For today's data, fetch the latest from the pedometer
                self.fetchTodayData(dailyLog: todayLog!, dailyGoal: dailyStepGoal, completion: completion)
            }
        }
    }
    
    // Fetches today's data including steps and flights from the pedometer for live Detail View Data
    private func fetchTodayData(dailyLog: DailyLog, dailyGoal: Int, completion: @escaping (DetailData) -> Void) {
        let today = Calendar.current.startOfDay(for: Date())
        
        // Fetch today's total steps and flights data
        self.fetchSteps(for: today) { [weak self] steps, error in
            guard let self = self, error == nil else {
                print("Error fetching steps: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            
            self.fetchFlights(for: today) { ascended, descended, error in
                guard error == nil else {
                    print("Error fetching flights: \(error?.localizedDescription ?? "Unknown error")")
                    return
                }
                
                // Fetch hourly step data
                self.fetchHourlyStepData(for: today) { hourlyData in
                    // Map hourly data to HourlySteps objects
                    let hourlySteps = hourlyData.enumerated().map { HourlySteps(hour: $0.offset, steps: $0.element) }
                    
                    // Create the DetailData object
                    let detailData = DetailData(
                        hourlySteps: hourlySteps,
                        flightsAscended: Int(ascended),
                        flightsDescended: Int(descended),
                        goalAchievementStatus: steps >= dailyGoal ? .achieved : .notAchieved,
                        dailySteps: steps,
                        dailyGoal: dailyGoal
                    )
                    
                    // Completion handler with detail data
                    DispatchQueue.main.async {
                        completion(detailData)
                    }
                    
                    // Update the DailyLog object in CoreData with the new data
                    dailyLog.totalSteps = Int32(steps)
                    dailyLog.flightsAscended = Int32(ascended)
                    dailyLog.flightsDescended = Int32(descended)
                    hourlySteps.forEach { hourlyStep in
                        let hourlyStepData = HourlyStepData(context: self.context)
                        hourlyStepData.hour = Int16(hourlyStep.hour)
                        hourlyStepData.stepCount = Int32(hourlyStep.steps)
                        dailyLog.addToHourlyStepData(hourlyStepData)
                        self.saveContextIfNeeded()
                    }
                }
            }
        }
    }
    
    func calculateHourlyAverageSteps(stepData: [DailyLog]) -> [HourlySteps] {
        var hourlyAverages = Array(repeating: 0, count: 24)
        var totalDayCount = 0
        
        // Initialize hourlyStepSums outside of the loop
        var hourlyStepSums = Array(repeating: 0, count: 24)
        
        for dailyLog in stepData{
            if let hourlyData = dailyLog.hourlyStepData as? Set<HourlyStepData> {
                // Reset hourlyStepSums for each daily log
                hourlyStepSums = Array(repeating: 0, count: 24)
                
                for data in hourlyData {
                    hourlyStepSums[Int(data.hour)] += Int(data.stepCount)
                }
                
                // Accumulate hourly sums and increment the total day count
                hourlyAverages = zip(hourlyAverages, hourlyStepSums).map { $0 + $1 }
                totalDayCount += 1
            }
        }
        
        guard totalDayCount > 0 else { return [] }
        
        // Calculate hourly averages by dividing by the total day count
        let averageHourlySteps = hourlyAverages.map { $0 / totalDayCount }
        
        // Create an array of HourlySteps objects with hourly averages
        let hourlyStepsArray: [HourlySteps] = averageHourlySteps.enumerated().map { (hour, steps) in
            return HourlySteps(hour: hour, steps: steps)
        }
        
        return hourlyStepsArray
    }
}
