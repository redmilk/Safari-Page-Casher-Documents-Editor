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
    var output: AnyPublisher<UIImage, Never> { get }
    func displayPhotoLibrary(_ parentController: UIViewController)
}

final class PhotoalbumManagerImpl: NSObject, PhotoalbumManager {
    
    var picker: PHPickerViewController!
    var output: AnyPublisher<UIImage, Never> { _output.eraseToAnyPublisher() }
    private let _output = PassthroughSubject<UIImage, Never>()
    private let queue = DispatchQueue(label: "image.picker.queue")
    
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
        let itemProviders = results.map(\.itemProvider)
        for item in itemProviders {
            if item.canLoadObject(ofClass: UIImage.self) {
                item.loadObject(ofClass: UIImage.self) { [weak self] (image, error) in
                    if let image = image as? UIImage {
                        self?._output.send(image)
                    }
                }
            }
        }
    }
}
