//
//  PedometerDataStoreTests.swift
//  myPedometerTests
//
//  Created by Sam Roman on 1/24/24.
//

import XCTest
import CoreData
@testable import myPedometer

class PedometerDataStoreTests: XCTestCase {
    var dataStore: PedometerDataStore!
    var mockPedometerDataProvider: MockPedometerDataProvider!
    var inMemoryContext: NSManagedObjectContext!

    override func setUp() {
        super.setUp()
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        inMemoryContext = PersistenceController.inMemoryContext()
        mockPedometerDataProvider = MockPedometerDataProvider(context: inMemoryContext)
        dataStore = PedometerDataStore(context: inMemoryContext)
    }

    override func tearDown() {
        inMemoryContext = nil
        mockPedometerDataProvider = nil
        dataStore = nil
        super.tearDown()
    }

    func testFetchAndStoreData() {
        let expectedSteps = 10000
        let testDate = Calendar.current.startOfDay(for: Date()) // Ensure the date matches the mock setup

        let expectation = self.expectation(description: "FetchAndStoreData")

        // Trigger data fetching and storing
        dataStore.fetchLastSevenDaysData { logs in
            // Verify that logs contain the expected data
            if let logForTestDate = logs.first(where: { $0.date == testDate }) {
                XCTAssertEqual(logForTestDate.totalSteps, Int32(expectedSteps), "The total steps should match the mock data")
            } else {
                XCTFail("Log for the test date was not found")
            }
            expectation.fulfill()
        }

        waitForExpectations(timeout: 5)
    }

}

