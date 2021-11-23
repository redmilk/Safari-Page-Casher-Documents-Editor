//
//  
//  PdfViewerViewController.swift
//  AirPrint
//
//  Created by Danyl Timofeyev on 23.11.2021.
//
//

import UIKit
import Combine
import PDFKit
import QuickLook


// MARK: - PdfViewerViewController

final class PdfViewerViewController: UIViewController {
    enum State {
        case dummyState
        case renderPdf(PDFDocument)
    }
        
    @IBOutlet private weak var pdfView: PDFView!
    
    private let viewModel: PdfViewerViewModel
    private var bag = Set<AnyCancellable>()
    
    init(viewModel: PdfViewerViewModel) {
        self.viewModel = viewModel
        super.init(nibName: String(describing: PdfViewerViewController.self), bundle: nil)
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    deinit {
        Logger.log(String(describing: self), type: .deinited)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        handleStates()
    }
}

// MARK: - Internal

private extension PdfViewerViewController {
    
    /// Handle ViewModel's states
    func handleStates() {
        viewModel.output
            .compactMap { $0 }
            .sink(receiveValue: { [weak self] state in
            switch state {
            case .dummyState:
                break
            case .renderPdf(let pdfDocument):
                self?.pdfView.document = pdfDocument
                self?.pdfView.autoScales = true
                self?.pdfView.backgroundColor = UIColor.lightGray
                DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: { [weak self] in
                    self?.editFile()
                })
            }
        })
        .store(in: &bag)
    }
    
    func editFile() {
        let editor = QLPreviewController()
        editor.dataSource = self
        editor.delegate = self
        editor.setEditing(true, animated: true)
        present(editor, animated: true, completion: nil)
    }
}

// MARK: - Internal
// TODO: Refactor
#warning("DECOMPOSE TO APROPRIATE SERVICES")

extension PdfViewerViewController: QLPreviewControllerDataSource {
    func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
        return 1
    }
    
    func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
        return viewModel.pdfUrl as QLPreviewItem
    }
}

@available(iOS 13.0, *)
extension PdfViewerViewController: QLPreviewControllerDelegate {
    
    func previewController(_ controller: QLPreviewController, editingModeFor previewItem: QLPreviewItem) -> QLPreviewItemEditingMode {
        return .createCopy
    }

    func previewController(_ controller: QLPreviewController, didSaveEditedCopyOf previewItem: QLPreviewItem, at modifiedContentsURL: URL) {
        print("SAVED at \(modifiedContentsURL)")
        pdfView.document = PDFDocument(url: modifiedContentsURL)!
    }
}
