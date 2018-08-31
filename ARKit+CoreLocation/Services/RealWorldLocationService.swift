//
//  RealWorldLocationService.swift
//  ARKit+CoreLocation
//
//  Created by Eric Internicola on 8/31/18.
//  Copyright © 2018 Project Dent. All rights reserved.
//

import Foundation

class RealWorldLocationService {

    static let shared = RealWorldLocationService()

    /// The real world points
    var worldPoints = [GeoCodeResult]() {
        didSet {
            Notification.ArClExample.locationsUpdated.notify()
        }
    }

}
