//
//  PDFKitDocument+Extension.swift
//  AirPrint
//
//  Created by Danyl Timofeyev on 27.11.2021.
//

import Foundation
import PDFKit.PDFDocument

extension PDFDocument {
    @discardableResult
    func savePdfIntoDocumentsDirectory(_ pdf: PDFDocument) -> URL {
        func getDocumentsDirectory() -> URL {
            let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
            return paths[0]
        }
        
        let pdfName = UUID().uuidString
        let pdfPath = getDocumentsDirectory().appendingPathComponent(pdfName)
        if let pdfData = pdf.dataRepresentation() {
            try? pdfData.write(to: pdfPath)
        }
        return pdfPath
    }
}
