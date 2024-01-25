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
    
    private let dataStore: PedometerDataStore
    private let dateManager: DateManager
    
    init(dateManager: DateManager, dataStore: PedometerDataStore) {
        self.dateManager = dateManager
        self.dataStore = dataStore
        fetchStepData()
    }
    
    func fetchStepData() {
        let group = DispatchGroup()

        for daysBack in 0..<7 {
            let date = Calendar.current.date(byAdding: .day, value: -daysBack, to: Date())!
            group.enter()
            
            dataStore.fetchOrCreateDailyLog(for: date) { [weak self] dailyLog in
                if dailyLog.totalSteps == 0 {
                    // Steps not available in CoreData, fetch from CMPedometer
                    self?.dataStore.pedometerManager.fetchSteps(for: date) { steps, error in
                        DispatchQueue.main.async {
                            if error == nil {
                                dailyLog.totalSteps = Int32(steps)
                                self?.dataStore.saveContext()
                            }
                            self?.stepDataList.append(dailyLog)
                            group.leave()
                        }
                    }
                } else {
                    // Steps are available in CoreData
                    DispatchQueue.main.async {
                        self?.stepDataList.append(dailyLog)
                        group.leave()
                    }
                }
            }
        }

        group.notify(queue: DispatchQueue.main) {
            self.stepDataList.sort(by: { $0.date ?? Date() > $1.date ?? Date() })
        }
    }
}
