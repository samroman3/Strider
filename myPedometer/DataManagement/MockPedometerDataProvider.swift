//
//  MockPedometerDataProvider.swift
//  myPedometer
//
//  Created by Sam Roman on 1/24/24.
//

import Foundation
class MockPedometerDataProvider: PedometerDataProvider {
    private var mockData: [Date: Int] = [:]
    private var timer: Timer?
    private var baseStepCount: Int = 5000 // Starting step count for the simulation
    private var stepVariation: Int = 1000
    
    private var stepCount: Int {
            didSet {
                UserDefaults.standard.set(stepCount, forKey: "mockStepCount")
            }
        }
    
    init() {
            // Retrieve the stored step count when the provider is initialized
            stepCount = UserDefaults.standard.integer(forKey: "mockStepCount")
        }
    
    func fetchHourlySteps(for date: Date, completion: @escaping ([Int]) -> Void) {
           let simulatedHourlyData = (0..<24).map { _ in Int.random(in: 100...500) } // Random data for simulation
           completion(simulatedHourlyData)
       }
    
    func startPedometerUpdates(updateHandler: @escaping (Int) -> Void) {
           timer?.invalidate()  // Invalidate any existing timer
           timer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { [weak self] _ in
               guard let self = self else { return }
               self.stepCount += 3  // Increment steps
               updateHandler(self.stepCount)
           }
       }

       func stopPedometerUpdates() {
           timer?.invalidate()
           timer = nil
       }

       // Deinitializer to ensure the timer is invalidated if the provider is deallocated
       deinit {
           timer?.invalidate()
       }

    func setMockData(steps: Int, for date: Date) {
        let startOfDay = Calendar.current.startOfDay(for: date) // Normalize the date
        UserDefaults.standard.set(steps, forKey: "mockData-\(startOfDay.timeIntervalSince1970)")
        mockData[startOfDay] = steps
    }

    func fetchSteps(for date: Date, completion: @escaping (Int, Error?) -> Void) {
        let steps = simulateSteps(for: date)
        completion(steps, nil)
    }

    private func simulateSteps(for date: Date) -> Int {
        // Check if mock data is set for the specific date
        if let mockSteps = mockData[Calendar.current.startOfDay(for: date)] {
            return mockSteps
        }

        // Logic to simulate step count based on the date
        // Specific date test (e.g., for January 1, 2021)
        let specificDate = Calendar.current.date(from: DateComponents(year: 2021, month: 1, day: 1))!
        if date == specificDate {
            return 10000 // Return specific step count for January 1, 2021
        }

        // Vary the step count to simulate more activity on certain days
        let dayOfWeek = Calendar.current.component(.weekday, from: date)
        return calculateStepCount(for: dayOfWeek)
    }

    private func calculateStepCount(for dayOfWeek: Int) -> Int {
        // Simulate different step counts based on the day of the week
        switch dayOfWeek {
        case 1: // Sunday
            return baseStepCount - stepVariation // Simulate a lazy day
        case 2, 3, 4: // Monday to Wednesday
            return baseStepCount + stepVariation // Simulate active days
        case 5, 6: // Thursday, Friday
            return baseStepCount // Normal activity
        case 7: // Saturday
            return baseStepCount + 2 * stepVariation // Simulate a very active day
        default:
            return baseStepCount
        }
    }
}


