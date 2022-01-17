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
    var output: AnyPublisher<[PrintableDataBox], Never> { get }
    func displayDocumentsSelectionMenu(_ parentController: UIViewController, presentationCallback: @escaping VoidClosure)
}

final class CloudFilesManagerImpl: NSObject, CloudFilesManager, PdfServiceProvidable {
    var output: AnyPublisher<[PrintableDataBox], Never> { _output.eraseToAnyPublisher() }
    private var finishCallback: VoidClosure!
    private let _output = PassthroughSubject<[PrintableDataBox], Never>()
    
    func displayDocumentsSelectionMenu(_ parentController: UIViewController, presentationCallback: @escaping VoidClosure) {
        finishCallback = presentationCallback
        let importMenu = UIDocumentPickerViewController(forOpeningContentTypes: [.pdf], asCopy: true)
        importMenu.overrideUserInterfaceStyle = .dark
        importMenu.delegate = self
        importMenu.modalPresentationStyle = .fullScreen
        parentController.present(importMenu, animated: true, completion: nil)
    }
}


extension UIDocumentPickerViewController: ActivityIndicatorPresentable {
    
}


extension Notification.Name {
    static let pdfImportProcessDidStart = Notification.Name("pdf-import-process-start")
    static let pdfImportProcessDidStop = Notification.Name("pdf-import-process-stop")
}

extension CloudFilesManagerImpl: UIDocumentPickerDelegate {
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let url = urls.first, let pdf = PDFDocument(url: url) else { return }
        NotificationCenter.default.post(name: Notification.Name.pdfImportProcessDidStart, object: nil)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: { [weak self] in
            guard let self = self else { return }
            let pdfPagesAsDocuments = self.pdfService.makeSeparatePDFDocumentsFromPDF(pdf)
            let dataBoxList = pdfPagesAsDocuments.map { page in
                autoreleasepool {
                    PrintableDataBox(id: Date().millisecondsSince1970.description,
                                     image: self.pdfService.makeImageFromPDFDocument(page, withImageSize: UIScreen.main.bounds.size, ofPageIndex: 0),
                                     document: page)
                }
            }
            NotificationCenter.default.post(name: Notification.Name.pdfImportProcessDidStop, object: nil)
            self._output.send(dataBoxList)
        })
    }
    
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        finishCallback()
    }
}
