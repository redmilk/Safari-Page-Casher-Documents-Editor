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

final class PdfViewerViewController: QLPreviewController {
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
        //self.toolbarItems?.f
        self.view.backgroundColor = .black
        handleStates()
        dataSource = self
        delegate = self
        setEditing(false, animated: true)
        let b = UIButton(frame: .init(x: 40, y: 140, width: 100, height: 100))
        b.backgroundColor = .red
        let clearButton = UIBarButtonItem(systemItem: .refresh)
        navigationItem.rightBarButtonItem = clearButton
        UIToolbar.appearance().barTintColor = .black
        UIToolbar.appearance().tintColor = .black
        
        clearButton.publisher().sink(receiveValue: { [weak self] _ in
            //self?.cleanDrawing()
        })
        .store(in: &bag)
        
        let saveButton = UIBarButtonItem(systemItem: .save)
        saveButton.publisher().sink(receiveValue: { [weak self] _ in
            //self?.saveDrawing()
        })
        .store(in: &bag)
        
        //self.setValue(<#T##value: Any?##Any?#>, forKey: <#T##String#>)
        b.publisher().receive(on: DispatchQueue.main).sink(receiveValue: { [unowned self] _ in
            //self?.navigationController?.setToolbarHidden(true, animated: true)
            //self?.navigationController?.setNavigationBarHidden(true, animated: true)
            //print(self?.toolbarItems?.first.debugDescription)
            //setEditing(true, animated: true)
            //reloadInputViews()
            setToolbarItems([clearButton, saveButton], animated: true)
            
            _ = self.editButtonItem.target!.perform(self.editButtonItem.action, with: nil)
            
            /// and
            
            UIApplication.shared.sendAction(self.editButtonItem.action!, to: self.editButtonItem.target, from: self, for: nil)
            
        })
        .store(in: &bag)
        self.view.addSubview(b)
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
        return .createCopy
    }

    func previewController(_ controller: QLPreviewController, didSaveEditedCopyOf previewItem: QLPreviewItem, at modifiedContentsURL: URL) {
        print("SAVED at \(modifiedContentsURL)")
        let document = PDFDocument(url: modifiedContentsURL)!
        let page = document.page(at: 0)!
        
        let newPdf = PDFDocument()
        newPdf.insert(page, at: 0)
        
        pdfView.document = newPdf//PDFDocument(url: modifiedContentsURL)!
    }
}
