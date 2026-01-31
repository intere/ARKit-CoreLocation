//
//  SceneLocationManager.swift
//  ARKit+CoreLocation
//
//  Created by Ilya Seliverstov on 10/08/2017.
//  Copyright © 2017 Project Dent. All rights reserved.
//

import Foundation
import ARKit
import CoreLocation
import MapKit
import Combine

///Different methods which can be used when determining locations (such as the user's location).
public enum LocationEstimateMethod {
    ///Only uses Core Location data.
    ///Not suitable for adding nodes using current position, which requires more precision.
    case coreLocationDataOnly

    ///Combines knowledge about movement through the AR world with
    ///the most relevant Core Location estimate (based on accuracy and time).
    case mostRelevantEstimate
}

protocol SceneLocationManagerDelegate: AnyObject {
    var scenePosition: SCNVector3? { get }

    func confirmLocationOfDistantLocationNodes()
    func updatePositionAndScaleOfLocationNodes()

    func didAddSceneLocationEstimate(position: SCNVector3, location: CLLocation)
    func didRemoveSceneLocationEstimate(position: SCNVector3, location: CLLocation)
}

/// Represents a scene location estimate event
public struct SceneLocationEstimateEvent {
    public let position: SCNVector3
    public let location: CLLocation
}

public final class SceneLocationManager {
    weak var sceneLocationDelegate: SceneLocationManagerDelegate?

    public var locationEstimateMethod: LocationEstimateMethod = .mostRelevantEstimate
    public let locationManager = LocationManager()

    var sceneLocationEstimates = [SceneLocationEstimate]()

    var updateEstimatesTimer: Timer?

    // MARK: - Combine Publishers

    /// Publisher that emits when a new scene location estimate is added
    public let estimateAddedPublisher = PassthroughSubject<SceneLocationEstimateEvent, Never>()

    /// Publisher that emits when a scene location estimate is removed
    public let estimateRemovedPublisher = PassthroughSubject<SceneLocationEstimateEvent, Never>()

    /// Publisher that emits the current location (combining AR position with GPS)
    public let currentLocationPublisher = PassthroughSubject<CLLocation, Never>()

    // MARK: - Async/Await Support

    private var locationContinuations: [UUID: AsyncStream<CLLocation>.Continuation] = [:]
    private let continuationLock = NSLock()

    /// An AsyncStream that yields combined AR+GPS location updates
    /// Use this with Swift's async/await pattern: `for await location in sceneLocationManager.locations { ... }`
    public var locations: AsyncStream<CLLocation> {
        AsyncStream { continuation in
            let id = UUID()
            continuationLock.lock()
            locationContinuations[id] = continuation
            continuationLock.unlock()

            continuation.onTermination = { [weak self] _ in
                self?.continuationLock.lock()
                self?.locationContinuations.removeValue(forKey: id)
                self?.continuationLock.unlock()
            }
        }
    }

    /// Waits for the next location update asynchronously
    public func waitForNextLocation() async -> CLLocation? {
        await withCheckedContinuation { continuation in
            var cancellable: AnyCancellable?
            cancellable = currentLocationPublisher
                .first()
                .sink { location in
                    continuation.resume(returning: location)
                    cancellable?.cancel()
                }
        }
    }

    /// The best estimation of location that has been taken
    /// This takes into account horizontal accuracy, and the time at which the estimation was taken
    /// favouring the most accurate, and then the most recent result.
    /// This doesn't indicate where the user currently is.
    public var bestLocationEstimate: SceneLocationEstimate? {
        let sortedLocationEstimates = sceneLocationEstimates.sorted(by: {
            if $0.location.horizontalAccuracy == $1.location.horizontalAccuracy {
                return $0.location.timestamp > $1.location.timestamp
            }

            return $0.location.horizontalAccuracy < $1.location.horizontalAccuracy
        })

        return sortedLocationEstimates.first
    }

    public var currentLocation: CLLocation? {
        if locationEstimateMethod == .coreLocationDataOnly { return locationManager.currentLocation }

        guard let bestEstimate = bestLocationEstimate,
            let position = sceneLocationDelegate?.scenePosition else { return nil }

        return bestEstimate.translatedLocation(to: position)
    }

    init() {
        locationManager.delegate = self
    }

    deinit {
        pause()
    }

    @objc
    func updateLocationData() {
        removeOldLocationEstimates()

        sceneLocationDelegate?.confirmLocationOfDistantLocationNodes()
        sceneLocationDelegate?.updatePositionAndScaleOfLocationNodes()

        // Publish current location if available
        if let location = currentLocation {
            currentLocationPublisher.send(location)

            // Yield to async streams
            continuationLock.lock()
            locationContinuations.values.forEach { $0.yield(location) }
            continuationLock.unlock()
        }
    }

    ///Adds a scene location estimate based on current time, camera position and location from location manager
    func addSceneLocationEstimate(location: CLLocation) {
        guard let position = sceneLocationDelegate?.scenePosition else { return }

        sceneLocationEstimates.append(SceneLocationEstimate(location: location, position: position))

        sceneLocationDelegate?.didAddSceneLocationEstimate(position: position, location: location)
        estimateAddedPublisher.send(SceneLocationEstimateEvent(position: position, location: location))
    }

    func removeOldLocationEstimates() {
        guard let currentScenePosition = sceneLocationDelegate?.scenePosition else { return }
        removeOldLocationEstimates(currentScenePosition: currentScenePosition)
    }

    func removeOldLocationEstimates(currentScenePosition: SCNVector3) {
        let currentPoint = CGPoint.pointWithVector(vector: currentScenePosition)

        sceneLocationEstimates = sceneLocationEstimates.filter { estimate in
            let radiusContainsPoint = currentPoint.radiusContainsPoint(
                radius: CGFloat(SceneLocationView.sceneLimit),
                point: CGPoint.pointWithVector(vector: estimate.position))

            if !radiusContainsPoint {
                sceneLocationDelegate?.didRemoveSceneLocationEstimate(position: estimate.position, location: estimate.location)
                estimateRemovedPublisher.send(SceneLocationEstimateEvent(position: estimate.position, location: estimate.location))
            }

            return radiusContainsPoint
        }
    }

}

public extension SceneLocationManager {
    func run() {
        pause()
        updateEstimatesTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.updateLocationData()
        }
    }

    func pause() {
        updateEstimatesTimer?.invalidate()
        updateEstimatesTimer = nil
    }
}

extension SceneLocationManager: LocationManagerDelegate {

    func locationManagerDidUpdateLocation(_ locationManager: LocationManager,
                                          location: CLLocation) {
        addSceneLocationEstimate(location: location)
    }
}
