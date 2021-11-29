//
//  CloudFilesManager.swift
//  AirPrint
//
//  Created by Danyl Timofeyev on 29.11.2021.
//

import Foundation
import PDFKit.PDFDocument
import Combine

protocol CloudFilesManager {
    var output: AnyPublisher<PDFDocument, Never> { get }
    func displayDocumentsSelectionMenu()
}

final class CloudFilesManagerImpl: NSObject, CloudFilesManager {
    var output: AnyPublisher<PDFDocument, Never> { _output.eraseToAnyPublisher() }

    private unowned let parentController: UIViewController
    private let importMenu = UIDocumentPickerViewController(forOpeningContentTypes: [.pdf], asCopy: true)
    private let _output = PassthroughSubject<PDFDocument, Never>()
    
    init(parentController: UIViewController) {
        self.parentController = parentController
    }
    
    func displayDocumentsSelectionMenu() {
        importMenu.delegate = self
        importMenu.modalPresentationStyle = .fullScreen
        parentController.present(importMenu, animated: true, completion: nil)
    }
}

extension CloudFilesManagerImpl: UIDocumentPickerDelegate {
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let url = urls.first, let pdf = PDFDocument(url: url) else { return }
        urls.forEach { Logger.log($0.absoluteString) }
        _output.send(pdf)
    }
    
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        
    }
}
