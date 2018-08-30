//
//  GeoCodeService.swift
//  ARKit+CoreLocation
//
//  Created by Eric Internicola on 8/30/18.
//  Copyright © 2018 Project Dent. All rights reserved.
//

import Foundation

typealias GeoCodeCallback = ([GeoCodeResult]?, Error?) -> Void

class GeoCodeService {

    static let shared = GeoCodeService()

    /// Given an address, this will hand you back a collection of geo coded results.
    ///
    /// - Parameters:
    ///   - address: The address you want the lat/lon for.
    ///   - completion: A completion handler that gives you back a collection of
    ///     GeoCodeResult objects or an error.
    func getGeoCodes(for address: String, completion: @escaping GeoCodeCallback) {
        guard let url = buildGeoCodeUrl(forAddress: address) else {
            return completion(nil, GeoCodingError.buildUrlError)
        }

        URLSession.shared.dataTask(with: url) { (data, _, error) in
            if let error = error {
                return completion(nil, error)
            }

            guard let data = data else {
                return completion(nil, GeoCodingError.noData)
            }
            guard let jsonData = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) else {
                return completion(nil, GeoCodingError.nonJsonFormat)
            }
            guard let json = jsonData as? [String: Any],
                let jsonResults = json["results"] as? [[String: Any]],
                let providedLocation = jsonResults.first?["providedLocation"] as? [String: Any],
                let locationString = providedLocation["location"] as? String,
                let locations = jsonResults.first?["locations"] as? [[String: Any]] else {
                return completion(nil, GeoCodingError.invalidFormat)
            }

            var results = [GeoCodeResult]()

            for location in locations {
                guard let result = GeoCodeResult(fromMap: location, locationString: locationString) else {
                    continue
                }
                results.append(result)
            }

            completion(results, nil)

        }.resume()
    }
}

// MARK: - Implementation

extension GeoCodeService {

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

// MARK: - Errors

extension GeoCodeService {

    enum GeoCodingError: LocalizedError {
        case buildUrlError
        case noData
        case nonJsonFormat
        case invalidFormat

        /// A description of the error
        public var errorDescription: String? {
            switch self {
            case .buildUrlError:
                return "Failed to build a GeoCoding URL"
            case .noData:
                return "No data was returned"
            case .nonJsonFormat:
                return "The data received was not in JSON format"
            case .invalidFormat:
                return "The JSON received was in an unexpected format"

            }
        }

        /// The human readable description for the error.
        var humanReadableDescription: String {
            return errorDescription ?? "Error description not provided"
        }

    }

}
