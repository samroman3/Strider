//
//  StepDataViewModel.swift
//  myPedometer
//
//  Created by Sam Roman on 1/24/24.
//

import Foundation
import CoreMotion

class StepDataViewModel: ObservableObject {
    @Published var stepDataList: [DailyLog] = []
    @Published var weeklyAverageSteps: Int = 0
    @Published var selectedDate = Date()
    var liveDataManager: LiveDataManager
    var dataStore: PedometerDataStore
    let calendar = Calendar.current
    
    @Published var todayLog: DailyLog?

    
    
    init(pedometerDataProvider: PedometerDataProvider, dataStore: PedometerDataStore) {
        self.liveDataManager = LiveDataManager(pedometerDataProvider: pedometerDataProvider, dataStore: dataStore)
        self.dataStore = dataStore
        loadInitialData()
        loadTodayLog()
    }

    private func loadInitialData() {
        dataStore.fetchLastSevenDaysData { [weak self] dailyLogs in
            DispatchQueue.main.async {
                self?.stepDataList = dailyLogs.filter { log in
                    guard let logDate = log.date else { return false }
                    return !logDate.isToday()
                }
                self?.calculateWeeklyAverageSteps()
            }
        }
    }
    
    private func loadTodayLog() {
           let today = Calendar.current.startOfDay(for: Date())
           dataStore.fetchOrCreateDailyLog(for: today) { [weak self] log in
               DispatchQueue.main.async {
                   self?.todayLog = log
               }
           }
       }

    private func calculateWeeklyAverageSteps() {
        let totalSteps = stepDataList.reduce(0) { $0 + Int($1.totalSteps) }
        weeklyAverageSteps = totalSteps / max(stepDataList.count, 1)
    }

    func isToday() -> Bool {
                let calendar = Calendar.current
                return calendar.isDateInToday(Date())
    }

}
