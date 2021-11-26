//
//  PrintableDataBox.swift
//  AirPrint
//
//  Created by Danyl Timofeyev on 25.11.2021.
//

import Foundation
import PDFKit.PDFDocument

final class PrintableDataBox {
    private var images: [UIImage] = []
    private var documents: [PDFDocument] = []
    
    var containsImages: Bool { !images.isEmpty }
    var containsDocuments: Bool { !documents.isEmpty }
}
