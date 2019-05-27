//
//  TrackService.swift
//  ARKit+CoreLocation
//
//  Created by Eric Internicola on 8/10/18.
//  Copyright © 2018 Project Dent. All rights reserved.
//

import Foundation
import GeoTrackKit
import UIKit

class TrackService {
    static let shared = TrackService()
    var track: GeoTrack!

    init() {
        track = trackFile
    }
}

// MARK: - Implementation

extension TrackService {

    var trackFile: GeoTrack? {
        guard let filename = Bundle.main.path(forResource: "block", ofType: "json") else {
            return nil
        }
        guard let data = try? Data.init(contentsOf: URL(fileURLWithPath: filename)) else {
            return nil
        }
        guard let jsonData = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) else {
            return nil
        }
        guard let map = jsonData as? [String: Any] else {
            return nil
        }
        return GeoTrack.fromMap(map: map)
    }
}
