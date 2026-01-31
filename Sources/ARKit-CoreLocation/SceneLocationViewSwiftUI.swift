//
//  SceneLocationViewSwiftUI.swift
//  ARKit+CoreLocation
//
//  SwiftUI wrapper for SceneLocationView
//

import SwiftUI
import ARKit
import CoreLocation
import Combine

/// A SwiftUI wrapper for `SceneLocationView` that enables AR location-based experiences.
///
/// Usage:
/// ```swift
/// struct ContentView: View {
///     @StateObject private var viewModel = ARCLViewModel()
///
///     var body: some View {
///         ARCLView(
///             trackingType: .worldTracking,
///             onSceneLocationViewCreated: { sceneView in
///                 viewModel.sceneLocationView = sceneView
///             }
///         )
///         .onAppear {
///             viewModel.addAnnotations()
///         }
///     }
/// }
/// ```
public struct ARCLView: UIViewRepresentable {
    public typealias UIViewType = SceneLocationView

    /// The type of AR tracking to use
    public var trackingType: SceneLocationView.ARTrackingType

    /// Whether to orient the scene to true north
    public var orientToTrueNorth: Bool

    /// Whether to show feature points for debugging
    public var showFeaturePoints: Bool

    /// Whether to show an axes node at the scene origin
    public var showAxesNode: Bool

    /// Callback when the SceneLocationView is created
    public var onSceneLocationViewCreated: ((SceneLocationView) -> Void)?

    /// Callback for location updates
    public var onLocationUpdate: ((CLLocation) -> Void)?

    /// Creates a new ARCLView
    /// - Parameters:
    ///   - trackingType: The type of AR tracking (default: .worldTracking)
    ///   - orientToTrueNorth: Whether to orient to true north (default: true)
    ///   - showFeaturePoints: Show AR feature points for debugging (default: false)
    ///   - showAxesNode: Show axes at scene origin for debugging (default: false)
    ///   - onSceneLocationViewCreated: Callback when the view is created
    ///   - onLocationUpdate: Callback for location updates
    public init(
        trackingType: SceneLocationView.ARTrackingType = .worldTracking,
        orientToTrueNorth: Bool = true,
        showFeaturePoints: Bool = false,
        showAxesNode: Bool = false,
        onSceneLocationViewCreated: ((SceneLocationView) -> Void)? = nil,
        onLocationUpdate: ((CLLocation) -> Void)? = nil
    ) {
        self.trackingType = trackingType
        self.orientToTrueNorth = orientToTrueNorth
        self.showFeaturePoints = showFeaturePoints
        self.showAxesNode = showAxesNode
        self.onSceneLocationViewCreated = onSceneLocationViewCreated
        self.onLocationUpdate = onLocationUpdate
    }

    public func makeUIView(context: Context) -> SceneLocationView {
        let sceneLocationView = SceneLocationView(trackingType: trackingType)
        sceneLocationView.orientToTrueNorth = orientToTrueNorth
        sceneLocationView.showFeaturePoints = showFeaturePoints
        sceneLocationView.showAxesNode = showAxesNode

        // Set up coordinator as delegate
        sceneLocationView.locationViewDelegate = context.coordinator
        sceneLocationView.sceneTrackingDelegate = context.coordinator

        // Subscribe to location updates
        context.coordinator.setupLocationSubscription(sceneLocationView: sceneLocationView)

        // Notify that the view was created
        onSceneLocationViewCreated?(sceneLocationView)

        // Start the AR session
        sceneLocationView.run()

        return sceneLocationView
    }

    public func updateUIView(_ uiView: SceneLocationView, context: Context) {
        uiView.orientToTrueNorth = orientToTrueNorth
        uiView.showFeaturePoints = showFeaturePoints
        uiView.showAxesNode = showAxesNode
    }

    public static func dismantleUIView(_ uiView: SceneLocationView, coordinator: Coordinator) {
        uiView.pause()
        coordinator.cancellables.removeAll()
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator(onLocationUpdate: onLocationUpdate)
    }

    // MARK: - Coordinator

    public class Coordinator: NSObject, SceneLocationViewDelegate, SceneTrackingDelegate {
        var onLocationUpdate: ((CLLocation) -> Void)?
        var cancellables = Set<AnyCancellable>()

        init(onLocationUpdate: ((CLLocation) -> Void)?) {
            self.onLocationUpdate = onLocationUpdate
        }

        func setupLocationSubscription(sceneLocationView: SceneLocationView) {
            sceneLocationView.sceneLocationManager.currentLocationPublisher
                .receive(on: DispatchQueue.main)
                .sink { [weak self] location in
                    self?.onLocationUpdate?(location)
                }
                .store(in: &cancellables)
        }

        // MARK: - SceneLocationViewDelegate

        public func didConfirmLocationOfNode(sceneLocationView: SceneLocationView, node: LocationNode) {
            // Override in subclass if needed
        }

        public func didSetupSceneNode(sceneLocationView: SceneLocationView, sceneNode: SCNNode) {
            // Override in subclass if needed
        }

        public func didUpdateLocationAndScaleOfLocationNode(sceneLocationView: SceneLocationView, locationNode: LocationNode) {
            // Override in subclass if needed
        }

        // MARK: - SceneTrackingDelegate

        public func sessionWasInterrupted(_ session: ARSession) {
            // Override in subclass if needed
        }

        public func sessionInterruptionEnded(_ session: ARSession) {
            // Override in subclass if needed
        }

        public func session(_ session: ARSession, didFailWithError error: Error) {
            // Override in subclass if needed
        }

        public func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
            // Override in subclass if needed
        }
    }
}

// MARK: - View Modifiers

public extension ARCLView {
    /// Sets whether to show feature points for debugging
    func showingFeaturePoints(_ show: Bool) -> ARCLView {
        var view = self
        view.showFeaturePoints = show
        return view
    }

    /// Sets whether to show an axes node at the scene origin
    func showingAxesNode(_ show: Bool) -> ARCLView {
        var view = self
        view.showAxesNode = show
        return view
    }

    /// Sets whether to orient the scene to true north
    func orientingToTrueNorth(_ orient: Bool) -> ARCLView {
        var view = self
        view.orientToTrueNorth = orient
        return view
    }
}

// MARK: - Preview Provider

#if DEBUG
struct ARCLView_Previews: PreviewProvider {
    static var previews: some View {
        ARCLView()
    }
}
#endif
