//
//  PedometerDataProviderTests.swift
//  myPedometerTests
//
//  Created by Sam Roman on 1/24/24.
//

import XCTest
import CoreData
@testable import myPedometer

class PedometerDataProviderTests: XCTestCase {

    var pedometerDataProvider: MockPedometerDataProvider!
    var inMemoryContext: NSManagedObjectContext!

    override func setUp() {
        super.setUp()
        inMemoryContext = PersistenceController.inMemoryContext()
        pedometerDataProvider = MockPedometerDataProvider(context: inMemoryContext) 
    }

    override func tearDown() {
        pedometerDataProvider = nil
        inMemoryContext = nil
        super.tearDown()
    }

    func testFetchSteps() {
        let expectation = self.expectation(description: "FetchSteps")

        let testDate = Date()
        pedometerDataProvider.fetchSteps(for: testDate) { steps, error in
            XCTAssertNil(error, "There should be no error")
            XCTAssert(steps >= 0, "Steps should be non-negative")

            expectation.fulfill()
        }

        waitForExpectations(timeout: 5) { error in
            if let error = error {
                XCTFail("waitForExpectationsWithError: \(error)")
            }
        }
    }
    
    func testFetchSpecificDateSteps() {
        let expectation = self.expectation(description: "FetchSpecificDateSteps")

        // The specificDate is the date of the last entry in stepDataList
        let specificDate = pedometerDataProvider.stepDataList.last?.date ?? Date()
        let specificStepsCount = 10000  // The specific step count set in the mock data

        pedometerDataProvider.fetchSteps(for: specificDate) { steps, error in
            XCTAssertNil(error, "There should be no error")
            XCTAssertEqual(steps, specificStepsCount, "Steps for the specific date should be \(specificStepsCount)")
            expectation.fulfill()
        }

        waitForExpectations(timeout: 5) { error in
            if let error = error {
                XCTFail("waitForExpectationsWithError: \(error)")
            }
        }
    }
    
    func testTodayLogInitialization() {
        let today = Calendar.current.startOfDay(for: Date())
        XCTAssertNotNil(pedometerDataProvider.todayLog, "Today's log should be initialized")

        if let todayLogDate = pedometerDataProvider.todayLog?.date {
            XCTAssertTrue(Calendar.current.isDate(todayLogDate, inSameDayAs: today), "Today's log should have today's date")
        } else {
            XCTFail("Today's log date is nil")
        }
    }
    
    func testStepIncrementSimulation() {
        let initialSteps = pedometerDataProvider.todayLog?.totalSteps ?? 0
        let expectation = self.expectation(description: "StepIncrementSimulation")

        // Simulate waiting for some time
        DispatchQueue.main.asyncAfter(deadline: .now() + 30) {
            let newSteps = self.pedometerDataProvider.todayLog?.totalSteps ?? 0
            XCTAssertGreaterThan(newSteps, initialSteps, "Steps should have increased")
            expectation.fulfill()
        }

        waitForExpectations(timeout: 30)
    }

    func testFetchFlightsData() {
        let expectation = self.expectation(description: "FetchFlightsData")
        
        let testDate = Date()
        pedometerDataProvider.fetchFlights(for: testDate) { ascended, descended, error in
            XCTAssertNil(error, "There should be no error")
            XCTAssert(ascended >= 0, "Flights ascended should be non-negative")
            XCTAssert(descended >= 0, "Flights descended should be non-negative")
            expectation.fulfill()
        }

        waitForExpectations(timeout: 5)
    }

    func testFetchHourlyStepData() {
        let expectation = self.expectation(description: "FetchHourlyStepData")
        
        // Normalize testDate to the start of the day
        let calendar = Calendar.current
        let testDate = calendar.startOfDay(for: Date())

        pedometerDataProvider.fetchHourlyStepData(for: testDate) { hourlySteps in
            XCTAssertEqual(hourlySteps.count, 24, "There should be 24 hourly data points")
            for steps in hourlySteps {
                XCTAssert(steps >= 0, "Hourly steps should be non-negative")
            }
            expectation.fulfill()
        }

        waitForExpectations(timeout: 5)
    }

}
