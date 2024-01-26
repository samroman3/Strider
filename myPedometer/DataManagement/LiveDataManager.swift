//
//  LiveDataManager.swift
//  myPedometer
//
//  Created by Sam Roman on 1/25/24.
//

import Foundation
import CoreData

class LiveDataManager: ObservableObject {
    @Published var liveStepCount: Int = 0
    @Published var liveFlightsAscended: Int = 0
    @Published var liveFlightsDescended: Int = 0
    @Published var liveHourlySteps: [HourlySteps] = []
    
    private var pedometerDataProvider: PedometerDataProvider
    private var dataStore: PedometerDataStore
    private var lastHourlyUpdate: Date?

    init(pedometerDataProvider: PedometerDataProvider, dataStore: PedometerDataStore) {
        self.pedometerDataProvider = pedometerDataProvider
        self.dataStore = dataStore
        startLiveUpdates()
    }

    private func startLiveUpdates() {
        // Start updates for steps
        pedometerDataProvider.startPedometerUpdates { [weak self] stepCount in
            DispatchQueue.main.async {
                self?.liveStepCount = stepCount
                self?.checkAndUpdateHourlyDataIfNeeded()
            }
        }

        // Start updates for flights ascended and descended
        updateFlightsData()

        // Start updates for hourly step data
        updateHourlySteps()
    }

    private func checkAndUpdateHourlyDataIfNeeded() {
        let now = Date()
        let currentHour = Calendar.current.component(.hour, from: now)
        
        if let lastUpdate = lastHourlyUpdate {
            let lastUpdateHour = Calendar.current.component(.hour, from: lastUpdate)
            if currentHour != lastUpdateHour {
                // Hour has changed, update hourly steps and store in CoreData
                updateHourlySteps()
            }
        } else {
            // This is the first time; initialize lastHourlyUpdate
            lastHourlyUpdate = now
        }
    }

    private func updateFlightsData() {
        let today = Calendar.current.startOfDay(for: Date())
        pedometerDataProvider.fetchFlights(for: today) { [weak self] ascended, descended, error in
            guard let self = self, error == nil else { return }
            DispatchQueue.main.async {
                self.liveFlightsAscended = Int(ascended)
                self.liveFlightsDescended = Int(descended)
            }
        }
    }

    private func updateHourlySteps() {
        let today = Calendar.current.startOfDay(for: Date())
        pedometerDataProvider.fetchHourlyStepData(for: today) { [weak self] hourlyData in
            guard let self = self else { return }
            DispatchQueue.main.async {
                // Map the array of Int to an array of HourlySteps
                self.liveHourlySteps = hourlyData.enumerated().map { HourlySteps(hour: $0.offset, steps: $0.element) }
                self.lastHourlyUpdate = Date()
                // Store hourly step data in CoreData
                self.dataStore.updateDailyLogWithHourlySteps(hourlySteps: hourlyData, for: today)
            }
        }
    }
}



