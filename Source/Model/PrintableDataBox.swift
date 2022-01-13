//
//  PrintableDataBox.swift
//  AirPrint
//
//  Created by Danyl Timofeyev on 25.11.2021.
//

import Foundation
import PDFKit.PDFDocument
import UIKit

final class PrintableDataBox: Hashable, Equatable {
    
    var isSelected: Bool = false
    let id: String
    var thumbnail: UIImage?

    /// scan or photoalbum item
    var image: UIImage?
    
    /// document from icloud
    var document: PDFDocument?
    var documentPage: Int?
    
    init(id: String, image: UIImage?, document: PDFDocument?, thumbnail: UIImage? = nil) {
        self.id = id
        self.image = image
        self.document = document
        self.thumbnail = thumbnail
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(image)
        hasher.combine(document)
        hasher.combine(documentPage)
        hasher.combine(thumbnail)
    }
    
    static func == (lhs: PrintableDataBox, rhs: PrintableDataBox) -> Bool {
        lhs.id == rhs.id
    }
}
