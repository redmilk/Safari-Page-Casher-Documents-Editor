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


// MARK: - ExampleViewController

final class ExampleViewController: UIViewController {
    enum State {
        case dummyState
    }
    
    @IBOutlet var imageView: UIImageView!
    
    private let viewModel: ExampleViewModel
    private var bag = Set<AnyCancellable>()
    private var canvasView: PKCanvasView!
    private var imgForMarkup: UIImage?

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
}

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
            canvasView.frame = setSize()
        }
        dismiss(animated: true, completion: nil)
    }
    
    func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
        dismiss(animated: true, completion: nil)
    }
}

// MARK: - Internal
// TODO: Refactor
#warning("NEED REFACTORING FOR ADOPTION OF CURRENT ARCHITECTURE")

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
        })
        .store(in: &bag)
        
        let clearButton = UIBarButtonItem(systemItem: .refresh)
        navigationItem.rightBarButtonItem = clearButton
        clearButton.publisher().sink(receiveValue: { [weak self] _ in
            self?.canvasView.drawing = PKDrawing()
        })
        .store(in: &bag)
        
        let saveButton = UIBarButtonItem(systemItem: .save)
        saveButton.publisher().sink(receiveValue: { [weak self] _ in
            self?.saveDrawing()
        })
        .store(in: &bag)
        
        let toolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: view.frame.size.width, height: 35))
        toolbar.widthAnchor.constraint(equalToConstant: 150).isActive = true
        let rightSpacer = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let leftSpacer = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        toolbar.setItems([leftSpacer, saveButton, rightSpacer], animated: false)
        navigationItem.titleView = toolbar
    }
    
    func displayScanningController() {
        guard VNDocumentCameraViewController.isSupported else { return }
        let controller = VNDocumentCameraViewController()
        controller.delegate = self
        present(controller, animated: true)
    }
    
    /// PencilKit
    
    func configureCanvasView() {
        canvasView = PKCanvasView.init(frame: imageView.frame)
        canvasView.isOpaque = false
        //canvasView.allowsFingerDrawing = true
        canvasView.drawingPolicy = .anyInput
        view.addSubview(canvasView)
    }
    
    func setSize() -> CGRect {
        let containerRatio = self.imageView.frame.size.height/self.imageView.frame.size.width
        let imageRatio = self.imgForMarkup!.size.height/self.imgForMarkup!.size.width
        if containerRatio > imageRatio {
            return self.getHeight()
        } else {
            return self.getWidth()
        }
    }
    
    func getHeight() -> CGRect {
        let containerView = self.imageView!
        let image = self.imgForMarkup!
        let ratio = containerView.frame.size.width / image.size.width
        let newHeight = ratio * image.size.height
        let size = CGSize(width: containerView.frame.width, height: newHeight)
        var yPosition = (containerView.frame.size.height - newHeight) / 2
        yPosition = (yPosition < 0 ? 0 : yPosition) + containerView.frame.origin.y
        let origin = CGPoint.init(x: 0, y: yPosition)
        return CGRect.init(origin: origin, size: size)
    }

    func getWidth() -> CGRect {
        let containerView = self.imageView!
        let image = self.imgForMarkup!
        let ratio = containerView.frame.size.height / image.size.height
        let newWidth = ratio * image.size.width
        let size = CGSize(width: newWidth, height: containerView.frame.height)
        let xPosition = ((containerView.frame.size.width - newWidth) / 2) + containerView.frame.origin.x
        let yPosition = containerView.frame.origin.y
        let origin = CGPoint.init(x: xPosition, y: yPosition)
        return CGRect.init(origin: origin, size: size)
    }
    
    func addPencilKitToCanvas() {
        self.canvasView?.drawing = PKDrawing()
        if let window = self.view.window, let toolPicker = PKToolPicker.shared(for: window) {
            toolPicker.setVisible(true, forFirstResponder: self.canvasView)
            toolPicker.addObserver(self.canvasView)
            /// self.updateLayout(for: toolPicker)
            self.canvasView.becomeFirstResponder()
        }
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
        
        let drawing = self.canvasView.drawing.image(from: self.canvasView.bounds, scale: 0)
        if let markedupImage = saveImage(drawing: drawing) {
            // Save the image or do whatever with the Marked up Image
            Logger.log("Imaged saved", type: .all)
        }
        self.navigationController?.popViewController(animated: true)
    }
}
