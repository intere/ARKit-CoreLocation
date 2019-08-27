//
//  StatesDemoData.swift
//  ARKit+CoreLocation
//
//  Created by Eric Internicola on 7/7/19.
//  Copyright © 2019 Project Dent. All rights reserved.
//

import ARCL
import CoreLocation
import Foundation

@available(iOS 11.0, *)
struct USState {
    let imageName: String
    let coordinate: CLLocationCoordinate2D

    /// Gets you the collection of all states that we're demo-ing
    static let all: [USState] = {
        return [
            USState(imageName: "alaska", coordinate: CLLocationCoordinate2D(latitude: 61.370716, longitude: -152.404419)),
            USState(imageName: "california", coordinate: CLLocationCoordinate2D(latitude: 36.116203, longitude: -119.681564)),
            USState(imageName: "florida", coordinate: CLLocationCoordinate2D(latitude: 27.766279, longitude: -81.686783)),
            USState(imageName: "new-york", coordinate: CLLocationCoordinate2D(latitude: 42.165726, longitude: -74.948051)),
            USState(imageName: "texas", coordinate: CLLocationCoordinate2D(latitude: 31.054487, longitude: -97.563461))
        ]
    }()

    /// Adds all of the USStates to the provided scene at the provided elevation.
    ///
    /// - Parameters:
    ///   - scene: The `SceneLocationView` to add the USStates to.
    ///   - elevation: the elevation to add them at.
    static func addAll(to scene: SceneLocationView, withElevation elevation: CLLocationDistance) {
        all.compactMap({ $0.locationAnnotationNode(elevation: elevation) }).forEach { stateNode in
            scene.addLocationNodeWithConfirmedLocation(locationNode: stateNode)
        }
    }

    /// Creates a LocationAnnotationNode for this USState at the provided elevation.
    ///
    /// - Parameter elevation: The elevation to show the node at
    /// - Returns: A LocationAnnotationNode for this state (assuming we could load the image).
    func locationAnnotationNode(elevation: CLLocationDistance) -> LocationAnnotationNode? {
        guard let image = UIImage(named: imageName) else {
            assertionFailure("Failed to load image for state \(imageName)")
            return nil
        }

        let location = CLLocation(coordinate: coordinate, altitude: elevation)

        return LocationAnnotationNode(location: location, image: image)
    }

}
