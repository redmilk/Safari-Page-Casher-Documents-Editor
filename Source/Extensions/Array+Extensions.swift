//
//  Array+Extensions.swift
//  AirPrint
//
//  Created by Danyl Timofeyev on 22.11.2021.
//

import Foundation
import PDFKit

extension Array where Element: UIImage {
    func makePDF() -> PDFDocument? {
        let pdfDocument = PDFDocument()
        for (index,image) in self.enumerated() {
            let pdfPage = PDFPage(image: image)
            pdfDocument.insert(pdfPage!, at: index)
        }
        return pdfDocument
    }
}
