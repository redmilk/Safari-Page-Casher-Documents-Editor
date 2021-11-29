//
//  CameraScanManager.swift
//  AirPrint
//
//  Created by Danyl Timofeyev on 29.11.2021.
//

import Foundation
import VisionKit
import Combine

protocol CameraScanManager {
    var output: AnyPublisher<[UIImage], Never> { get }
    func displayScanningController()
}

final class CameraScanManagerImpl: NSObject, CameraScanManager {
    
    var output: AnyPublisher<[UIImage], Never> { _output.eraseToAnyPublisher() }
    
    private let _output = PassthroughSubject<[UIImage], Never>()
    private unowned let parentController: UIViewController
    private let controller = VNDocumentCameraViewController()
    
    init(parentController: UIViewController) {
        self.parentController = parentController
        super.init()
    }
    
    func displayScanningController() {
        guard VNDocumentCameraViewController.isSupported else { return }
        controller.delegate = self
        parentController.present(controller, animated: true)
    }
}

extension CameraScanManagerImpl: VNDocumentCameraViewControllerDelegate {
    func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
        var results: [UIImage] = []
        for index in 0 ..< scan.pageCount {
            let image = scan.imageOfPage(at: index)
            guard index < 1 else { return controller.dismiss(animated: true, completion: nil) }
            results.append(image)
        }
        guard !results.isEmpty else { return controller.dismiss(animated: true, completion: nil) }
        _output.send(results)
        controller.dismiss(animated: true, completion: nil)
    }
    
    func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
        controller.dismiss(animated: true, completion: nil)
    }
}
