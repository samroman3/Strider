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
    @Published var stepDataList: [DailyLog] = []
    @Published var weeklyAverageSteps: Int = 0
    
    @Published var todayLog: DailyLog?
    
    @Published var dailyGoal: Int
    
    @Published private(set) var isGoalMet: Bool = false
    
    var pedometerDataProvider: PedometerDataProvider & PedometerDataObservable

    private var cancellables = Set<AnyCancellable>()

    init(pedometerDataProvider: PedometerDataProvider & PedometerDataObservable) {
        
        
        self.pedometerDataProvider = pedometerDataProvider
        self.dailyGoal = pedometerDataProvider.retrieveDailyGoal()
        print(dailyGoal)
        //Set Subscribers
        pedometerDataProvider.stepDataListPublisher
            .receive(on: DispatchQueue.main)
            .assign(to: \.stepDataList, on: self)
            .store(in: &cancellables)

        pedometerDataProvider.todayLogPublisher
            .receive(on: DispatchQueue.main)
            .assign(to: \.todayLog, on: self)
            .store(in: &cancellables)
        // Calculate weekly average steps whenever stepDataList changes
         calculateWeeklySteps()
        checkGoalStatus()
    }
    
    private func checkGoalStatus() {
            isGoalMet = todayLog?.totalSteps ?? 0 >= dailyGoal
        }
    
    private func calculateWeeklySteps(){
        $stepDataList
            .map { logs in
                let totalSteps = logs.reduce(0) { $0 + Int($1.totalSteps) }
                return totalSteps / max(logs.count, 1)
            }
            .receive(on: DispatchQueue.main)
            .assign(to: \.weeklyAverageSteps, on: self)
            .store(in: &cancellables)
    }

    func isToday(log: DailyLog) -> Bool {
        let calendar = Calendar.current
        return calendar.isDateInToday(log.date ?? Date())
    }
    
    func loadData(for date: Date) -> DetailData? {
        var data: DetailData?
        pedometerDataProvider.getDetailData(for: date) { detailData in
            data = detailData
        }
        return data
    }
}
