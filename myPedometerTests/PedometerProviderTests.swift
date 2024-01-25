//
//  PedometerProviderTests.swift
//  myPedometerTests
//
//  Created by Sam Roman on 1/24/24.
//

import XCTest
@testable import myPedometer

class PedometerDataProviderTests: XCTestCase {

    var pedometerDataProvider: PedometerDataProvider!

    override func setUp() {
        super.setUp()
        pedometerDataProvider = MockPedometerDataProvider()
    }

    override func tearDown() {
        pedometerDataProvider = nil
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
        
        let specificDate = Calendar.current.date(from: DateComponents(year: 2021, month: 1, day: 1))!
        pedometerDataProvider.fetchSteps(for: specificDate) { steps, error in
            XCTAssertNil(error, "There should be no error")
            XCTAssertEqual(steps, 10000, "Steps for January 1, 2021 should be 10000")
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 5) { error in
            if let error = error {
                XCTFail("waitForExpectationsWithError: \(error)")
            }
        }
    }

}
