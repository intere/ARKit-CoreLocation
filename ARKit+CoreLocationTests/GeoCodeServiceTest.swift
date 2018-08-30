//
//  GeoCodeServiceTest.swift
//  ARCLTests
//
//  Created by Eric Internicola on 8/30/18.
//  Copyright © 2018 Project Dent. All rights reserved.
//

import ARCL
@testable import ARKit_CoreLocation
import CoreLocation
import XCTest

class GeoCodeServiceTest: XCTestCase {

    struct TestData {
        static let address = "13562 Vallejo St Westminster, CO"
    }

    func testGetGeoCodedResults() {
        let exp = expectation(description: "Fetch GeoCode")

        GeoCodeService.shared.getGeoCodes(for: TestData.address) { (results, error) in
            defer {
                exp.fulfill()
            }
            if let error = error {
                return XCTFail("Fetch failure: \(error.localizedDescription)")
            }
            guard let results = results else {
                return XCTFail("no results")
            }
            XCTAssertEqual(1, results.count)
            XCTAssertEqual(TestData.address, results.first?.locationString)
        }

        waitForExpectations(timeout: 5, handler: nil)
    }
}
