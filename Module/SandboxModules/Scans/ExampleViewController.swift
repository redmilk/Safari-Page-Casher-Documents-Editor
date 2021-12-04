//
//  
//  ExampleViewController.swift
//  AirPrint
//
//  Created by Danyl Timofeyev on 18.11.2021.
//
//

import UIKit
import Combine
import VisionKit
import PencilKit
import PDFKit
import MobileCoreServices

// MARK: - ExampleViewController

final class ExampleViewController: UIViewController, PdfServiceProvidable {
    enum State {
        case dummyState
    }
    
    @IBOutlet private weak var imageView: UIImageView!
    @IBOutlet private weak var bottomToolBar: UIToolbar!
    
    private let viewModel: ExampleViewModel
    private var bag = Set<AnyCancellable>()
    /// pencil kit
    private var canvasView: PKCanvasView?
    private let toolPicker = PKToolPicker()
    private var imgForMarkup: UIImage?
    private let importMenu = CustomDocumentPickerViewController(forOpeningContentTypes: [.pdf], asCopy: true)

    init(viewModel: ExampleViewModel) {
        self.viewModel = viewModel
        super.init(nibName: String(describing: ExampleViewController.self), bundle: nil)
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
        configureView()
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        setPencilKitToolbarHidden(false)
    }
}

// MARK: - Internal
// TODO: Refactor

#warning("NEED REFACTORING FOR ADOPTION OF CURRENT ARCHITECTURE")
#warning("DECOMPOSE TO APROPRIATE SERVICES")

extension ExampleViewController: VNDocumentCameraViewControllerDelegate {
    func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
        for index in 0 ..< scan.pageCount {
            let image = scan.imageOfPage(at: index)
            guard index < 1 else {
                return dismiss(animated: true, completion: nil)
            }
            imgForMarkup = image
            imageView.image = image
            configureCanvasView()
            let size = setSize()
            canvasView?.translatesAutoresizingMaskIntoConstraints = false
            ///
            switch size {
            case .height(let heightRect):
                Logger.log("Min Height: \(min(imageView.frame.height, heightRect.height).description)")
                canvasView?.heightAnchor.constraint(equalToConstant: min(imageView.frame.height, heightRect.height)).isActive = true
                canvasView?.widthAnchor.constraint(equalToConstant: imageView.frame.width).isActive = true

            case .width(let widthRect):
                Logger.log("Min Width: \(min(imageView.frame.width, widthRect.width).description)")
                canvasView?.widthAnchor.constraint(equalToConstant: min(imageView.frame.width, widthRect.width)).isActive = true
                canvasView?.heightAnchor.constraint(equalToConstant: imageView.frame.height).isActive = true
            }
                        
            canvasView?.centerXAnchor.constraint(equalTo: imageView.centerXAnchor).isActive = true
            canvasView?.centerYAnchor.constraint(equalTo: imageView.centerYAnchor).isActive = true
            
            //canvasView?.backgroundColor = #colorLiteral(red: 0, green: 0.9768045545, blue: 0, alpha: 0.3474667406)
            //imageView.backgroundColor = .black
            addPencilKitToCanvas()
        }
        dismiss(animated: true, completion: nil)
    }
    
    func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
        dismiss(animated: true, completion: nil)
    }
}


private extension ExampleViewController {
    
    /// Handle ViewModel's states
    func handleStates() {
        viewModel.output.sink(receiveValue: { [weak self] state in
            switch state {
            case .dummyState:
                break
            }
        })
        .store(in: &bag)
    }
    
    func configureView() {
        let scanButton = UIBarButtonItem(systemItem: .camera)
        navigationItem.leftBarButtonItem = scanButton
        scanButton.publisher().sink(receiveValue: { [weak self] _ in
            self?.displayScanningController()
            self?.cleanDrawing()
        })
        .store(in: &bag)
        
        let clearButton = UIBarButtonItem(systemItem: .refresh)
        navigationItem.rightBarButtonItem = clearButton
        clearButton.publisher().sink(receiveValue: { [weak self] _ in
            self?.cleanDrawing()
        })
        .store(in: &bag)
        
        let saveButton = UIBarButtonItem(systemItem: .save)
        saveButton.publisher().sink(receiveValue: { [weak self] _ in
            self?.saveDrawing()
        })
        .store(in: &bag)
        
        let openDocumentsButton = UIBarButtonItem(systemItem: .add)
        openDocumentsButton.publisher().sink(receiveValue: { [weak self] _ in
            self?.displayDocumentsSelectionMenu()
        })
        .store(in: &bag)
        
        let openPhotoLibraryButton = UIBarButtonItem(systemItem: .add)
        openPhotoLibraryButton.publisher().sink(receiveValue: { [weak self] _ in
            self?.displayPhotoLibrary()
        })
        .store(in: &bag)
        
        let toolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: view.frame.size.width, height: 35))
        toolbar.widthAnchor.constraint(equalToConstant: 150).isActive = true
        let rightSpacer = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let leftSpacer = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        toolbar.setItems([leftSpacer, saveButton, rightSpacer], animated: false)
        navigationItem.titleView = toolbar
        
        
        bottomToolBar.setItems([openDocumentsButton, openPhotoLibraryButton], animated: false)
    }
    
    func displayScanningController() {
        guard VNDocumentCameraViewController.isSupported else { return }
        let controller = VNDocumentCameraViewController()
        controller.delegate = self
        present(controller, animated: true)
    }
    
    /// PencilKit
    
    func configureCanvasView() {
        removePencilKitFromCanvas()
        canvasView = PKCanvasView.init(frame: imageView.frame)
        canvasView!.isOpaque = false
        canvasView!.drawingPolicy = .anyInput
        view.addSubview(canvasView!)
    }
    
    func cleanDrawing() {
        canvasView?.drawing = PKDrawing()
    }
    
    enum RatioSide {
        case width(CGRect)
        case height(CGRect)
    }
    
    func setSize() -> RatioSide {
        func getHeight() -> CGRect {
            let containerView = imageView!
            let image = imgForMarkup!
            let ratio = containerView.frame.size.width / image.size.width
            let newHeight = ratio * image.size.height
            let size = CGSize(width: containerView.frame.width, height: newHeight)
            var yPosition = (containerView.frame.size.height - newHeight) / 2
            yPosition = (yPosition < 0 ? 0 : yPosition) + containerView.frame.origin.y
            let origin = CGPoint.init(x: 0, y: yPosition)
            return CGRect.init(origin: origin, size: size)
        }
        func getWidth() -> CGRect {
            let containerView = imageView!
            let image = imgForMarkup!
            let ratio = containerView.frame.size.height / image.size.height
            let newWidth = ratio * image.size.width
            let size = CGSize(width: newWidth, height: containerView.frame.height)
            let xPosition = ((containerView.frame.size.width - newWidth) / 2) + containerView.frame.origin.x
            let yPosition = containerView.frame.origin.y
            let origin = CGPoint.init(x: xPosition, y: yPosition)
            return CGRect.init(origin: origin, size: size)
        }
        Logger.log("Width: \(getWidth())")
        Logger.log("Height: \(getHeight())")
        Logger.log("ImageView Frame: \(imageView.frame)")
        
        let containerRatio = imageView.frame.size.height / imageView.frame.size.width
        let imageRatio = imgForMarkup!.size.height / imgForMarkup!.size.width
        
        //return containerRatio > imageRatio ? .height(getHeight()) : .width(getWidth())
        
        if containerRatio > imageRatio {
            return .height(getHeight())
        } else {
            return .width(getWidth())
        }
    }
    
    func addPencilKitToCanvas() {
        self.canvasView?.drawing = PKDrawing()
        if sceneDelegate?.window != nil, let canvasView = canvasView {
            toolPicker.setVisible(true, forFirstResponder: canvasView)
            toolPicker.addObserver(canvasView)
            canvasView.becomeFirstResponder()
        }
    }
    
    func removePencilKitFromCanvas() {
        canvasView?.resignFirstResponder()
        if let canvasView = canvasView {
            toolPicker.setVisible(false, forFirstResponder: canvasView)
            toolPicker.removeObserver(canvasView)
            canvasView.removeFromSuperview()
            self.canvasView = nil
        }
    }
    
    func setPencilKitToolbarHidden(_ isHidden: Bool) {
        if let canvasView = canvasView {
            toolPicker.setVisible(!isHidden, forFirstResponder: canvasView)
        }
        if !isHidden {
            canvasView?.becomeFirstResponder()
        }
    }
    
    // MARK: - Saving, printing
   
    func printPDFToLocalPrinter(_ pdf: PDFDocument, jobName: String) {
        let printInfo = UIPrintInfo(dictionary: nil)
        printInfo.jobName = jobName
        printInfo.outputType = .general
        let printController = UIPrintInteractionController.shared
        printController.printInfo = printInfo
        printController.showsNumberOfCopies = true
        printController.printingItem = pdf
        printController.showsPaperSelectionForLoadedPapers = true
        setPencilKitToolbarHidden(true)
        printController.present(animated: true, completionHandler: nil)
    }
    
    func convertImagesToPDF(_ images: [UIImage]) -> PDFDocument? {
        pdfService.makePDFFilesFromImages(images).first
    }
    
    func saveDrawing() {
        func saveImage(drawing: UIImage) -> UIImage? {
            let bottomImage = self.imgForMarkup!
            let newImage = autoreleasepool { () -> UIImage in
                UIGraphicsBeginImageContextWithOptions(self.canvasView!.frame.size, false, 0.0)
                bottomImage.draw(in: CGRect(origin: CGPoint.zero, size: self.canvasView!.frame.size))
                drawing.draw(in: CGRect(origin: CGPoint.zero, size: self.canvasView!.frame.size))
                let createdImage = UIGraphicsGetImageFromCurrentImageContext()
                UIGraphicsEndImageContext()
                return createdImage!
            }
            return newImage
        }
        guard let canvasView = canvasView else { return }
        let drawing = canvasView.drawing.image(from: canvasView.bounds, scale: 0)
        if let markedupImage = saveImage(drawing: drawing), let pdf = convertImagesToPDF([markedupImage]) {
           printPDFToLocalPrinter(pdf, jobName: "Test how to print")
        }
        self.navigationController?.popViewController(animated: true)
    }
}

// MARK: - Open photos from Photo Album

extension ExampleViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        guard let image = info[.originalImage] as? UIImage else { return }
        let pdf = pdfService.makePDFFilesFromImages([image])
        
        dismiss(animated: true)
    }

    func displayPhotoLibrary() {
        let picker = UIImagePickerController()
        picker.view.subviews.forEach { $0.backgroundColor = .black }
        //picker.allowsEditing = true
        picker.delegate = self
        picker.modalPresentationStyle = .fullScreen
        present(picker, animated: true)
    }
}

// MARK: - Open pdf files from iCloud or Dropbox

class CustomDocumentPickerViewController: UIDocumentPickerViewController {

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    
    
  }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        tabBarController?.selectedIndex = 1
        
        Logger.logSubviews(view)

    }

  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
  }
}

extension ExampleViewController: UIDocumentPickerDelegate {

    func displayDocumentsSelectionMenu() {
        /// "public.composite-content" another option for pdf search
        importMenu.delegate = self
        importMenu.modalPresentationStyle = .fullScreen
        present(importMenu, animated: true, completion: nil)
    }
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let url = urls.first, let pdf = PDFDocument(url: url) else { return }
        urls.forEach { Logger.log($0.absoluteString) }
        viewModel.input.send(.displayPdfViewer(pdf))
    }
    
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        
    }
}
