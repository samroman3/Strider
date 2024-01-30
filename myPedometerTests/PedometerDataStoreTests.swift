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

    func testFetchExistingDailyLog() {
        let testDate = Calendar.current.startOfDay(for: Date())
        let existingLog = DailyLog(context: inMemoryContext)
        existingLog.date = testDate
        try! inMemoryContext.save()

        let expectation = self.expectation(description: "FetchExistingDailyLog")

        dataStore.fetchOrCreateDailyLog(for: testDate) { log, error in
            XCTAssertNil(error, "No error should be returned")
            XCTAssertEqual(log.date, testDate, "Fetched log should have the same date")
            expectation.fulfill()
        }

        waitForExpectations(timeout: 5)
    }
    
    func testCreateNewDailyLog() {
        let testDate = Calendar.current.startOfDay(for: Date())

        let expectation = self.expectation(description: "CreateNewDailyLog")

        dataStore.fetchOrCreateDailyLog(for: testDate) { log, error in
            XCTAssertNil(error, "No error should be returned")
            XCTAssertEqual(log.date, testDate, "Created log should have the correct date")
            expectation.fulfill()
        }

        waitForExpectations(timeout: 5)
    }
}
