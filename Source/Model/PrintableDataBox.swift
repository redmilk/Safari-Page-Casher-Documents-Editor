//
//  PrintableDataBox.swift
//  AirPrint
//
//  Created by Danyl Timofeyev on 25.11.2021.
//

import Foundation
import PDFKit.PDFDocument

final class PrintableDataBox: Hashable, Equatable {
    
    let id: String
    let isAddButton: Bool
    
    /// scan or photoalbum item
    var image: UIImage?
    
    /// document from icloud
    var document: PDFDocument?
    var documentPage: Int?
    
    init(id: String, image: UIImage?, document: PDFDocument?, isAddButton: Bool = false) {
        self.id = id
        print("PrintableDataBox id: \(id)")
        self.image = image
        self.document = document
        self.isAddButton = isAddButton
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(image)
        hasher.combine(document)
        hasher.combine(documentPage)
    }
    
    static func == (lhs: PrintableDataBox, rhs: PrintableDataBox) -> Bool {
        lhs.id == rhs.id && lhs.image == rhs.image && lhs.document == rhs.document && lhs.documentPage == rhs.documentPage
    }
}
