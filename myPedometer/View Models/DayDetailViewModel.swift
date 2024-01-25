//
//  DayDetailViewModel.swift
//  myPedometer
//
//  Created by Sam Roman on 1/24/24.
//

import Foundation
import CoreMotion

class DayDetailViewModel: ObservableObject {
    
    private let dataStore: PedometerDataStore
    var dailyLog: DailyLog
    @Published var hourlySteps: [Int] = Array(repeating: 0, count: 24) // For each hour of the day
    
    init(dailyLog: DailyLog, dataStore: PedometerDataStore) {
        self.dailyLog = dailyLog
        self.dataStore = dataStore
//        fetchHourlySteps(for: dailyLog.date ?? Date())
    }
    

//    func fetchHourlySteps(for date: Date) {
//        let calendar = Calendar.current
//        let startOfDay = calendar.startOfDay(for: date)
//        
//        // Clear previous data
//        hourlySteps = Array(repeating: 0, count: 24)
//        
//        let group = DispatchGroup()
//        
//        for hour in 0..<24 {
//            group.enter()
//            let startDate = calendar.date(byAdding: .hour, value: hour, to: startOfDay)!
//            let endDate = calendar.date(byAdding: .hour, value: 1, to: startDate)!
//            
//            pedomo.pedometer.queryPedometerData(from: startDate, to: endDate) { [weak self] (data, error) in
//                defer { group.leave() }
//                
//                if let data = data, error == nil {
//                    // Run on the main thread because we're updating the UI
//                    DispatchQueue.main.async {
//                        self?.hourlySteps[hour] = data.numberOfSteps.intValue
//                    }
//                } else {
//                    print("Error fetching hourly steps: \(error?.localizedDescription ?? "Unknown error")")
//                }
//            }
//        }
//        
//        group.notify(queue: .main) {
//            // All data has been fetched and `hourlySteps` array is ready
//            // You can now update the bar chart in the UI
//        }
//    }
}
