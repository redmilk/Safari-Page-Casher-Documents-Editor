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
    var output: AnyPublisher<[PrintableDataBox], Never> { get }
    func displayScanningController(_ parentController: UIViewController, presentationCallback: @escaping VoidClosure)
}

final class CameraScanManagerImpl: NSObject, CameraScanManager {
    
    var output: AnyPublisher<[PrintableDataBox], Never> { _output.eraseToAnyPublisher() }
    private let _output = PassthroughSubject<[PrintableDataBox], Never>()
    private var presentationCallback: VoidClosure?
    
    func displayScanningController(_ parentController: UIViewController, presentationCallback: @escaping VoidClosure) {
        let controller = VNDocumentCameraViewController()
        self.presentationCallback = presentationCallback
        guard VNDocumentCameraViewController.isSupported else { return }
        controller.delegate = self
        parentController.present(controller, animated: true, completion: nil)
    }
}

extension CameraScanManagerImpl: VNDocumentCameraViewControllerDelegate {
    func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
        var results: [UIImage] = []
        for index in 0 ..< scan.pageCount {
            let image = scan.imageOfPage(at: index)
            results.append(image)
        }
        guard !results.isEmpty else { return
            controller.dismiss(animated: true, completion: presentationCallback)
        }
        let dataBoxList = results.map {
            PrintableDataBox(id: Date().millisecondsSince1970.description, image: $0, document: nil)
        }
        _output.send(dataBoxList)
        controller.dismiss(animated: true, completion: presentationCallback)
    }
    
    func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
        controller.dismiss(animated: true, completion: presentationCallback)
    }
}
