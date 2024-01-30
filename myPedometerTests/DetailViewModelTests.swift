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

    func testErrorStateWhenDataProviderFails() {
        // Simulate an error in the data provider
        mockPedometerDataProvider.shouldSimulateError = true

        let expectation = self.expectation(description: "ErrorState")

        // Observe changes in the ViewModel's error state
        let cancellable = viewModel.$error.sink { error in
            if error != nil {
                expectation.fulfill()
            }
        }

        // Trigger an action that would fetch data and potentially fail
        viewModel.loadData(for: viewModel.date)

        waitForExpectations(timeout: 5)
        cancellable.cancel()
    }
}
