//
//  MockPedometerDataProvider.swift
//  myPedometer
//
//  Created by Sam Roman on 1/24/24.
//

import Foundation
class MockPedometerDataProvider: PedometerDataProvider {
    private var baseStepCount: Int = 5000 // Starting step count for the simulation
    private var stepVariation: Int = 1000  // Variation in step count

    private var mockData: [Date: Int] = [:]

    func setMockData(steps: Int, for date: Date) {
        let startOfDay = Calendar.current.startOfDay(for: date) // Normalize the date
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


