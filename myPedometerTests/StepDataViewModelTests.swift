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

    func testErrorHandling() {
        // Simulate an error in the data provider
        mockPedometerDataProvider.shouldSimulateError = true
        
        // Create an expectation
        let expectation = XCTestExpectation(description: "Error handling")
        
        // Set up a cancellable to observe changes to viewModel.error
        let cancellable = viewModel.$error
            .sink { error in
                if error != nil {
                    // Error is not nil, fulfill the expectation
                    expectation.fulfill()
                }
            }
        
        // Trigger the fetch operation
        viewModel.loadData(provider: mockPedometerDataProvider)
        
        // Wait for the expectation to be fulfilled (with a timeout)
        wait(for: [expectation], timeout: 10.0)
        
        // Cancel the cancellable to avoid memory leaks
        cancellable.cancel()
        
        // Assert that viewModel.error is not nil
        XCTAssertNotNil(viewModel.error)
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
