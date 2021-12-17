//
//  SharedActivityResults.swift
//  AirPrint
//
//  Created by Danyl Timofeyev on 17.12.2021.
//

import Foundation
import PDFKit.PDFDocument

fileprivate let kSharedText = "shared-text"
fileprivate let kSharedURL = "shared-url"
fileprivate let kSharedPDF = "shared-pdf.pdf"
fileprivate let kSharedImage = "shared-image"
fileprivate let kGroupPathIdentifier = "group.airprint_path_of_media"

final class SharedActivityResults: PdfServiceProvidable, UserSessionServiceProvidable {
    
    private var path: URL? { FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: kGroupPathIdentifier) }
    private var imagePath: URL? { path?.appendingPathComponent(kSharedImage) }
    private var documentPath: URL? { path?.appendingPathComponent(kSharedPDF) }
    private var sharedURL: URL? { UserDefaults(suiteName: kGroupPathIdentifier)?.url(forKey: kSharedURL) }
    private var sharedText: String? { UserDefaults.standard.string(forKey: kSharedText) }
    
    func searchSharedItems() -> Int {
        let totalSharedItems = (checkSharedImage() ?? []) + (checkSharedDocument() ?? []) + (checkSharedText() ?? [])
        if totalSharedItems.count > 0 {
            userSession.input.send(.addItems(totalSharedItems))
        }
        return totalSharedItems.count
    }
    
    func searchSharedURL() -> URL? {
        guard let url = sharedURL else { return nil }
        UserDefaults(suiteName: kGroupPathIdentifier)?.set(nil, forKey: kSharedURL)
        return url
    }
    
    private func checkSharedImage() -> [PrintableDataBox]? {
        var filePath = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: kGroupPathIdentifier)
        filePath?.appendPathComponent(kSharedImage)
        guard let path = filePath?.absoluteString.split(separator: ":")[1].replacingOccurrences(of: "///", with: "/"),
              FileManager().fileExists(atPath: path) else { return nil }
        let url = URL.init(fileURLWithPath: path)
        let mediaData = NSData(contentsOf: url)
        let sharedImage = UIImage(data: Data(mediaData!))
        print(filePath!.absoluteString)
        do {
            try FileManager.default.removeItem(at: filePath!)
        } catch {
            print((error as NSError).localizedDescription)
        }
        return [PrintableDataBox(id: Date().millisecondsSince1970.description,
                                image: sharedImage, document: nil)]
    }
    
    private func checkSharedDocument() -> [PrintableDataBox]? {
        var fullPath = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: kGroupPathIdentifier)
        fullPath!.appendPathComponent(kSharedPDF)
        guard let pdf = PDFDocument(url: fullPath!) else { return nil }
        let pdfPagesAsDocuments = pdfService.makeSeparatePDFDocumentsFromPDF(pdf)
        do {
            try FileManager.default.removeItem(at: fullPath!)
        } catch {
            print((error as NSError).localizedDescription)
        }
        let dataBoxList = pdfPagesAsDocuments.map {
            PrintableDataBox(id: Date().millisecondsSince1970.description, image: self.pdfService.makeImageFromPDFDocument($0, withImageSize: UIScreen.main.bounds.size, ofPageIndex: 0),
                document: $0)
        }
        return dataBoxList
    }

    
    private func checkSharedText() -> [PrintableDataBox]? {
        guard let text = sharedText,
              let pdf = pdfService.createPDFWithText(text) else { return nil }
        UserDefaults.standard.set(nil, forKey: kSharedText)
        let dataBox = PrintableDataBox(
            id: Date().millisecondsSince1970.description,
            image: self.pdfService.makeImageFromPDFDocument(pdf, withImageSize: UIScreen.main.bounds.size, ofPageIndex: 0),
            document: pdf)
        return [dataBox]
    }
}
