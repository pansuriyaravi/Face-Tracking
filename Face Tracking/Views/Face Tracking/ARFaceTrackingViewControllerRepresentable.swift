//
//  ARFaceTrackingViewControllerRepresentable.swift
//  Face Tracking
//
//  Created on 15/05/24.
//  
//

import SwiftUI

struct ARFaceTrackingViewControllerRepresentable: UIViewControllerRepresentable {
    typealias UIViewControllerType = ARFaceTrackingViewController
    
    func makeUIViewController(context: Context) -> ARFaceTrackingViewController {
        let contoller = ARFaceTrackingViewController()
        return contoller
    }
    
    func updateUIViewController(_ uiViewController: ARFaceTrackingViewController, context: Context) {
        
    }
    
}
