//
//  GeoTrackKit+MapKit.swift
//  ARKit+CoreLocation
//
//  Created by Eric Internicola on 9/21/18.
//  Copyright © 2018 Project Dent. All rights reserved.
//

import GeoTrackKit
import MapKit

extension GeoTrack {

    var coordinates: [CLLocationCoordinate2D] {
        let coordsPointer = UnsafeMutablePointer<CLLocationCoordinate2D>.allocate(capacity: points.count)
        var coords: [CLLocationCoordinate2D] = []
        points.forEach { coords.append($0.coordinate) }
        coordsPointer.deallocate()
        return coords
    }

    var polyline: MKPolyline {
        return MKPolyline(coordinates: coordinates, count: points.count)
    }
}
