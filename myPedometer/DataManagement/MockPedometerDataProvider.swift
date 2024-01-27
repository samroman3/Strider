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
    var stepDataListPublisher: Published<[DailyLog]>.Publisher { $stepDataList }
    var todayLogPublisher: Published<DailyLog?>.Publisher { $todayLog }

    init(context: NSManagedObjectContext) {
        self.context = context
        setupInitialMockData()
    }

    private func setupInitialMockData() {
        let today = Date()
        for dayBack in 0..<7 {
            if let date = Calendar.current.date(byAdding: .day, value: -dayBack, to: today) {
                createMockDailyLog(for: date)
            }
        }
        loadTodayLog()
    }

    private func createMockDailyLog(for date: Date) {
        let dailyLog = DailyLog(context: context)
        dailyLog.date = date
        dailyLog.totalSteps = Int32.random(in: 1000...10000)
        dailyLog.flightsAscended = Int32.random(in: 0...20)
        dailyLog.flightsDescended = Int32.random(in: 0...20)

        for hour in 0..<24 {
            let hourlyData = HourlyStepData(context: context)
            hourlyData.hour = Int16(hour)
            hourlyData.stepCount = Int32.random(in: 100...500)
            dailyLog.addToHourlyStepData(hourlyData)
        }

        stepDataList.append(dailyLog)
    }

    func loadTodayLog() {
        let today = Calendar.current.startOfDay(for: Date())
        todayLog = stepDataList.first { $0.date == today }
    }

    func fetchSteps(for date: Date, completion: @escaping (Int, Error?) -> Void) {
        let steps = stepDataList.first { $0.date == date }?.totalSteps ?? 0
        completion(Int(steps), nil)
    }

    func fetchHourlyStepData(for date: Date, completion: @escaping ([Int]) -> Void) {
        let hourlyData = stepDataList.first { $0.date == date }?.hourlyStepData?.allObjects as? [HourlyStepData]
        let stepsArray = hourlyData?.sorted(by: { $0.hour < $1.hour }).map { Int($0.stepCount) } ?? []
        completion(stepsArray)
    }

    func fetchFlights(for date: Date, completion: @escaping (Int32, Int32, Error?) -> Void) {
        let log = stepDataList.first { $0.date == date }
        completion(log?.flightsAscended ?? 0, log?.flightsDescended ?? 0, nil)
    }

    func getDetailData(for date: Date, completion: @escaping (DetailData) -> Void) {
        let log = stepDataList.first { $0.date == date }
        let hourlySteps = (log?.hourlyStepData?.allObjects as? [HourlyStepData])?.sorted(by: { $0.hour < $1.hour }).map { HourlySteps(hour: Int($0.hour), steps: Int($0.stepCount)) } ?? []

        let detailData = DetailData(
            hourlySteps: hourlySteps,
            flightsAscended: Int(log?.flightsAscended ?? 0),
            flightsDescended: Int(log?.flightsDescended ?? 0),
            goalAchievementStatus: .achieved, // Modify as needed
            dailySteps: Int(log?.totalSteps ?? 0),
            dailyGoal: retrieveDailyGoal()
        )
        completion(detailData)
    }
    
    func calculateWeeklyAverageHourlySteps(includeToday: Bool) -> [HourlySteps] {
        var hourlyStepSums = Array(repeating: 0, count: 24)
        var dayCount = 0

        for dailyLog in stepDataList {
            if !includeToday && Calendar.current.isDateInToday(dailyLog.date ?? Date()) {
                continue
            }

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

    func retrieveDailyGoal() -> Int {
        return UserDefaults.standard.integer(forKey: "dailyStepGoal")
    }

    func storeDailyGoal(_ goal: Int) {
        UserDefaults.standard.set(goal, forKey: "dailyStepGoal")
    }
}

//class MockPedometerDataProvider: PedometerDataProvider, PedometerDataObservable {
//    private var mockData: [Date: (steps: Int, flightsAscended: Int, flightsDescended: Int, hourlyData: [Int])] = [:]
//    @Published var todayLog: DailyLog?
//    @Published var stepDataList: [DailyLog] = []
//
//    var stepDataListPublisher: Published<[DailyLog]>.Publisher { $stepDataList }
//    var todayLogPublisher: Published<DailyLog?>.Publisher { $todayLog }
//
//    init() {
//        // Populate mock data for initial testing
//        setupInitialMockData()
//    }
//
//    private func setupInitialMockData() {
//        let today = Date()
//        for dayBack in 0..<7 {
//            if let date = Calendar.current.date(byAdding: .day, value: -dayBack, to: today) {
//                setMockData(for: date)
//            }
//        }
//    }
//
//    private func setMockData(for date: Date) {
//        let steps = Int.random(in: 1000...10000)
//        let flightsAscended = Int.random(in: 0...20)
//        let flightsDescended = Int.random(in: 0...20)
//        let hourlyData = (0..<24).map { _ in Int.random(in: 100...500) }
//
//        mockData[date] = (steps, flightsAscended, flightsDescended, hourlyData)
//    }
//
//    func fetchSteps(for date: Date, completion: @escaping (Int, Error?) -> Void) {
//        let steps = mockData[date]?.steps ?? 0
//        completion(steps, nil)
//    }
//
//    func fetchHourlyStepData(for date: Date, completion: @escaping ([Int]) -> Void) {
//        let hourlyData = mockData[date]?.hourlyData ?? []
//        completion(hourlyData)
//    }
//
//    func fetchFlights(for date: Date, completion: @escaping (Int32, Int32, Error?) -> Void) {
//        let flightsAscended = mockData[date]?.flightsAscended ?? 0
//        let flightsDescended = mockData[date]?.flightsDescended ?? 0
//        completion(Int32(flightsAscended), Int32(flightsDescended), nil)
//    }
//
//    func getDetailData(for date: Date, completion: @escaping (DetailData) -> Void) {
//        let steps = mockData[date]?.steps ?? 0
//        let flightsAscended = mockData[date]?.flightsAscended ?? 0
//        let flightsDescended = mockData[date]?.flightsDescended ?? 0
//        let hourlySteps = mockData[date]?.hourlyData.map { HourlySteps(hour: 0, steps: $0) } ?? []
//        
//        let detailData = DetailData(hourlySteps: hourlySteps, flightsAscended: flightsAscended, flightsDescended: flightsDescended, goalAchievementStatus: .achieved, dailySteps: steps, dailyGoal: retrieveDailyGoal())
//        completion(detailData)
//    }
//
//    func retrieveDailyGoal() -> Int {
//        return UserDefaults.standard.integer(forKey: "dailyStepGoal")
//    }
//
//    func storeDailyGoal(_ goal: Int) {
//        UserDefaults.standard.set(goal, forKey: "dailyStepGoal")
//    }
//}

//class MockPedometerDataProvider: PedometerDataProvider & PedometerDataObservable {
//    
//    func retrieveDailyGoal() -> Int {
//        return 100
//    }
//    
//    func storeDailyGoal(_ goal: Int) {
//        return
//    }
//    
//    func getDetailData(for date: Date, completion: @escaping (DetailData) -> Void) {
//        completion(DetailData(hourlySteps: [], flightsAscended: 0, flightsDescended: 0, goalAchievementStatus: .achieved, dailySteps: 2, dailyGoal: 2))
//    }
//    
//    private var mockData: [Date: Int] = [:]
//    private var timer: Timer?
//    private var baseStepCount: Int = 460 // Starting step count for the simulation
//    private var stepVariation: Int = 1000
//    @Published var todayLog: DailyLog?
//    @Published var stepDataList: [DailyLog] = []
//    var stepDataListPublisher: Published<[DailyLog]>.Publisher { $stepDataList }
//    var todayLogPublisher: Published<DailyLog?>.Publisher { $todayLog }
//    
//    private var stepCount: Int {
//            didSet {
//                UserDefaults.standard.set(stepCount, forKey: "mockStepCount")
//            }
//        }
//    
//    init() {
//            // Retrieve the stored step count when the provider is initialized
//            stepCount = UserDefaults.standard.integer(forKey: "mockStepCount")
//        
//        }
//    
//    func fetchFlights(for date: Date, completion: @escaping (Int32, Int32, Error?) -> Void) {
//            // Simulate fetching flights data
//            let simulatedFlightsAscended = Int32.random(in: 0...10)  // Randomly simulate flights ascended
//            let simulatedFlightsDescended = Int32.random(in: 0...10) // Randomly simulate flights descended
//
//            // Call completion handler with simulated data
//            completion(simulatedFlightsAscended, simulatedFlightsDescended, nil)
//        }
//    
//    func fetchHourlyStepData(for date: Date, completion: @escaping ([Int]) -> Void) {
//           let simulatedHourlyData = (0..<24).map { _ in Int.random(in: 100...500) } // Random data for simulation
//           completion(simulatedHourlyData)
//       }
//    
//    func startPedometerUpdates(updateHandler: @escaping (Int) -> Void) {
//           timer?.invalidate()  // Invalidate any existing timer
//           timer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { [weak self] _ in
//               guard let self = self else { return }
//               self.stepCount += 3  // Increment steps
//               updateHandler(self.stepCount)
//           }
//       }
//
//       func stopPedometerUpdates() {
//           timer?.invalidate()
//           timer = nil
//       }
//
//       // Deinitializer to ensure the timer is invalidated if the provider is deallocated
//       deinit {
//           timer?.invalidate()
//       }
//
//    func setMockData(steps: Int, for date: Date) {
//        let startOfDay = Calendar.current.startOfDay(for: date) // Normalize the date
//        UserDefaults.standard.set(steps, forKey: "mockData-\(startOfDay.timeIntervalSince1970)")
//        mockData[startOfDay] = steps
//    }
//
//    func fetchSteps(for date: Date, completion: @escaping (Int, Error?) -> Void) {
//        let steps = simulateSteps(for: date)
//        completion(steps, nil)
//    }
//
//    private func simulateSteps(for date: Date) -> Int {
//        // Check if mock data is set for the specific date
//        if let mockSteps = mockData[Calendar.current.startOfDay(for: date)] {
//            return mockSteps
//        }
//
//        // Logic to simulate step count based on the date
//        // Specific date test (e.g., for January 1, 2021)
//        let specificDate = Calendar.current.date(from: DateComponents(year: 2021, month: 1, day: 1))!
//        if date == specificDate {
//            return 10000 // Return specific step count for January 1, 2021
//        }
//
//        // Vary the step count to simulate more activity on certain days
//        let dayOfWeek = Calendar.current.component(.weekday, from: date)
//        return calculateStepCount(for: dayOfWeek)
//    }
//
//    private func calculateStepCount(for dayOfWeek: Int) -> Int {
//        // Simulate different step counts based on the day of the week
//        switch dayOfWeek {
//        case 1: // Sunday
//            return baseStepCount - stepVariation // Simulate a lazy day
//        case 2, 3, 4: // Monday to Wednesday
//            return baseStepCount + stepVariation // Simulate active days
//        case 5, 6: // Thursday, Friday
//            return baseStepCount // Normal activity
//        case 7: // Saturday
//            return baseStepCount + 2 * stepVariation // Simulate a very active day
//        default:
//            return baseStepCount
//        }
//    }
//}


