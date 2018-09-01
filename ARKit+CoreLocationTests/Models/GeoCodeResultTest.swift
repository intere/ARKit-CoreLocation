//
//  GeoCodeResultTest.swift
//  ARKit+CoreLocationTests
//
//  Created by Eric Internicola on 9/1/18.
//  Copyright © 2018 Project Dent. All rights reserved.
//

@testable import ARKit_CoreLocation
import XCTest

class GeoCodeResultTest: XCTestCase {

    /// Verifies that we can serialize into a map and then deserialize back into
    /// GeoCodeResult objects
    func testSerializeDeserialize() {
        let exp = expectation(description: "Search Results")
        var originalObjects = [GeoCodeResult]()
        GeoCodeService.shared.getGeoCodes(for: "450 Main Street, Colorado") { (results, error) in
            defer {
                exp.fulfill()
            }
            if let error = error {
                return XCTFail(error.localizedDescription)
            }
            guard let results = results else {
                return XCTFail("No results came back")
            }
            originalObjects.append(contentsOf: results)
        }
        waitForExpectations(timeout: 5, handler: nil)
        XCTAssertNotEqual(0, originalObjects.count)

        let mapped = originalObjects.map { $0.toMap }

        for map in mapped {
            guard let deserialized = GeoCodeResult(fromMap: map) else {
                XCTFail("Failed to deserialize map: \(map)")
                continue
            }
            XCTAssertNotEqual("", deserialized.city)
            XCTAssertNotEqual("", deserialized.state)
            XCTAssertNotEqual("", deserialized.locationString)
        }
    }
}
