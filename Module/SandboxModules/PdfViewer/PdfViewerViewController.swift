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
import QuickLook
import PDFKit.PDFDocument

extension UIView {
    var parentViewController: UIViewController? {
        // Starts from next (As we know self is not a UIViewController).
        var parentResponder: UIResponder? = self.next
        while parentResponder != nil {
            if let viewController = parentResponder as? UIViewController {
                return viewController
            }
            parentResponder = parentResponder?.next
        }
        return nil
    }
}


// MARK: - PdfViewerViewController

final class PdfViewerViewController: QLPreviewController, PdfServiceProvidable {
    enum State {
        case dummyState
        case renderPdf(PDFDocument)
    }
            
    private let resultStackView = UIStackView(frame: .zero)
    
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
        dataSource = self
        delegate = self
        let clearButton = UIBarButtonItem(systemItem: .refresh)
        navigationItem.rightBarButtonItem = clearButton
        
        clearButton.publisher().sink(receiveValue: { [weak self] _ in
            //self?.cleanDrawing()
        })
        .store(in: &bag)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        Logger.logSubviews(view)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        ViewHierarchyDebugger.paintEverythingToBlackWithinView(view)
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
                //self?.pdfView.document = pdfDocument
                //self?.pdfView.autoScales = true
                //self?.pdfView.backgroundColor = UIColor.lightGray
                DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: { [weak self] in
                    //self?.editFile()
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
        return .updateContents
    }

    func previewController(_ controller: QLPreviewController, didSaveEditedCopyOf previewItem: QLPreviewItem, at modifiedContentsURL: URL) {
        print("SAVED at \(modifiedContentsURL)")
        let document = PDFDocument(url: modifiedContentsURL)!
        let page = document.page(at: 0)!
        
        let newPdf = PDFDocument()
        newPdf.insert(page, at: 0)
        
        let newPage = newPdf.page(at: 0)!
        let pageSize = newPage.bounds(for: .mediaBox)
        let image: UIImage? = pdfService.makeImageFromPdfDocument(newPdf, withImageSize: pageSize.size, ofPageIndex: 0)
        let imageView = UIImageView(image: image)
        resultStackView.addArrangedSubview(imageView)
    }
}
