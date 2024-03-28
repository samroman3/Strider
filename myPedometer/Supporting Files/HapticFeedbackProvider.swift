//
//  HapticFeedbackProvider.swift
//  myPedometer
//
//  Created by Sam Roman on 3/28/24.
//

import Foundation
import SwiftUI

class HapticFeedbackProvider {
    
    static func impact() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
    
}
