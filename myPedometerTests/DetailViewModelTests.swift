//
//  DetailViewModelTests.swift
//  myPedometerTests
//
//  Created by Sam Roman on 1/30/24.
//

import XCTest
import CoreData
@testable import myPedometer

class DetailViewModelTests: XCTestCase {
    var viewModel: DetailViewModel!
    var mockPedometerDataProvider: MockPedometerDataProvider!
    var inMemoryContext: NSManagedObjectContext!

    override func setUp() {
        super.setUp()
        inMemoryContext = PersistenceController.inMemoryContext()
        mockPedometerDataProvider = MockPedometerDataProvider(context: inMemoryContext)
        let testDate = Date()
        let weeklyAvg = 5000 // Example weekly average
        let averageHourlySteps = [HourlySteps]() // Example hourly steps data
        viewModel = DetailViewModel(pedometerDataProvider: mockPedometerDataProvider, date: testDate, weeklyAvg: weeklyAvg, averageHourlySteps: averageHourlySteps)
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
        viewModel.fetchData()
        
        // Wait for the expectation to be fulfilled (with a timeout)
        wait(for: [expectation], timeout: 10.0)
        
        // Cancel the cancellable to avoid memory leaks
        cancellable.cancel()
        
        // Assert that viewModel.error is not nil
        XCTAssertNotNil(viewModel.error)
    }

    
    func testViewModelUpdatesOnDataProviderChange() {
        // Simulate data change in the data provider
        let mockDetailData = DetailData(hourlySteps: [HourlySteps(hour: 10, steps: 1000)], flightsAscended: 5, flightsDescended: 4, goalAchievementStatus: .achieved, dailySteps: 1000, dailyGoal: 800)
        mockPedometerDataProvider.detailData = mockDetailData

        // The ViewModel should react to this change
        XCTAssertNotEqual(viewModel.hourlySteps, mockDetailData.hourlySteps)
        XCTAssertNotEqual(viewModel.flightsAscended, mockDetailData.flightsAscended)
    }
}
