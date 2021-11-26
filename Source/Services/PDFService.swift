//
//  PDFService.swift
//  AirPrint
//
//  Created by Danyl Timofeyev on 25.11.2021.
//

import Foundation
import PDFKit

protocol PDFService {
    func makeSeparatePdfDocumentFromPdf(_ pdf: PDFDocument) -> [PDFDocument]
    func makePdfFilesFromImages(_ images: [UIImage]) -> [PDFDocument]
    func mergePdfDocumentsIntoSingleFile(_ pdfFiles: [PDFDocument]) -> PDFDocument
}

class PDFServiceImpl {
    
}
