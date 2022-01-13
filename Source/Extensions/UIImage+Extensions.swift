//
//  UIImage+Extensions.swift
//  AirPrint
//
//  Created by Danyl Timofeyev on 27.11.2021.
//

import Foundation

extension UIImage {
    
    @discardableResult
    func saveImageIntoDocumentsDirectory(_ image: UIImage) -> URL {
        func getDocumentsDirectory() -> URL {
            let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
            return paths[0]
        }
        
        let imageName = UUID().uuidString
        let imagePath = getDocumentsDirectory().appendingPathComponent(imageName)
        if let jpegData = image.jpegData(compressionQuality: 0.8) {
            try? jpegData.write(to: imagePath)
        }
        return imagePath
    }
    
    func resizedImage(for size: CGSize) -> UIImage? {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { (context) in
            self.draw(in: CGRect(origin: .zero, size: size))
        }
    }
    
}

