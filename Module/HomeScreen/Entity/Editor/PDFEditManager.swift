//
//  PdfEditManager.swift
//  AirPrint
//
//  Created by Danyl Timofeyev on 04.12.2021.
//

import Foundation
import QuickLook
import PDFKit.PDFDocument

final class PDFEditManager: NSObject {
    
    private let finishCallback: VoidClosure
    private let fileURL: URL
    var editor: QLPreviewController!
    
    init(fileURL: URL, finishCallback: @escaping VoidClosure) {
        self.finishCallback = finishCallback
        self.fileURL = fileURL
        super.init()
    }
    deinit {
        Logger.log(String(describing: self), type: .deinited)
    }
    
    func editFile(navigation: UINavigationController?) {
        let preview = PreviewController()
        preview.fileURL = fileURL
        navigation?.setNavigationBarHidden(true, animated: false)
        navigation?.present(preview, animated: false, completion: nil)
    }
}
