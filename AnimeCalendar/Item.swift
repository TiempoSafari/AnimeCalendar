//
//  Item.swift
//  AnimeCalendar
//
//  Created by 山枫 on 2026/1/15.
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
