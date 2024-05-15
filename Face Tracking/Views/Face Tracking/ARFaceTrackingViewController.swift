//
//  ARFaceTrackingViewController.swift
//  Face Tracking
//
//  Created on 15/05/24.
//  
//

import ARKit
import Foundation
import os.log
import UIKit

private let logger = Logger(subsystem: "FaceTracking", category: "ARFaceTrackingViewController")

class ARFaceTrackingViewController: UIViewController {
    private var sceneView: ARSCNView? = nil
    private var faceAnchorsNodes: [ARFaceAnchor: SCNNode] = [:]
}

// MARK: Lifecycle
extension ARFaceTrackingViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureSceneView()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        resetTracking()
    }
}

// MARK: Internals
private extension ARFaceTrackingViewController {
    func configureSceneView() {
        let sceneView = ARSCNView()
        self.sceneView = sceneView
        
        sceneView.delegate = self
        sceneView.session.delegate = self
        sceneView.automaticallyUpdatesLighting = true
        
        // Add sceneView to the view hierarchy
        view.addSubview(sceneView)
        
        // Enable auto layout for sceneView
        sceneView.translatesAutoresizingMaskIntoConstraints = false
        
        // Define constraints for sceneView
        NSLayoutConstraint.activate([
            sceneView.topAnchor.constraint(equalTo: view.topAnchor),
            sceneView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            sceneView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            sceneView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }
    
    func resetTracking() {
        guard ARFaceTrackingConfiguration.isSupported else {
            fatalError("Ar face tracking is not supported!")
        }
        
        let configuration = ARFaceTrackingConfiguration()
        configuration.maximumNumberOfTrackedFaces = ARFaceTrackingConfiguration.supportedNumberOfTrackedFaces
        configuration.isLightEstimationEnabled = true
        sceneView?.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
        
        faceAnchorsNodes.removeAll()
    }
    
    func displayErrorMessage(title: String, message: String) {
        // Present an alert informing about the error that has occurred.
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let restartAction = UIAlertAction(title: "Restart Session", style: .default) { _ in
            alertController.dismiss(animated: true, completion: nil)
            self.resetTracking()
        }
        alertController.addAction(restartAction)
        present(alertController, animated: true, completion: nil)
    }
    
    func faceGeomatryRenderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        guard let sceneView = renderer as? ARSCNView,
            anchor is ARFaceAnchor
        else { 
            return nil
        }
        
        #if targetEnvironment(simulator)
        #error("ARKit is not supported in iOS Simulator. Connect a physical iOS device and select it as your Xcode run destination, or select Generic iOS Device as a build-only destination.")
        #else
        
        guard let device = sceneView.device,
              let faceGeometry = ARSCNFaceGeometry(device: device),
              let material = faceGeometry.firstMaterial
        else {
            return nil
        }
        
        material.fillMode = .lines
        material.lightingModel = .physicallyBased
        
        let contentNode = SCNNode(geometry: faceGeometry)
        #endif
        
        return contentNode
    }
    
    func trackFacePosition(anchor: ARFaceAnchor) {
        let facePosition = anchor.transform.position()
        let leftEye = anchor.leftEyeTransform.position()
        let rightEye = anchor.rightEyeTransform.position()
        // Print out the direction vector
        logger.debug("Face Posstion: \(String(describing: facePosition))")
        logger.debug("leftEye Posstion: \(String(describing: leftEye))")
        logger.debug("rightEye Posstion: \(String(describing: rightEye))")
    }
}

// MARK: ARSessionDelegate
extension ARFaceTrackingViewController: ARSessionDelegate {
    func session(_ session: ARSession, didFailWithError error: any Error) {
        guard error is ARError else { return }
        
        let errorWithInfo = error as NSError
        let messages = [
            errorWithInfo.localizedDescription,
            errorWithInfo.localizedFailureReason,
            errorWithInfo.localizedRecoverySuggestion
        ]
        let errorMessage = messages.compactMap({ $0 }).joined(separator: "\n")
        
        DispatchQueue.main.async {
            self.displayErrorMessage(title: "The AR session failed.", message: errorMessage)
        }
    }
}

// MARK: ARSCNViewDelegate
extension ARFaceTrackingViewController: ARSCNViewDelegate {
    func renderer(_ renderer: any SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard let faceAnchor = anchor as? ARFaceAnchor else { return }
        
        // If this is the first time with this anchor, get the controller to create content.
        // Otherwise (switching content), will change content when setting `selectedVirtualContent`.
        DispatchQueue.main.async {
            if node.childNodes.isEmpty,
                let contentNode = self.faceGeomatryRenderer(renderer, nodeFor: faceAnchor) {
                node.addChildNode(contentNode)
                self.faceAnchorsNodes[faceAnchor] = contentNode
            }
        }
        
        trackFacePosition(anchor: faceAnchor)
    }
    
    /// - Tag: ARFaceGeometryUpdate
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let faceAnchor = anchor as? ARFaceAnchor,
              let faceAnchorNode = faceAnchorsNodes[faceAnchor],
              let faceGeometry = faceAnchorNode.geometry as? ARSCNFaceGeometry 
        else {
            return
        }
        
        faceGeometry.update(from: faceAnchor.geometry)
        trackFacePosition(anchor: faceAnchor)
    }
    
    func renderer(_ renderer: any SCNSceneRenderer, didRemove node: SCNNode, for anchor: ARAnchor) {
        guard let faceAnchor = anchor as? ARFaceAnchor else { return }
        
        faceAnchorsNodes[faceAnchor] = nil
    }
}
