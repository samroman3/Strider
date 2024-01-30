//
//  StepDataViewModelTests.swift
//  myPedometerTests
//
//  Created by Sam Roman on 1/29/24.
//

import XCTest
import CoreData

@testable import myPedometer


class StepDataViewModelTests: XCTestCase {
    var viewModel: StepDataViewModel!
    var mockPedometerDataProvider: MockPedometerDataProvider!
    var inMemoryContext: NSManagedObjectContext!


    override func setUp() {
        super.setUp()
        inMemoryContext = PersistenceController.inMemoryContext()
        mockPedometerDataProvider = MockPedometerDataProvider(context: inMemoryContext)
        viewModel = StepDataViewModel(pedometerDataProvider: mockPedometerDataProvider)
    }

    override func tearDown() {
        viewModel = nil
        mockPedometerDataProvider = nil
        super.tearDown()
    }


   
    func testInitialDailyGoalSetting() {
        XCTAssertEqual(viewModel.dailyGoal, UserDefaultsHandler.shared.retrieveDailyGoal() ?? 0, "Daily goal should be set correctly at initialization")
    }

    func testCalculateWeeklySteps() {
        // Setup test data
        let log1 = mockPedometerDataProvider.createMockDailyLog(for: Date(), totalSteps: 1000, flightsAscended: 0, flightsDescended: 0)
        let log2 = mockPedometerDataProvider.createMockDailyLog(for: Date(), totalSteps: 2000, flightsAscended: 0, flightsDescended: 0)
        let testLogs = [log1,log2]
        viewModel.stepDataList = testLogs
        viewModel.calculateWeeklySteps()
        let expectedAverage = (1000 + 2000) / testLogs.count
        XCTAssertEqual(viewModel.weeklyAverageSteps, expectedAverage, "Weekly average steps calculation should be correct")
    }

    func testIsToday() {
        let todayLog = mockPedometerDataProvider.createMockDailyLog(for: Date(), totalSteps: 1000)
        XCTAssertTrue(viewModel.isToday(log: todayLog), "isToday should return true for today's log")

        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        let yesterdayLog = mockPedometerDataProvider.createMockDailyLog(for: yesterday, totalSteps: 1000)
        XCTAssertFalse(viewModel.isToday(log: yesterdayLog), "isToday should return false for yesterday's log")
    }
}
