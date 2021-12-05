//
//  PdfEditManager.swift
//  AirPrint
//
//  Created by Danyl Timofeyev on 04.12.2021.
//

import Foundation
import QuickLook
import PDFKit.PDFDocument

final class PDFEditManager: NSObject, PdfServiceProvidable, UserSessionServiceProvidable {
    
    private let finishCallback: VoidClosure
    private let fileURL: URL
    var editor: QLPreviewController!
    
    init(fileURL: URL, finishCallback: @escaping VoidClosure) {
        self.finishCallback = finishCallback
        self.fileURL = fileURL
        super.init()
    }
    deinit {
        Logger.log(String(describing: self), type: .deinited)
        replaceEditedFileWithUpdated(fileURL)
    }
    
    func editFile(navigation: UINavigationController?) {
        editor = QLPreviewController()
        editor.dataSource = self
        editor.delegate = self
        editor.setEditing(true, animated: true)
        editor.currentPreviewItemIndex = 0
        navigation?.pushViewController(editor, animated: false)
    }
    
    private func replaceEditedFileWithUpdated(_ fileURL: URL) {
        if let editedPDF = PDFDocument(url: fileURL),
           let oldDataBox = userSession.editingFileDataBox,
           let updatedThumbnail = pdfService.makeImageFromPDFDocument(
            editedPDF, withImageSize: oldDataBox.image?.size ?? UIScreen.main.bounds.size, ofPageIndex: 0) {
            
            let newDataBox = PrintableDataBox(id: oldDataBox.id, image: updatedThumbnail, document: editedPDF)
            userSession.input.send(.updateEditedFilesData(newDataBox: newDataBox, oldDataBox: oldDataBox))
        }
    }
}


extension PDFEditManager: QLPreviewControllerDataSource {
    func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
        return 1
    }
    
    func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
        return fileURL as QLPreviewItem
    }
}


extension PDFEditManager: QLPreviewControllerDelegate {
    func previewController(_ controller: QLPreviewController, editingModeFor previewItem: QLPreviewItem) -> QLPreviewItemEditingMode {
        return .updateContents
    }
    
    func previewController(_ controller: QLPreviewController, didUpdateContentsOf previewItem: QLPreviewItem) {

    }

    func previewController(_ controller: QLPreviewController, didSaveEditedCopyOf previewItem: QLPreviewItem, at modifiedContentsURL: URL) {

    }
    func previewControllerDidDismiss(_ controller: QLPreviewController) {
        controller.navigationController?.popViewController(animated: false)
    }
}
