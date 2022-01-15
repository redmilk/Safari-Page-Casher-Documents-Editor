//
//  PreviewController.swift
//  AirPrint
//
//  Created by Danyl Timofeyev on 14.12.2021.
//

import Foundation
import QuickLook

class PreviewController: QLPreviewController, PdfServiceProvidable, UserSessionServiceProvidable {
    
    var fileURL: URL!
    var toolbars: [UIView] = []
    var observations: [NSKeyValueObservation] = []
    var isFileWasEdited: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        delegate = self
        dataSource = self
        overrideUserInterfaceStyle = .dark
        navigationItem.setRightBarButton(UIBarButtonItem(), animated: false)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.toolbar.isHidden = true
        if let navigationToobar = navigationController?.toolbar {
            let observation = navigationToobar.observe(\.isHidden) {[weak self] (changedToolBar, change) in
                if self?.navigationController?.toolbar.isHidden == false {
                    self?.navigationController?.toolbar.isHidden = true
                }
            }
            observations.append(observation)
        }
        toolbars = toolbarsInSubviews(forView: view)
        for toolbar in toolbars {
            toolbar.isHidden = true
            let observation = toolbar.observe(\.isHidden) { (changedToolBar, change) in
                if let isHidden = change.newValue,
                   isHidden == false {
                    changedToolBar.isHidden = true
                }
            }
            observations.append(observation)
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        (children[0] as? UINavigationController)?.toolbar.removeFromSuperview()
    }
    
    private func toolbarsInSubviews(forView view: UIView) -> [UIView] {
        var toolbars: [UIView] = []
        for subview in view.subviews {
            if subview is UIToolbar {
                toolbars.append(subview)
            }
            toolbars.append(contentsOf: toolbarsInSubviews(forView: subview))
        }
        return toolbars
    }
    
    private func replaceEditedFileWithUpdated(_ fileURL: URL) {
        guard isFileWasEdited else { return }
        if let editedPDF = PDFDocument(url: fileURL),
           let oldDataBox = userSession.editingFileDataBox,
           let updatedThumbnail = pdfService.makeImageFromPDFDocument(
            editedPDF, withImageSize: oldDataBox.image?.size ?? UIScreen.main.bounds.size, ofPageIndex: 0) {
            let newDataBox = PrintableDataBox(id: oldDataBox.id, image: updatedThumbnail, document: editedPDF)
            userSession.input.send(.updateEditedFilesData(newDataBox: newDataBox, oldDataBox: oldDataBox))
        }
    }
}

extension PreviewController: QLPreviewControllerDataSource {
    func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
        return 1
    }
    func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
        return fileURL as QLPreviewItem
    }
}


extension PreviewController: QLPreviewControllerDelegate {
    func previewController(_ controller: QLPreviewController, editingModeFor previewItem: QLPreviewItem) -> QLPreviewItemEditingMode {
        return .updateContents
    }
    func previewController(_ controller: QLPreviewController, didUpdateContentsOf previewItem: QLPreviewItem) {
        isFileWasEdited = true
    }
    func previewControllerWillDismiss(_ controller: QLPreviewController) {
        replaceEditedFileWithUpdated(fileURL)
    }
}
