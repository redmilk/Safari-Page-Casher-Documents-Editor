//
//  PDFService.swift
//  AirPrint
//
//  Created by Danyl Timofeyev on 25.11.2021.
//

import Foundation
import PDFKit

protocol PDFService {
    func convertPrintableDataBoxesToSinglePDFDocument(_ sessionData: [PrintableDataBox]) -> PDFDocument?
    func makeSeparatePDFDocumentsFromPDF(_ pdf: PDFDocument) -> [PDFDocument]
    func makePDFFilesFromImages(_ images: [UIImage]) -> [PDFDocument]
    func mergePDFDocumentsIntoSingleFile(_ pdfFiles: [PDFDocument]) -> PDFDocument?
    func makeImageFromPDFDocument(_ pdfDocument: PDFDocument, withImageSize size: CGSize, ofPageIndex page: Int) -> UIImage?
    func savePdfIntoTempDirectory(_ pdf: PDFDocument, filepath: URL)
}

final class PDFServiceImpl: PDFService {
    
    func makeImageFromPDFDocument(_ pdfDocument: PDFDocument, withImageSize size: CGSize, ofPageIndex page: Int) -> UIImage? {
        let pdfDocumentPage = pdfDocument.page(at: page)
        return pdfDocumentPage?.thumbnail(of: size, for: PDFDisplayBox.trimBox)
    }
        
    func makePDFFilesFromImages(_ images: [UIImage]) -> [PDFDocument] {
        var pdfDocumentList: [PDFDocument] = []
        for (index,image) in images.enumerated() {
            let document = PDFDocument()
            let pdfPage = PDFPage(image: image)
            document.insert(pdfPage!, at: index)
            pdfDocumentList.append(document)
        }
        return pdfDocumentList
    }
    
    func makeSeparatePDFDocumentsFromPDF(_ pdf: PDFDocument) -> [PDFDocument] {
        guard pdf.pageCount != 0 else { return [] }
        var pdfList: [PDFDocument] = []
        for i in 0...pdf.pageCount {
            guard let page = pdf.page(at: i) else { break }
            let newPdf = PDFDocument()
            newPdf.insert(page, at: 0)
            pdfList.append(newPdf)
        }
        return pdfList
    }
    
    func mergePDFDocumentsIntoSingleFile(_ pdfFiles: [PDFDocument]) -> PDFDocument? {
        guard !pdfFiles.isEmpty else { return nil }
        let resultDocument = PDFDocument()
        pdfFiles.forEach {
            guard $0.pageCount != 0, let page = $0.page(at: 0) else { return }
            resultDocument.insert(page, at: 0)
        }
        guard resultDocument.pageCount != 0 else { return nil }
        return resultDocument
    }
    
    func convertPrintableDataBoxesToSinglePDFDocument(_ sessionData: [PrintableDataBox]) -> PDFDocument? {
        let resultSinglePdf = PDFDocument()
        for (index, dataBox) in sessionData.enumerated() {
            if let image = dataBox.image {
                let pdfPage = PDFPage(image: image)
                resultSinglePdf.insert(pdfPage!, at: index)
            } else if let pdfPage = dataBox.document?.page(at: 0) {
                resultSinglePdf.insert(pdfPage, at: index)
            }
        }
        guard resultSinglePdf.pageCount > 0 else { return nil }
        return resultSinglePdf
    }
        
    func savePdfIntoTempDirectory(_ pdf: PDFDocument, filepath: URL) {
        let pdfData = pdf.dataRepresentation()!
        try? pdfData.write(to: filepath)
    }
}
