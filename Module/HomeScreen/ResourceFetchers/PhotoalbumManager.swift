//
//  PhotoalbumManager.swift
//  AirPrint
//
//  Created by Danyl Timofeyev on 29.11.2021.
//

import Foundation
import Combine

protocol PhotoalbumManager {
    var output: AnyPublisher<UIImage, Never> { get }
    func displayPhotoLibrary()
}

final class PhotoalbumManagerImpl: NSObject, PhotoalbumManager {
    
    var output: AnyPublisher<UIImage, Never> { _output.eraseToAnyPublisher() }
    private unowned let parentController: UIViewController
    private let _output = PassthroughSubject<UIImage, Never>()
    
    init(parentController: UIViewController) {
        self.parentController = parentController
        super.init()
    }
    
    func displayPhotoLibrary() {
        let picker = UIImagePickerController()
        picker.view.subviews.forEach { $0.backgroundColor = .black }
        /// picker.allowsEditing = true
        picker.delegate = self
        picker.modalPresentationStyle = .fullScreen
        parentController.present(picker, animated: true)
    }
}

extension PhotoalbumManagerImpl: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        guard let image = info[.originalImage] as? UIImage else { return }
        _output.send(image)
        parentController.dismiss(animated: true)
    }
}
