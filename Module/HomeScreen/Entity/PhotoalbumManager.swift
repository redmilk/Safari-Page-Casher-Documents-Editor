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
    private var finishCallback: VoidClosure!
    private var isAlreadyProcessingFiles: Bool = false
    private var selectedPhotosCount = 0
    private var tapGesture = UITapGestureRecognizer()
    private var totalConversionsCompleted = -1 {
        didSet {
            print(selectedPhotosCount)
            print(totalConversionsCompleted)
            
            if totalConversionsCompleted >= selectedPhotosCount {
                guard let finishCallback = finishCallback else { return }
                isAlreadyProcessingFiles = false
                totalConversionsCompleted = -1
                selectedPhotosCount = 0
                DispatchQueue.main.async {
                    self.picker.dismiss(animated: true, completion: finishCallback)
                }
            }
        }
    }
    
    func displayPhotoLibrary(_ parentController: UIViewController, presentationCallback: @escaping VoidClosure) {
        finishCallback = presentationCallback
        var configuration = PHPickerConfiguration()
        configuration.selectionLimit = 20
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
        guard !isAlreadyProcessingFiles else { return }
        if results.count == 0 {
            return DispatchQueue.main.async {
                picker.dismiss(animated: true, completion: self.finishCallback)
                self.isAlreadyProcessingFiles = false
                self.totalConversionsCompleted = -1
                self.selectedPhotosCount = 0
            }
        }
        picker.startActivityAnimation()
        isAlreadyProcessingFiles = true
        selectedPhotosCount = results.count
        totalConversionsCompleted = 0
        let dispatchQueue = DispatchQueue(label: "image-processing-photoalbum")
        var selectedImageDataList = [Data?](repeating: nil, count: results.count)

        for (index, result) in results.enumerated() {
            result.itemProvider.loadFileRepresentation(forTypeIdentifier: UTType.image.identifier) { [weak self] (url, error) in
                guard let self = self else { return }
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
                    selectedImageDataList[index] = data as Data
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
