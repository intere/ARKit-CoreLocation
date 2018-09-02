//
//  GeoCodeResult.swift
//  ARKit+CoreLocation
//
//  Created by Eric Internicola on 8/30/18.
//  Copyright © 2018 Project Dent. All rights reserved.
//

import ARCL
import CoreLocation
import Foundation
import UIKit

class GeoCodeResult {

    let locationString: String
    let location: CLLocationCoordinate2D
    let displayLocation: CLLocationCoordinate2D
    let city: String
    let state: String

    /// Use this initializer to deserialize an object from the "toMap" variable.
    ///
    /// - Parameter map: The serialized map of a GeoCodeResult object to deserialize from.
    convenience init?(fromMap map: [String: Any]) {
        guard let locationString = map["locationString"] as? String else {
            return nil
        }
        self.init(fromMap: map, locationString: locationString)
    }

    /// Use this initializer to deserialize an object from the MapQuest Geocode API.
    ///
    /// - Parameters:
    ///   - map: The map of data for everything (but the locationString) for this object.
    ///   - locationString: The Location String (essentially what you searched for).
    init?(fromMap map: [String: Any], locationString: String) {
        guard let latLng = map["latLng"] as? [String: Any],
            let displayLatLng = map["displayLatLng"] as? [String: Any],
            let lat = latLng["lat"] as? CLLocationDegrees,
            let lon = latLng["lng"] as? CLLocationDegrees,
            let displayLat = displayLatLng["lat"] as? CLLocationDegrees,
            let displayLon = displayLatLng["lng"] as? CLLocationDegrees else {
                return nil
        }
        self.locationString = locationString
        location = CLLocationCoordinate2D(latitude: lat, longitude: lon)
        displayLocation = CLLocationCoordinate2D(latitude: displayLat, longitude: displayLon)
        city = GeoCodeResult.getCity(from: map)
        state = GeoCodeResult.getState(from: map)
    }

    /// Builds you a location (real world node) from this GeoCodeResult
    func buildLocationNode(altitude: CLLocationDistance) -> LocationAnnotationNode {
        let node = buildNode(latitude: location.latitude, longitude: location.longitude, altitude: altitude, imageName: "house")
        node.scaleRelativeToDistance = true
        return node
    }

    /// Gets you the string to display this geo coded result in a table cell.
    var cellDisplayText: String {
        var result = locationString
        if !city.isEmpty && !state.isEmpty {
            result += "\n\(city), \(state)"
        } else if !city.isEmpty {
            result += "\n\(city)"
        } else if !state.isEmpty {
            result += "\n\(state)"
        }

        return result
    }

    /// Builds you a map for serialization
    var toMap: [String: Any] {
        var result = [String: Any]()
        result["latLng"] = [
            "lat": location.latitude,
            "lng": location.longitude
        ]

        result["displayLatLng"] = [
            "lat": displayLocation.latitude,
            "lng": displayLocation.longitude
        ]
        result["locationString"] = locationString
        if !city.isEmpty {
            result["adminArea1Type"] = "City"
            result["adminArea1"] = city
        }
        if !state.isEmpty {
            result["adminArea2Type"] = "State"
            result["adminArea2"] = state
        }

        return result
    }
}

// MARK: - Implementation

extension GeoCodeResult {

    func buildNode(latitude: CLLocationDegrees, longitude: CLLocationDegrees, altitude: CLLocationDistance, imageName: String) -> LocationAnnotationNode {
        let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        let location = CLLocation(coordinate: coordinate, altitude: altitude)
        let image = UIImage(named: imageName)!
        return LocationAnnotationNode(location: location, image: image)
    }

    /// Parses the city from the map.
    ///
    /// - Parameter map: The map to find the city from.
    /// - Returns: The city value (or empty string if not found).
    static func getCity(from map: [String: Any]) -> String {

        for i in 1...6 {
            guard (map["adminArea\(i)Type"] as? String) == "City" else {
                continue
            }
            return map["adminArea\(i)"] as? String ?? ""
        }

        return ""
    }

    /// Parses the state from the map.
    ///
    /// - Parameter map: The map to find the state from.
    /// - Returns: The state value (or empty string if not found).
    static func getState(from map: [String: Any]) -> String {
        for i in 1...6 {
            guard (map["adminArea\(i)Type"] as? String) == "State" else {
                continue
            }
            return map["adminArea\(i)"] as? String ?? ""
        }

        return ""
    }
}
