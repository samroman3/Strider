//
//  PedometerDataProcessorTests.swift
//  myPedometerTests
//
//  Created by Sam Roman on 1/30/24.
//

import XCTest
@testable import myPedometer

final class PedometerDataProcessorTests: XCTestCase {
    
    func testCalculateMostAndLeastActiveHours() {
        let hourlySteps: [HourlySteps] = [
            HourlySteps(hour: 1, steps: 500),
            HourlySteps(hour: 2, steps: 600),
            HourlySteps(hour: 3, steps: 400),
        ]
        
        let result = PedometerDataProcessor.calculateMostAndLeastActiveHours(hourlySteps: hourlySteps)
        
        XCTAssertEqual(result.mostActive, 2, "Most active hour should be 2")
        XCTAssertEqual(result.leastActive, 3, "Least active hour should be 3")
    }
    
    func testCalculateMostActivePeriodOfDay() {
        let hourlySteps: [HourlySteps] = [
            HourlySteps(hour: 6, steps: 1000),  // Morning
            HourlySteps(hour: 13, steps: 800),  // Afternoon
            HourlySteps(hour: 19, steps: 1200), // Evening
        ]
        
        let result = PedometerDataProcessor.calculateMostActivePeriodOfDay(hourlySteps: hourlySteps)
        
        XCTAssertEqual(result, "Evening", "Most active period should be 'Evening'")
    }
    
    func testCompareTodayWithWeeklyAverage() {
        let todayTotalSteps = 900
        let weeklyAvg = 800
        
        let result = PedometerDataProcessor.compareTodayWithWeeklyAverage(todayTotalSteps: todayTotalSteps, weeklyAvg: weeklyAvg)
        
        XCTAssertEqual(result, "more active", "Today should be 'more active' compared to weekly average")
    }
    
    func testCalculateMostAndLeastActiveHoursEmptyInput() {
        let hourlySteps: [HourlySteps] = []
        
        let result = PedometerDataProcessor.calculateMostAndLeastActiveHours(hourlySteps: hourlySteps)
        
        XCTAssertEqual(result.mostActive, 0, "Most active hour should be 0 for empty input")
        XCTAssertEqual(result.leastActive, 0, "Least active hour should be 0 for empty input")
    }
    
    func testCalculateMostActivePeriodOfDayEmptyInput() {
        let hourlySteps: [HourlySteps] = []
        
        let result = PedometerDataProcessor.calculateMostActivePeriodOfDay(hourlySteps: hourlySteps)
        
        XCTAssertEqual(result, "Morning", "Most active period should be 'Morning' for empty input")
    }
}


