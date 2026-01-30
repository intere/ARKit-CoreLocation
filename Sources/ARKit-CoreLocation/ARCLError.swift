//
//  ARCLError.swift
//  ARKit+CoreLocation
//
//  Modern error handling for ARCL
//

import Foundation
import CoreLocation

/// Errors that can occur in ARCL operations
public enum ARCLError: LocalizedError {
    /// Location services are not authorized
    case locationNotAuthorized(CLAuthorizationStatus)

    /// The current location is not available
    case locationUnavailable

    /// The scene position is not available (AR session not running)
    case scenePositionUnavailable

    /// The scene node has not been set up yet
    case sceneNodeUnavailable

    /// The node's location is not confirmed
    case nodeLocationNotConfirmed

    /// The node's location is nil
    case nodeLocationNil

    /// AR session failed
    case arSessionFailed(Error)

    /// Invalid altitude - no elevation data available
    case altitudeUnavailable

    public var errorDescription: String? {
        switch self {
        case .locationNotAuthorized(let status):
            return "Location services not authorized: \(status.description)"
        case .locationUnavailable:
            return "Current location is not available"
        case .scenePositionUnavailable:
            return "Scene position is not available. Ensure the AR session is running."
        case .sceneNodeUnavailable:
            return "Scene node has not been set up yet"
        case .nodeLocationNotConfirmed:
            return "Node location has not been confirmed"
        case .nodeLocationNil:
            return "Node location is nil"
        case .arSessionFailed(let error):
            return "AR session failed: \(error.localizedDescription)"
        case .altitudeUnavailable:
            return "Altitude data is not available"
        }
    }

    public var recoverySuggestion: String? {
        switch self {
        case .locationNotAuthorized:
            return "Request location authorization or check Settings."
        case .locationUnavailable:
            return "Wait for a location update or check if location services are enabled."
        case .scenePositionUnavailable:
            return "Call run() on the SceneLocationView before adding nodes."
        case .sceneNodeUnavailable:
            return "Wait for the AR session to initialize the scene."
        case .nodeLocationNotConfirmed:
            return "Set the node's location or wait for it to be confirmed automatically."
        case .nodeLocationNil:
            return "Provide a valid CLLocation when creating the node."
        case .arSessionFailed:
            return "Try restarting the AR session."
        case .altitudeUnavailable:
            return "Wait for location updates with altitude data."
        }
    }
}

// MARK: - CLAuthorizationStatus Description

extension CLAuthorizationStatus: CustomStringConvertible {
    public var description: String {
        switch self {
        case .notDetermined:
            return "Not Determined"
        case .restricted:
            return "Restricted"
        case .denied:
            return "Denied"
        case .authorizedAlways:
            return "Authorized Always"
        case .authorizedWhenInUse:
            return "Authorized When In Use"
        @unknown default:
            return "Unknown"
        }
    }
}

// MARK: - Result Type Aliases

/// Result type for operations that return a location
public typealias LocationResult = Result<CLLocation, ARCLError>

/// Result type for operations that add nodes
public typealias NodeAddResult = Result<Void, ARCLError>
