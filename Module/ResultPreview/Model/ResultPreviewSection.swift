//
//  ResultPreviewSection.swift
//  AirPrint
//
//  Created by Danyl Timofeyev on 25.11.2021.
//

import Foundation
import UIKit.UIImage

struct ResultPreviewSection: Hashable {
    var id: String?
    let title: String
    let items: [ResultPreviewSectionItem]
    
    init(items: [ResultPreviewSectionItem], title: String) {
        self.items = items
        self.title = title
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(items)
        hasher.combine(title)
        hasher.combine(id)
    }

    static func == (lhs: ResultPreviewSection, rhs: ResultPreviewSection) -> Bool {
        lhs.title == rhs.title && lhs.items == rhs.items && lhs.id == rhs.id
    }
}

struct ResultPreviewSectionItem: Hashable {
    let thumbnail: UIImage
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(thumbnail)
    }
}
