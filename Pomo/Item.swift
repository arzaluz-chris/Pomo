//
//  Item.swift
//  Pomo
//
//  Created by Christian Arzaluz on 30/05/25.
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
