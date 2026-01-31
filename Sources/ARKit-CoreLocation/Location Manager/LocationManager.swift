//
//  LocationManager.swift
//  ARKit+CoreLocation
//
//  Created by Andrew Hart on 02/07/2017.
//  Copyright © 2017 Project Dent. All rights reserved.
//

import Foundation
import CoreLocation
import Combine

protocol LocationManagerDelegate: AnyObject {
    func locationManagerDidUpdateLocation(_ locationManager: LocationManager,
                                          location: CLLocation)
    func locationManagerDidUpdateHeading(_ locationManager: LocationManager,
                                         heading: CLLocationDirection,
                                         accuracy: CLLocationDirection)
}

extension LocationManagerDelegate {
    func locationManagerDidUpdateLocation(_ locationManager: LocationManager,
                                          location: CLLocation) { }

    func locationManagerDidUpdateHeading(_ locationManager: LocationManager,
                                         heading: CLLocationDirection,
                                         accuracy: CLLocationDirection) { }
}

/// Represents heading information with direction and accuracy
public struct HeadingUpdate {
    public let direction: CLLocationDirection
    public let accuracy: CLLocationDirection
}

/// Handles retrieving the location and heading from CoreLocation
/// Does not contain anything related to ARKit or advanced location
public class LocationManager: NSObject {
    weak var delegate: LocationManagerDelegate?

    private var locationManager: CLLocationManager?

    var currentLocation: CLLocation?

    private(set) public var heading: CLLocationDirection?
    private(set) public var headingAccuracy: CLLocationDirection?

    // MARK: - Combine Publishers

    /// Publisher that emits location updates
    public let locationPublisher = PassthroughSubject<CLLocation, Never>()

    /// Publisher that emits heading updates
    public let headingPublisher = PassthroughSubject<HeadingUpdate, Never>()

    /// Publisher that emits authorization status changes
    public let authorizationPublisher = PassthroughSubject<CLAuthorizationStatus, Never>()

    // MARK: - Async/Await Support

    private var locationContinuations: [UUID: AsyncStream<CLLocation>.Continuation] = [:]
    private var headingContinuations: [UUID: AsyncStream<HeadingUpdate>.Continuation] = [:]
    private let continuationLock = NSLock()

    /// An AsyncStream that yields location updates
    /// Use this with Swift's async/await pattern: `for await location in locationManager.locations { ... }`
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

    /// An AsyncStream that yields heading updates
    /// Use this with Swift's async/await pattern: `for await heading in locationManager.headings { ... }`
    public var headings: AsyncStream<HeadingUpdate> {
        AsyncStream { continuation in
            let id = UUID()
            continuationLock.lock()
            headingContinuations[id] = continuation
            continuationLock.unlock()

            continuation.onTermination = { [weak self] _ in
                self?.continuationLock.lock()
                self?.headingContinuations.removeValue(forKey: id)
                self?.continuationLock.unlock()
            }
        }
    }

    /// Waits for the next location update asynchronously
    public func waitForNextLocation() async -> CLLocation? {
        await withCheckedContinuation { continuation in
            var cancellable: AnyCancellable?
            cancellable = locationPublisher
                .first()
                .sink { location in
                    continuation.resume(returning: location)
                    cancellable?.cancel()
                }
        }
    }

    override init() {
        super.init()

        self.locationManager = CLLocationManager()
        self.locationManager!.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        self.locationManager!.distanceFilter = kCLDistanceFilterNone
        self.locationManager!.headingFilter = kCLHeadingFilterNone
        self.locationManager!.pausesLocationUpdatesAutomatically = false
        self.locationManager!.delegate = self
        self.locationManager!.startUpdatingHeading()
        self.locationManager!.startUpdatingLocation()

        self.locationManager!.requestWhenInUseAuthorization()

        self.currentLocation = self.locationManager!.location
    }

    func requestAuthorization() {
        guard let locationManager = locationManager else { return }

        let status = locationManager.authorizationStatus
        switch status {
        case .authorizedAlways, .authorizedWhenInUse:
            return
        case .denied, .restricted:
            return
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        @unknown default:
            locationManager.requestWhenInUseAuthorization()
        }
    }
}

// MARK: - CLLocationManagerDelegate

extension LocationManager: CLLocationManagerDelegate {

    public func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationPublisher.send(manager.authorizationStatus)
    }

    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        locations.forEach { location in
            delegate?.locationManagerDidUpdateLocation(self, location: location)
            locationPublisher.send(location)

            // Yield to async streams
            continuationLock.lock()
            locationContinuations.values.forEach { $0.yield(location) }
            continuationLock.unlock()
        }

        self.currentLocation = manager.location
    }

    public func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        heading = newHeading.headingAccuracy >= 0 ? newHeading.trueHeading : newHeading.magneticHeading
        headingAccuracy = newHeading.headingAccuracy

        if let heading = heading {
            let update = HeadingUpdate(direction: heading, accuracy: newHeading.headingAccuracy)
            delegate?.locationManagerDidUpdateHeading(self, heading: heading, accuracy: newHeading.headingAccuracy)
            headingPublisher.send(update)

            // Yield to async streams
            continuationLock.lock()
            headingContinuations.values.forEach { $0.yield(update) }
            continuationLock.unlock()
        }
    }

    public func locationManagerShouldDisplayHeadingCalibration(_ manager: CLLocationManager) -> Bool {
        return true
    }
}
