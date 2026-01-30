//
//  SceneLocationViewDelegate.swift
//  ARKit+CoreLocation
//
//  Created by Ilya Seliverstov on 09/08/2017.
//  Copyright © 2017 Project Dent. All rights reserved.
//

import Foundation
import ARKit
import CoreLocation
import MapKit

// Delegate for touch events on LocationNode
public protocol LNTouchDelegate: AnyObject {
    func annotationNodeTouched(node: AnnotationNode)
    func locationNodeTouched(node: LocationNode)
}

public protocol SceneLocationViewEstimateDelegate: AnyObject {
    func didAddSceneLocationEstimate(sceneLocationView: SceneLocationView, position: SCNVector3, location: CLLocation)
    func didRemoveSceneLocationEstimate(sceneLocationView: SceneLocationView, position: SCNVector3, location: CLLocation)
}

public extension SceneLocationViewEstimateDelegate {
    func didAddSceneLocationEstimate(sceneLocationView: SceneLocationView, position: SCNVector3, location: CLLocation) {
        //
    }
    func didRemoveSceneLocationEstimate(sceneLocationView: SceneLocationView, position: SCNVector3, location: CLLocation) {
        //
    }
}

public protocol SceneLocationViewDelegate: AnyObject {
    ///After a node's location is initially set based on current location,
    ///it is later confirmed once the user moves far enough away from it.
    ///This update uses location data collected since the node was placed to give a more accurate location.
    func didConfirmLocationOfNode(sceneLocationView: SceneLocationView, node: LocationNode)

    func didSetupSceneNode(sceneLocationView: SceneLocationView, sceneNode: SCNNode)

    func didUpdateLocationAndScaleOfLocationNode(sceneLocationView: SceneLocationView, locationNode: LocationNode)
}

/// Subset of delegate methods from ARSCNViewDelegate to be notified on tracking status changes
public protocol SceneTrackingDelegate: AnyObject {

    func sessionWasInterrupted(_ session: ARSession)

    func sessionInterruptionEnded(_ session: ARSession)

    func session(_ session: ARSession, didFailWithError error: Error)

    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera)

}

public extension SceneLocationViewDelegate {
    func didAddSceneLocationEstimate(sceneLocationView: SceneLocationView, position: SCNVector3, location: CLLocation) {
        //
    }
    func didRemoveSceneLocationEstimate(sceneLocationView: SceneLocationView, position: SCNVector3, location: CLLocation) {
        //
    }

    func didConfirmLocationOfNode(sceneLocationView: SceneLocationView, node: LocationNode) {
        //
    }
    func didSetupSceneNode(sceneLocationView: SceneLocationView, sceneNode: SCNNode) {
        //
    }

    func didUpdateLocationAndScaleOfLocationNode(sceneLocationView: SceneLocationView, locationNode: LocationNode) {
        //
    }
}
