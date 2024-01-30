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
    func fetchDetailData(for date: Date) 
    func getDetailData(for date: Date, completion: @escaping (DetailData?, Error?) -> Void)
    func calculateHourlyAverageSteps(stepData: [DailyLog]) -> [HourlySteps]
    func loadStepData(completion: @escaping ([DailyLog], [HourlySteps], Error?) -> Void)
    var stepDataList: [DailyLog] { get }
    var dailyAverageHourlySteps: [HourlySteps] { get }
    var detailData: DetailData? { get set }
    var errorPublisher: PassthroughSubject<Error, Never> { get }
    
}

protocol PedometerDataObservable {
    var todayLogPublisher: Published<DailyLog?>.Publisher { get }
    var detailDataPublisher: Published<DetailData?>.Publisher { get }
}

class PedometerManager: ObservableObject, PedometerDataProvider, PedometerDataObservable {
    
    
    
    let pedometer = CMPedometer()
    private var context: NSManagedObjectContext
    var startOfDay = Date()
    @ObservedObject var dataStore: PedometerDataStore
    @Published var todayLog: DailyLog?
    @Published var stepDataList: [DailyLog] = []
    @Published var dailyAverageHourlySteps: [HourlySteps] = []
    @Published var detailData: DetailData?
    var errorPublisher = PassthroughSubject<Error, Never>()
    var todayLogPublisher: Published<DailyLog?>.Publisher { $todayLog }
    var detailDataPublisher: Published<DetailData?>.Publisher { $detailData }
    
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
            loadStepData { logs, hourlyAvg, error in
                if let error = error {
                    self.errorPublisher.send(error)
                }
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
            pedometer.startUpdates(from: startOfDay) { [weak self] data, error in
                if let error = error {
                    self?.errorPublisher.send(error)
                    return
                }

                guard let data = data else {
                    let unknownError = NSError(domain: "PedometerManager", code: 0, userInfo: [NSLocalizedDescriptionKey: "Unknown pedometer error."])
                    self?.errorPublisher.send(unknownError)
                    return
                }

                DispatchQueue.main.async {
                    self?.todayLog?.totalSteps = data.numberOfSteps.int32Value
                    self?.todayLog?.flightsAscended = data.floorsAscended?.int32Value ?? 0
                    self?.todayLog?.flightsDescended = data.floorsDescended?.int32Value ?? 0
                }
            }
        } else {
            let notSupportedError = NSError(domain: "PedometerManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "Step counting / Pedometer not supported on this device"])
            errorPublisher.send(notSupportedError)
        }
    }

    
    func loadStepData(completion: @escaping ([DailyLog], [HourlySteps], Error?) -> Void) {
        var fetchedLogs = [DailyLog]()
        var fetchError: Error?
        
        let dispatchGroup = DispatchGroup()
        
        for daysBack in 0..<7 {
            dispatchGroup.enter()
            let date = Calendar.current.date(byAdding: .day, value: -daysBack, to: Date())!
            
            fetchOrCreateLog(for: date) { log, error in
                if let error = error {
                    fetchError = error // Capture the error
                }
                fetchedLogs.append(log)
                dispatchGroup.leave()
            }
        }
        
        dispatchGroup.notify(queue: DispatchQueue.main) {
            if let fetchError = fetchError {
                completion([], [], fetchError) // Pass the fetch error to the caller
                return
            }
            
            let sortedLogs = fetchedLogs.sorted { $0.date ?? Date() > $1.date ?? Date() }
            let hourlyAverage = self.calculateHourlyAverageSteps(stepData: sortedLogs)
            completion(sortedLogs, hourlyAverage, nil)
        }
    }

    
    
    func setDefaultDailyGoalIfNeeded() {
        let defaults = UserDefaults.standard
        if  UserDefaultsHandler.shared.retrieveDailyGoal() == nil {
            // Key does not exist, set the default value
            UserDefaultsHandler.shared.storeDailyGoal(8000)
        }
    }
    
    func fetchDetailData(for date: Date) {
            getDetailData(for: date) { [weak self] detailData, error in
                DispatchQueue.main.async {
                    if let error = error {
                        self?.errorPublisher.send(error)
                        return
                    }

                    // Update the published detailData 
                    self?.detailData = detailData
                }
            }
        }
    
    func loadTodayLog() {
        let today = Calendar.current.startOfDay(for: Date())
        dataStore.fetchOrCreateDailyLog(for: today) { [weak self] log, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.errorPublisher.send(error)
                } else {
                    self?.todayLog = log
                }
            }
        }
    }

    private func fetchOrCreateLog(for date: Date, completion: @escaping (DailyLog, Error?) -> Void) {
        dataStore.fetchOrCreateDailyLog(for: date) { [weak self] dailyLog, error in
            guard let self = self else { return }
            
            if let error = error {
                completion(dailyLog, error) // Pass the error to the caller
                return
            }
            
            if self.needsUpdating(log: dailyLog) {
                self.fetchHistoricalData(for: dailyLog, date: date) { updatedLog, historicalDataError in
                    if let historicalDataError = historicalDataError {
                        completion(updatedLog, historicalDataError) // Pass the error to the caller
                    } else {
                        completion(updatedLog, nil)
                    }
                }
            } else {
                completion(dailyLog, nil)
            }
        }
    }


    
    //Fetches historical data from pedometer to build a dailyLog
    private func fetchHistoricalData(for dailyLog: DailyLog, date: Date, completion: @escaping (DailyLog, Error?) -> Void) {
        fetchSteps(for: date) { [weak self] steps, error in
            guard let self = self else { return }
            
            if let error = error {
                self.errorPublisher.send(error)
                return
            }
            
            dailyLog.totalSteps = Int32(steps)
            
            self.fetchFlights(for: date) { ascended, descended, error in
                if let error = error {
                    self.errorPublisher.send(error)
                    completion(dailyLog, error)
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
                        completion(dailyLog, nil)  // Call the completion handler with the updated daily log
                    }
                }
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
            let error = NSError(domain: "CMPedometer", code: 0, userInfo: [NSLocalizedDescriptionKey: "Floor counting not available."])
            errorPublisher.send(error)
            completion(0, 0, error)
            return
        }
        
        let startOfDay = Calendar.current.startOfDay(for: date)
        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!
        
        pedometer.queryPedometerData(from: startOfDay, to: endOfDay) { [weak self] data, error in
            if let error = error {
                self?.errorPublisher.send(error)
                completion(0, 0, error)
                return
            }
            let stepsAscended = data?.floorsAscended?.intValue ?? 0
            let stepsDescended = data?.floorsDescended?.intValue ?? 0
            completion(Int32(stepsAscended), Int32(stepsDescended), nil)
        }
    }

    func fetchSteps(for date: Date, completion: @escaping (Int, Error?) -> Void) {
        guard CMPedometer.isStepCountingAvailable() else {
            let error = NSError(domain: "CMPedometer", code: 0, userInfo: [NSLocalizedDescriptionKey: "Step counting not available."])
            errorPublisher.send(error)
            completion(0, error)
            return
        }
        
        let startOfDay = Calendar.current.startOfDay(for: date)
        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!
        
        pedometer.queryPedometerData(from: startOfDay, to: endOfDay) { [weak self] data, error in
            if let error = error {
                self?.errorPublisher.send(error)
                completion(0, error)
                return
            }
            let stepCount = data?.numberOfSteps.intValue ?? 0
            completion(stepCount, nil)
        }
    }

    
    func fetchHourlyStepData(for date: Date, completion: @escaping ([Int]) -> Void) {
        guard CMPedometer.isStepCountingAvailable() else {
            self.errorPublisher.send(NSError(domain: "CMPedometer", code: 0, userInfo: [NSLocalizedDescriptionKey: "Step counting not available."]))
            completion([])
            return
        }
        
        var hourlySteps: [Int] = Array(repeating: 0, count: 24)
        var encounteredError: Error?
        let group = DispatchGroup()
        
        for hour in 0..<24 {
            group.enter()
            let startDate = Calendar.current.date(bySettingHour: hour, minute: 0, second: 0, of: date)!
            let endDate = Calendar.current.date(byAdding: .hour, value: 1, to: startDate)!
            
            pedometer.queryPedometerData(from: startDate, to: endDate) { [weak self] data, error in
                defer { group.leave() }

                if let error = error {
                    encounteredError = error
                } else if let data = data {
                    hourlySteps[hour] = data.numberOfSteps.intValue
                }
            }
        }
        
        group.notify(queue: .main) {
            if let error = encounteredError {
                self.errorPublisher.send(error)
            }
            completion(hourlySteps)
        }
    }

    
    //MARK: DetailView Methods
    // Fetches or creates a DailyLog, then updates it with hourly steps, flights, and goal status.
    func getDetailData(for date: Date, completion: @escaping (DetailData?, Error?) -> Void) {
        dataStore.fetchOrCreateDailyLog(for: date) { [weak self] dailyLog, error in
            guard let self = self else { return }

            // Retrieve the daily goal from user defaults or set a default value
            let dailyStepGoal = UserDefaultsHandler.shared.retrieveDailyGoal() ?? 8000

            if let error = error {
                completion(nil, error) // Pass the error to the caller
                return
            }

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
                    completion(detailData, nil)
                }
            } else {
                // For today's data, fetch the latest from the pedometer
                self.fetchTodayData(dailyLog: dailyLog, dailyGoal: dailyStepGoal) { detailData, error in
                    DispatchQueue.main.async {
                        if let error = error {
                            completion(nil, error) // Pass the error to the caller
                        } else {
                            completion(detailData, nil)
                        }
                    }
                }
            }
        }
    }


    
    // Fetches today's data including steps and flights from the pedometer for live Detail View Data
    private func fetchTodayData(dailyLog: DailyLog, dailyGoal: Int, completion: @escaping (DetailData?, Error?) -> Void) {
        let today = Calendar.current.startOfDay(for: Date())
        
        // Fetch today's total steps and flights data
        self.fetchSteps(for: today) { [weak self] steps, error in
            guard let self = self else { return }
            
            if let error = error {
                self.errorPublisher.send(error)
                completion(nil, error)
                return
            }
            
            self.fetchFlights(for: today) { ascended, descended, error in
                if let error = error {
                    self.errorPublisher.send(error)
                    completion(nil, error)
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
                        completion(detailData, nil)
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
        
        for dailyLog in stepData {
            if let hourlyData = dailyLog.hourlyStepData as? Set<HourlyStepData> {
                var hourlyStepSums = Array(repeating: 0, count: 24)
                
                for data in hourlyData {
                    let hour = Int(data.hour)
                    if hour < 0 || hour >= 24 {
                        // Handle unexpected hour value
                        errorPublisher.send(NSError(domain: "PedometerManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid hour value in hourly data."]))
                        return []
                    }
                    hourlyStepSums[hour] += Int(data.stepCount)
                }
                
                hourlyAverages = zip(hourlyAverages, hourlyStepSums).map { $0 + $1 }
                totalDayCount += 1
            } else {
                // Handle unexpected data format
                errorPublisher.send(NSError(domain: "PedometerManager", code: 2, userInfo: [NSLocalizedDescriptionKey: "Invalid step data format."]))
                return []
            }
        }
        
        guard totalDayCount > 0 else { return [] }
        
        let averageHourlySteps = hourlyAverages.map { $0 / totalDayCount }
        return averageHourlySteps.enumerated().map { HourlySteps(hour: $0.offset, steps: $0.element) }
    }


}
