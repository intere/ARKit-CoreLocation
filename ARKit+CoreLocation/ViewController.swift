//
//  ViewController.swift
//  ARKit+CoreLocation
//
//  Created by Andrew Hart on 02/07/2017.
//  Copyright © 2017 Project Dent. All rights reserved.
//

import ARCL
import Cartography
import MapKit
import SceneKit
import UIKit

@available(iOS 11.0, *)
class ViewController: UIViewController {
    let sceneLocationView = SceneLocationView()

    let mapView = MKMapView()
    var userAnnotation: MKPointAnnotation?
    var locationEstimateAnnotation: MKPointAnnotation?

    var updateUserLocationTimer: Timer?

    /// Whether to show a map view
    /// The initial value is respected
    var showMapView: Bool = true

    var centerMapOnUserLocation: Bool = true

    /// Whether to display some debugging data
    /// This currently displays the coordinate of the best location estimate
    /// The initial value is respected
    var displayDebugging = false

    var infoLabel = UILabel()

    var updateInfoLabelTimer: Timer?

    var adjustNorthByTappingSidesOfScreen = false

    /// A collection of the points on the map
    var mapAnnotationViews = [MKMarkerAnnotationView]()

    /// A collection of the real world points
    var trackNodes = [LocationAnnotationNode]()

    /// Should we render the track or not?
    var renderTrack = false

    let manageLocationsButton = UIButton(type: .custom)
    let addCurrentLocationButton = UIButton(type: .custom)
    let resetButton = UIButton(type: .custom)

    override func viewDidLoad() {
        super.viewDidLoad()

        infoLabel.font = UIFont.systemFont(ofSize: 10)
        infoLabel.textAlignment = .left
        infoLabel.textColor = UIColor.white
        infoLabel.numberOfLines = 0
        sceneLocationView.addSubview(infoLabel)

        manageLocationsButton.setTitle("🏠", for: .normal)
        manageLocationsButton.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        manageLocationsButton.titleLabel?.font = UIFont.systemFont(ofSize: 24)
        manageLocationsButton.addTarget(self, action: #selector(tappedFindLocation), for: .touchUpInside)
        sceneLocationView.addSubview(manageLocationsButton)

        addCurrentLocationButton.setTitle("🚩", for: .normal)
        addCurrentLocationButton.titleLabel?.font = UIFont.systemFont(ofSize: 24)
        addCurrentLocationButton.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        addCurrentLocationButton.addTarget(self, action: #selector(tappedAddCurrentLocation), for: .touchUpInside)
        sceneLocationView.addSubview(addCurrentLocationButton)

        resetButton.setTitle("♻️", for: .normal)
        resetButton.titleLabel?.font = UIFont.systemFont(ofSize: 24)
        resetButton.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        resetButton.addTarget(self, action: #selector(tappedReset), for: .touchUpInside)
        sceneLocationView.addSubview(resetButton)

        constrain(sceneLocationView, manageLocationsButton, addCurrentLocationButton, resetButton) { v, mlb, aclb, rb in
            mlb.top == v.top + 38
            mlb.right == v.right - 8
            aclb.top == mlb.top
            aclb.right == mlb.left - 8
            rb.top == aclb.top
            rb.right == aclb.left - 8

            mlb.width == 40
            mlb.height == 40
            aclb.width == 40
            aclb.height == 40
            rb.width == 40
            rb.height == 40
        }

        updateInfoLabelTimer = Timer.scheduledTimer(
            timeInterval: 0.1,
            target: self,
            selector: #selector(ViewController.updateInfoLabel),
            userInfo: nil,
            repeats: true)

        // Set to true to display an arrow which points north.
        //Checkout the comments in the property description and on the readme on this.
        sceneLocationView.orientToTrueNorth = true

//        sceneLocationView.locationEstimateMethod = .coreLocationDataOnly
        sceneLocationView.showAxesNode = true
        sceneLocationView.locationViewDelegate = self

        if displayDebugging {
            sceneLocationView.showFeaturePoints = true
        }

//        buildDemoData().forEach {
//            sceneLocationView.addLocationNodeWithConfirmedLocation(locationNode: $0)
//            trackNodes.append($0)
//        }

        view.addSubview(sceneLocationView)

        if showMapView {
            mapView.delegate = self
            mapView.showsUserLocation = true
            mapView.alpha = 0.8
            view.addSubview(mapView)

            updateUserLocationTimer = Timer.scheduledTimer(
                timeInterval: 0.5,
                target: self,
                selector: #selector(ViewController.updateUserLocation),
                userInfo: nil,
                repeats: true)
        }

        renderLocations()

        Notification.ArClExample.locationsUpdated.addObserver(observer: self, selector: #selector(renderLocations))
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        print("run")
        sceneLocationView.run()
        renderLocations()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        print("pause")
        // Pause the view's session
        sceneLocationView.pause()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        sceneLocationView.frame = view.bounds

        infoLabel.frame = CGRect(x: 6, y: 0, width: self.view.frame.size.width - 12, height: 14 * 4)

        if showMapView {
            infoLabel.frame.origin.y = (self.view.frame.size.height / 2) - infoLabel.frame.size.height
        } else {
            infoLabel.frame.origin.y = self.view.frame.size.height - infoLabel.frame.size.height
        }

        mapView.frame = CGRect(
            x: 0,
            y: self.view.frame.size.height / 2,
            width: self.view.frame.size.width,
            height: self.view.frame.size.height / 2)
    }

    @objc
    func updateUserLocation() {
        guard let currentLocation = sceneLocationView.currentLocation() else {
            return
        }

        DispatchQueue.main.async {
            self.updateMapViewAnnotationViews()
            self.updateMapViewAnnotations()
            self.toggleRealWorldPoints()

            if self.displayDebugging, let bestEstimate = self.sceneLocationView.bestLocationEstimate(),
                let position = self.sceneLocationView.currentScenePosition {
                print("")
                print("Fetch current location")
                print("best location estimate, position: \(bestEstimate.position), location: \(bestEstimate.location.coordinate), accuracy: \(bestEstimate.location.horizontalAccuracy), date: \(bestEstimate.location.timestamp)")
                print("current position: \(position)")

                let translation = bestEstimate.translatedLocation(to: position)

                print("translation: \(translation)")
                print("translated location: \(currentLocation)")
                print("")
            }

            if self.userAnnotation == nil {
                self.userAnnotation = MKPointAnnotation()
                if let annotation = self.userAnnotation {
                    self.mapView.addAnnotation(annotation)
                }
            }

            UIView.animate(withDuration: 0.5, delay: 0, options: UIViewAnimationOptions.allowUserInteraction, animations: {
                self.userAnnotation?.coordinate = currentLocation.coordinate
            }, completion: nil)

            if self.centerMapOnUserLocation {
                UIView.animate(withDuration: 0.45, delay: 0, options: UIViewAnimationOptions.allowUserInteraction, animations: {
                    self.mapView.setCenter(self.userAnnotation!.coordinate, animated: false)
                }, completion: { _ in
                    self.mapView.region.span = MKCoordinateSpan(latitudeDelta: 0.0005, longitudeDelta: 0.0005)
                })
            }

            if self.displayDebugging {
                let bestLocationEstimate = self.sceneLocationView.bestLocationEstimate()
                if bestLocationEstimate != nil {
                    if self.locationEstimateAnnotation == nil {
                        self.locationEstimateAnnotation = MKPointAnnotation()
                        self.mapView.addAnnotation(self.locationEstimateAnnotation!)
                    }

                    self.locationEstimateAnnotation!.coordinate = bestLocationEstimate!.location.coordinate
                } else {
                    if self.locationEstimateAnnotation != nil {
                        self.mapView.removeAnnotation(self.locationEstimateAnnotation!)
                        self.locationEstimateAnnotation = nil
                    }
                }
            }
        }
    }

    @objc
    func updateInfoLabel() {
        if let position = sceneLocationView.currentScenePosition {
            infoLabel.text = "x: \(String(format: "%.2f", position.x)), y: \(String(format: "%.2f", position.y)), z: \(String(format: "%.2f", position.z))\n"
        }

        if let eulerAngles = sceneLocationView.currentEulerAngles {
            infoLabel.text!.append("Euler x: \(String(format: "%.2f", eulerAngles.x)), y: \(String(format: "%.2f", eulerAngles.y)), z: \(String(format: "%.2f", eulerAngles.z))\n")
        }

        if let heading = sceneLocationView.locationManager.heading,
            let accuracy = sceneLocationView.locationManager.headingAccuracy {
            infoLabel.text!.append("Heading: \(heading)º, accuracy: \(Int(round(accuracy)))º\n")
        }

        let date = Date()
        let comp = Calendar.current.dateComponents([.hour, .minute, .second, .nanosecond], from: date)

        if let hour = comp.hour, let minute = comp.minute, let second = comp.second, let nanosecond = comp.nanosecond {
            infoLabel.text!.append("\(String(format: "%02d", hour)):\(String(format: "%02d", minute)):\(String(format: "%02d", second)):\(String(format: "%03d", nanosecond / 1000000))")
        }
    }

    @IBAction
    func tappedFindLocation() {
        guard let vc = UIStoryboard(name: "GeoCodeSearch", bundle: nil).instantiateInitialViewController() else {
            return print("No initial vc to show")
        }
        present(vc, animated: true, completion: nil)
    }

    @IBAction
    func tappedAddCurrentLocation() {
        guard let image = UIImage(named: "pin") else {
            return
        }
        let annotationNode = LocationAnnotationNode(location: nil, image: image)
        annotationNode.scaleRelativeToDistance = true
        sceneLocationView.addLocationNodeForCurrentPosition(locationNode: annotationNode)
        trackNodes.append(annotationNode)
    }

    @IBAction
    func tappedReset() {
        renderLocations()
    }

    @objc
    func renderLocations() {
        if sceneLocationView.sceneNode == nil {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                self?.renderLocations()
            }
        }

        removeLocations()

        // Add the points to the ARCL frame
        buildDemoData().forEach {
            trackNodes.append($0)
            sceneLocationView.addLocationNodeWithConfirmedLocation(locationNode: $0)
        }

        if showMapView {
            addMapPointAnnotations()
        }
        renderTrackPolyline()
    }

    /// Cleans out the locations
    func removeLocations() {
        // remove from AR
        trackNodes.forEach { node in
            sceneLocationView.removeLocationNode(locationNode: node)
        }
        trackNodes.removeAll()

        // Remove from map
        if showMapView {
            mapView.removeAnnotations(mapView.annotations)
        }
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)

        guard let touch = touches.first, let touchView = touch.view else {
            return
        }

        if mapView == touchView || mapView.recursiveSubviews().contains(touchView) {
            centerMapOnUserLocation = false
        } else {

            let location = touch.location(in: self.view)

            if location.x <= 40 && adjustNorthByTappingSidesOfScreen {
                print("left side of the screen")
                sceneLocationView.moveSceneHeadingAntiClockwise()
            } else if location.x >= view.frame.size.width - 40 && adjustNorthByTappingSidesOfScreen {
                print("right side of the screen")
                sceneLocationView.moveSceneHeadingClockwise()
            }
        }
    }
}

// MARK: - MKMapViewDelegate

@available(iOS 11.0, *)
extension ViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation {
            return nil
        }

        guard let pointAnnotation = annotation as? MKPointAnnotation else {
            return nil
        }

        let marker = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: nil)
        marker.displayPriority = .required

        if pointAnnotation == self.userAnnotation {
            marker.glyphImage = UIImage(named: "user")
        } else if RealWorldLocationService.shared.has(point: pointAnnotation.coordinate) {
            marker.markerTintColor = (annotation as? CustomPointAnnotation)?.tintColor
            marker.glyphImage = UIImage(named: "home")
            mapAnnotationViews.append(marker)
        } else {
//            marker.markerTintColor = UIColor(hue: 0.267, saturation: 0.67, brightness: 0.77, alpha: 1.0)
            marker.markerTintColor = (annotation as? CustomPointAnnotation)?.tintColor
            marker.glyphImage = UIImage(named: "compass")
            mapAnnotationViews.append(marker)
        }

        return marker
    }
}

// MARK: - SceneLocationViewDelegate

@available(iOS 11.0, *)
extension ViewController: SceneLocationViewDelegate {
    func sceneLocationViewDidAddSceneLocationEstimate(sceneLocationView: SceneLocationView, position: SCNVector3, location: CLLocation) {

        if displayDebugging {
            print("add scene location estimate, position: \(position), location: \(location.coordinate), accuracy: \(location.horizontalAccuracy), date: \(location.timestamp)")
        }
    }

    func sceneLocationViewDidRemoveSceneLocationEstimate(sceneLocationView: SceneLocationView, position: SCNVector3, location: CLLocation) {
        if displayDebugging {
            print("remove scene location estimate, position: \(position), location: \(location.coordinate), accuracy: \(location.horizontalAccuracy), date: \(location.timestamp)")
        }
    }

    func sceneLocationViewDidConfirmLocationOfNode(sceneLocationView: SceneLocationView, node: LocationNode) {
    }

    func sceneLocationViewDidSetupSceneNode(sceneLocationView: SceneLocationView, sceneNode: SCNNode) {

    }

    func sceneLocationViewDidUpdateLocationAndScaleOfLocationNode(sceneLocationView: SceneLocationView, locationNode: LocationNode) {

    }
}

// MARK: - Data Helpers

@available(iOS 11.0, *)
private extension ViewController {

    func buildDemoData() -> [LocationAnnotationNode] {
        var nodes: [LocationAnnotationNode] = []

        // TODO: add a few more demo points of interest.
        // TODO: use more varied imagery.

//        let spaceNeedle = buildNode(latitude: 47.6205, longitude: -122.3493, altitude: 225, imageName: "pin")
//        nodes.append(spaceNeedle)
//
//        let empireStateBuilding = buildNode(latitude: 40.7484, longitude: -73.9857, altitude: 14.3, imageName: "pin")
//        nodes.append(empireStateBuilding)
//
//        let canaryWharf = buildNode(latitude: 51.504607, longitude: -0.019592, altitude: 236, imageName: "pin")
//        nodes.append(canaryWharf)

        if let elevation = sceneLocationView.currentLocation()?.altitude {
            RealWorldLocationService.shared.worldPoints.forEach {
                nodes.append($0.buildLocationNode(altitude: elevation))
            }
        }

        if renderTrack {
            TrackService.shared.track.points.forEach { (point) in
                nodes.append(buildNode(latitude: point.coordinate.latitude, longitude: point.coordinate.longitude, altitude: point.altitude, imageName: "point"))
            }
        }

        print("There are \(nodes.count) nodes")

        return nodes
    }

    func buildNode(latitude: CLLocationDegrees, longitude: CLLocationDegrees, altitude: CLLocationDistance, imageName: String) -> LocationAnnotationNode {
        let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        let location = CLLocation(coordinate: coordinate, altitude: altitude)
        print("build point with altitude: \(altitude)")
        let image = UIImage(named: imageName)!
        return LocationAnnotationNode(location: location, image: image)
    }

    /// Adds annotations for the track to the map
    func addMapPointAnnotations() {
        for node in trackNodes {
            guard let location = node.location else {
                continue
            }
            let annotation = CustomPointAnnotation(from: location, locationView: sceneLocationView)
            mapView.addAnnotation(annotation)
        }

        if renderTrack {
            for point in TrackService.shared.track.points {
                let annotation = CustomPointAnnotation(from: point, locationView: sceneLocationView)
                mapView.addAnnotation(annotation)
            }
        }
    }

    /// Updates the color of all of the views for us.
    func updateMapViewAnnotationViews() {
        for view in mapAnnotationViews {
            guard let annotation = view.annotation as? CustomPointAnnotation else {
                continue
            }
            view.markerTintColor = annotation.tintColor
        }
    }

    /// Updates the titles on all of the mapView annotations
    /// NOTE: You will need to call `mapView.setNeedsDisplay()`
    func updateMapViewAnnotations() {
        for annotation in mapView.annotations {
            guard let customAnnotation = annotation as? CustomPointAnnotation else {
                continue
            }
            let title = customAnnotation.title
            customAnnotation.title = title
        }
    }

    /// Hides / shows all of the real world points depending on how near / far they are.
    func toggleRealWorldPoints() {
        guard let currentLocation = sceneLocationView.currentLocation() else {
            return
        }

        for node in trackNodes {
            node.isHidden = false
        }

        // TODO: Show / Hide nodes

//        for node in trackNodes {
//            let lastState = node.isHidden
//            let hidden = !node.location.isCloseEnough(to: currentLocation)
//            node.isHidden = hidden
//
//            if lastState != hidden {
//                print("Node \(node.location.coordinate) changed to hidden=\(hidden)")
//            }
//        }
    }

    func renderTrackPolyline() {
        guard let currentLocation = sceneLocationView.currentLocation() else {
            return print("ERROR: We don't have a location yet, skipping polyline")
        }
        guard let track = TrackService.shared.track else {
            return print ("ERROR: We couldn't load the track")
        }
        sceneLocationView.addRoute(with: track.polyline)
    }

}

extension DispatchQueue {

    func asyncAfter(timeInterval: TimeInterval, execute: @escaping () -> Void) {
        asyncAfter(deadline: .now() + timeInterval, execute: execute)
    }
}

extension UIView {

    func recursiveSubviews() -> [UIView] {
        var recursiveSubviews = self.subviews

        for subview in subviews {
            recursiveSubviews.append(contentsOf: subview.recursiveSubviews())
        }

        return recursiveSubviews
    }

}

// MARK: - CLLocation Extension

extension CLLocation {

    /// Are we close enough to the other location?  This can be used to determine whether or not to show it.
    ///
    /// - Parameters:
    ///   - another: The location to check the distance to
    ///   - maxDistance: The maximum distance threshold in meters (defaults to 20).
    func isCloseEnough(to another: CLLocation, maxDistance: CLLocationDistance = 30) -> Bool {
        return distance(from: another) <= maxDistance
    }
}

// MARK: - CustomPointAnnotation

@available(iOS 11.0, *)
class CustomPointAnnotation: MKPointAnnotation {

    var location: CLLocation
    var sceneLocationView: SceneLocationView

    init(from location: CLLocation, locationView: SceneLocationView) {
        self.location = location
        self.sceneLocationView = locationView
        super.init()
        self.coordinate = location.coordinate
    }

    override var title: String? {
        get {
            guard let currentLocation = sceneLocationView.currentLocation() else {
                return nil
            }

            let distance = Float(Int(location.distance(from: currentLocation) * 100)) / 100
            return "\(distance) meters away"
        }
        set {
            super.title = newValue
        }
    }

    var tintColor: UIColor {
        if let currentLocation = sceneLocationView.currentLocation(), location.isCloseEnough(to: currentLocation) {
            return UIColor(hue: 0.267, saturation: 0.67, brightness: 0.77, alpha: 1.0)
        } else {
            return UIColor.red
        }
    }
}
