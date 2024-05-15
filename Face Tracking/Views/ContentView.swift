//
//  ContentView.swift
//  Face Tracking
//
//  Created on 15/05/24.
//  
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        ARFaceTrackingViewControllerRepresentable()
            .ignoresSafeArea()
    }
}

#Preview {
    ContentView()
}
