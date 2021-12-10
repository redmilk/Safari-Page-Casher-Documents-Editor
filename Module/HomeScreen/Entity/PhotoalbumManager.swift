//
//  PhotoalbumManager.swift
//  AirPrint
//
//  Created by Danyl Timofeyev on 29.11.2021.
//

import Foundation
import Combine
import PhotosUI

protocol PhotoalbumManager {
    var output: AnyPublisher<PrintableDataBox, Never> { get }
    func displayPhotoLibrary(_ parentController: UIViewController, presentationCallback: @escaping VoidClosure)
}

final class PhotoalbumManagerImpl: NSObject, PhotoalbumManager {
    
    var output: AnyPublisher<PrintableDataBox, Never> { _output.eraseToAnyPublisher() }
    private let _output = PassthroughSubject<PrintableDataBox, Never>()
    private var picker: PHPickerViewController!
    private let group = DispatchGroup()
    private var finishCallback: VoidClosure!
    
    func displayPhotoLibrary(_ parentController: UIViewController, presentationCallback: @escaping VoidClosure) {
        finishCallback = presentationCallback
        var configuration = PHPickerConfiguration()
        configuration.selectionLimit = 100
        configuration.filter = .any(of: [.livePhotos, .images])
        configuration.preferredAssetRepresentationMode = .automatic
        picker = PHPickerViewController(configuration: configuration)
        picker.overrideUserInterfaceStyle = .dark
        picker.delegate = self
        picker.modalPresentationStyle = .fullScreen
        parentController.present(picker, animated: true, completion: nil)
    }
}

extension PhotoalbumManagerImpl: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        group.notify(queue: DispatchQueue.main, execute: { [weak self] in
            guard let finishCallback = self?.finishCallback else { return }
            self?.picker.dismiss(animated: true, completion: finishCallback)
        })
        let itemProviders = results.map { ($0.assetIdentifier, $0.itemProvider) }
        for item in itemProviders {
            if item.1.canLoadObject(ofClass: UIImage.self) {
                group.enter()
                item.1.loadObject(ofClass: UIImage.self) { [weak self] (image, error) in
                    if let image = image as? UIImage {
                        self?._output.send(
                            PrintableDataBox(id: item.0 ?? Date().millisecondsSince1970.description,
                                image: image, document: nil))
                    }
                    self?.group.leave()
                }
            }
        }
    }
}