//
//  Item.swift
//  myPedometer
//
//  Created by Sam Roman on 1/24/24.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
