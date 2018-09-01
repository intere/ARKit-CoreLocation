//
//  RealWorldLocationService.swift
//  ARKit+CoreLocation
//
//  Created by Eric Internicola on 8/31/18.
//  Copyright © 2018 Project Dent. All rights reserved.
//

import Foundation

/// Keeps track of the real world location points (GeoCodeResult objects) that
/// you have represented in the app.
class RealWorldLocationService {

    static let shared = RealWorldLocationService()

    /// The real world points
    var worldPoints = [GeoCodeResult]() {
        didSet {
            Notification.ArClExample.locationsUpdated.notify()
            saveToDefaults()
        }
    }

    init() {
        loadFromDefaults()
    }

}

// MARK: - Implementation

extension RealWorldLocationService {

    struct Constants {
        static let worldPointsKey = "arcl.example.world.points"
    }

    func loadFromDefaults() {
        guard let mapped = UserDefaults.standard.object(forKey: Constants.worldPointsKey) as? [[String: Any]] else {
            return
        }
        worldPoints = mapped.compactMap({ GeoCodeResult(fromMap: $0) })
    }

    func saveToDefaults() {
        let mapped = worldPoints.map { $0.toMap }
        UserDefaults.standard.set(mapped, forKey: Constants.worldPointsKey)
    }
}
