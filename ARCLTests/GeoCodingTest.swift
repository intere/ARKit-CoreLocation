//
//  GeoCodingTest.swift
//  ARCLTests
//
//  Created by Eric Internicola on 8/29/18.
//  Copyright © 2018 Project Dent. All rights reserved.
//

import XCTest

class GeoCodingTest: XCTestCase {

    struct TestData {
        static let address = "13562 Vallejo St Westminster, CO"
    }

    func testBuildUrl() {
        let expected = "https://www.mapquestapi.com/geocoding/v1/address?key=lYrP4vF3Uk5zgTiGGuEzQGwGIVDGuy24&inFormat=kvp&outFormat=json&location=13562+Vallejo+St+Westminster,+CO&thumMaps=false"

        guard let url = buildGeoCodeUrl(forAddress: TestData.address) else {
            return XCTFail("Failed to build GeoCode URL properly")
        }

        XCTAssertEqual(expected, url.absoluteString)
    }

    func testGetGeocoding() {
        guard let url = buildGeoCodeUrl(forAddress: TestData.address) else {
            return XCTFail("Failed to build GeoCode URL properly")
        }

        let exp = expectation(description: "Fetch GeoCode")
        URLSession.shared.dataTask(with: url) { (data, response, error) in
            defer {
                exp.fulfill()
            }
            if let error = error {
                return XCTFail("Fetch failure: \(error.localizedDescription)")
            }
            XCTAssertEqual(200, (response as? HTTPURLResponse)?.statusCode)
            guard let data = data else {
                return XCTFail("Failed to get any geocode data back")
            }
            guard let jsonData = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) else {
                return XCTFail("Failed to get json data")
            }
            guard let json = jsonData as? [String: Any] else {
                return XCTFail("Failed to get the expected type back")
            }
            XCTAssertNotNil(json["info"])
            XCTAssertNotNil(json["results"])
        }.resume()

        waitForExpectations(timeout: 5, handler: nil)
    }
}

// MARK: - Implementation

extension GeoCodingTest {

    struct Constants {
        static let baseURL = "https://www.mapquestapi.com"
        static let path = "/geocoding/v1/address"
        static let key = "lYrP4vF3Uk5zgTiGGuEzQGwGIVDGuy24"
        static let inFormat = "kvp"
        static let outFormat = "json"
        static let thumbsMaps = "false"
    }

    /// Builds the geocode url for you.
    ///
    /// - Parameter address: The address you want to geocode.
    /// - Returns: A URL (if one could be built) to hit mapquest for a geocoding.
    func buildGeoCodeUrl(forAddress address: String) -> URL? {
        guard var builder = URLComponents(string: Constants.baseURL) else {
            return nil
        }

        builder.path = Constants.path
        builder.queryItems = [
            URLQueryItem(name: "key", value: Constants.key),
            URLQueryItem(name: "inFormat", value: Constants.inFormat),
            URLQueryItem(name: "outFormat", value: Constants.outFormat),
            URLQueryItem(name: "location", value: address.replacingOccurrences(of: " ", with: "+")),
            URLQueryItem(name: "thumMaps", value: Constants.thumbsMaps)
        ]

        return builder.url
    }
}
