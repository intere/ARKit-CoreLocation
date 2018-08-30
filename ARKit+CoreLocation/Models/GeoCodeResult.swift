//
//  GeoCodeResult.swift
//  ARKit+CoreLocation
//
//  Created by Eric Internicola on 8/30/18.
//  Copyright © 2018 Project Dent. All rights reserved.
//

import CoreLocation
import Foundation

class GeoCodeResult {

    let locationString: String
    let location: CLLocationCoordinate2D
    let displayLocation: CLLocationCoordinate2D

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
    }
}
