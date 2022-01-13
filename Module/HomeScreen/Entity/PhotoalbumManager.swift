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

extension PHPickerViewController: ActivityIndicatorPresentable { }

final class PhotoalbumManagerImpl: NSObject, PhotoalbumManager {
    
    var output: AnyPublisher<PrintableDataBox, Never> { _output.eraseToAnyPublisher() }
    private let _output = PassthroughSubject<PrintableDataBox, Never>()
    private var picker: PHPickerViewController!
    private let group = DispatchGroup()
    private var finishCallback: VoidClosure!
    var totalConversionsCompleted = 0 {
        didSet {
            if totalConversionsCompleted >= selectedPhotosCount {
                guard let finishCallback = finishCallback else { return }
                DispatchQueue.main.async {
                    self.picker.dismiss(animated: true, completion: finishCallback)
                }
            }
        }
    }
    private var selectedPhotosCount = 0
    private lazy var queue: OperationQueue = {
       let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 60
        queue.qualityOfService = .userInitiated
        return queue
    }()
    
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
        guard results.count != 0 else {
            return DispatchQueue.main.async {
                picker.dismiss(animated: true, completion: self.finishCallback)
            }
        }
        picker.startActivityAnimation()
        picker.view.isUserInteractionEnabled = false
        let dispatchQueue = DispatchQueue(label: "image-processing-photoalbum")
        var selectedImageDatas = [Data?](repeating: nil, count: results.count)
        selectedPhotosCount = results.count
        
        for (index, result) in results.enumerated() {
            result.itemProvider.loadFileRepresentation(forTypeIdentifier: UTType.image.identifier) { (url, error) in
                guard let url = url else {
                    dispatchQueue.sync { self.totalConversionsCompleted += 1 }
                    return
                }
                let sourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary
                guard let source = CGImageSourceCreateWithURL(url as CFURL, sourceOptions) else {
                    dispatchQueue.sync { self.totalConversionsCompleted += 1 }
                    return
                }
                let downsampleOptions = [
                    kCGImageSourceCreateThumbnailFromImageAlways: true,
                    kCGImageSourceCreateThumbnailWithTransform: true,
                    kCGImageSourceThumbnailMaxPixelSize: 2_000,
                ] as CFDictionary
                guard let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, downsampleOptions) else {
                    dispatchQueue.sync { self.totalConversionsCompleted += 1 }
                    return
                }
                let data = NSMutableData()
                guard let imageDestination = CGImageDestinationCreateWithData(data, UTType.jpeg.identifier as CFString, 1, nil) else {
                    dispatchQueue.sync { self.totalConversionsCompleted += 1 }
                    return
                }
                let isPNG: Bool = {
                    guard let utType = cgImage.utType else { return false }
                    return (utType as String) == UTType.png.identifier
                }()
                let destinationProperties = [
                    kCGImageDestinationLossyCompressionQuality: isPNG ? 1.0 : 0.75
                ] as CFDictionary
                CGImageDestinationAddImage(imageDestination, cgImage, destinationProperties)
                CGImageDestinationFinalize(imageDestination)
                dispatchQueue.sync {
                    selectedImageDatas[index] = data as Data
                    if let image = UIImage(data: data as Data) {
                        let origW = image.size.width / 4
                        let origH = image.size.height / 4
                        let thumbnail = image.resizedImage(for: CGSize(width: origW, height: origH))
                        let dataBox = PrintableDataBox(
                            id: Date().millisecondsSince1970.description,
                            image: image, document: nil, thumbnail: thumbnail)
                        self._output.send(dataBox)
                        self.totalConversionsCompleted += 1
                    }
                }
            }
        }
    }
}
