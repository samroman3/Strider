//
//  StepDataViewModel.swift
//  myPedometer
//
//  Created by Sam Roman on 1/24/24.
//

import Foundation
import CoreMotion

class StepDataViewModel: ObservableObject {
    @Published var liveStepCount: Int = 0
    @Published var stepDataList: [DailyLog] = []

    var pedometerManager: PedometerManager
    var dataStore: PedometerDataStore
    var dateManager: DateManager
    let calendar = Calendar.current

    init(pedometerManager: PedometerManager, dataStore: PedometerDataStore, dateManager: DateManager) {
        self.pedometerManager = pedometerManager
        self.dataStore = dataStore
        self.dateManager = dateManager
        startLiveStepUpdates()
        fetchStepData()
    }

    private func startLiveStepUpdates() {
        pedometerManager.startPedometerUpdates { [weak self] stepCount in
            DispatchQueue.main.async {
                // Only update if it's today
                if self?.isToday() ?? false {
                    self?.liveStepCount = stepCount
                }
            }
        }
    }
    func fetchStepData() {
           // Call PedometerDataStore's method to fetch data for the last seven days
           dataStore.fetchLastSevenDaysData { [weak self] dailyLogs in
               DispatchQueue.main.async {
                   self?.stepDataList = dailyLogs.filter { $0.date ?? Date() <= Date() }
                   self?.stepDataList.sort(by: { $0.date ?? Date() > $1.date ?? Date() })
               }
           }
       }

     func isToday() -> Bool {
        return calendar.isDateInToday(Date())
    }
}
