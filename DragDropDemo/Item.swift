//
//  Item.swift
//  DragDropDemo
//
//  Created by An Nguyen on 12/5/26.
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
