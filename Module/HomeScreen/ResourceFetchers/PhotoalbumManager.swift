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
    func displayPhotoLibrary(_ parentController: UIViewController)
}

final class PhotoalbumManagerImpl: NSObject, PhotoalbumManager {
    
    var output: AnyPublisher<PrintableDataBox, Never> { _output.eraseToAnyPublisher() }
    private var picker: PHPickerViewController!
    private let _output = PassthroughSubject<PrintableDataBox, Never>()
    
    func displayPhotoLibrary(_ parentController: UIViewController) {
        var configuration = PHPickerConfiguration()
        configuration.selectionLimit = 10
        configuration.filter = .any(of: [.livePhotos, .images])
        configuration.preferredAssetRepresentationMode = .automatic
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = self
        picker.modalPresentationStyle = .fullScreen
        parentController.present(picker, animated: true, completion: nil)
    }
}

extension PhotoalbumManagerImpl: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        let itemProviders = results.map { ($0.assetIdentifier, $0.itemProvider) }
        for item in itemProviders {
            if item.1.canLoadObject(ofClass: UIImage.self) {
                item.1.loadObject(ofClass: UIImage.self) { [weak self] (image, error) in
                    if let image = image as? UIImage {
                        self?._output.send(
                            PrintableDataBox(id: item.0 ?? Date().millisecondsSince1970.description,
                                             image: image, document: nil)
                        )
                    }
                }
            }
        }
    }
}
