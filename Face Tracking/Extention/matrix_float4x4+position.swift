//
//  matrix_float4x4+position.swift
//  Face Tracking
//
//  Created on 15/05/24.
//  
//

import Foundation
import ARKit

extension matrix_float4x4 {
    func position() -> SCNVector3 {
        return SCNVector3(columns.3.x, columns.3.y, columns.3.z)
    }
}
