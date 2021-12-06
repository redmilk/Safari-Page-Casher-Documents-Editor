//
//  PrinterPickerManager.swift
//  AirPrint
//
//  Created by Danyl Timofeyev on 04.12.2021.
//

import Foundation

final class PrinterPickerManager: NSObject {
    let finishCallback: VoidClosure
    
    init(finishCallback: @escaping VoidClosure) {
        self.finishCallback = finishCallback
        super.init()
    }
    deinit {
        Logger.log(String(describing: self), type: .deinited)
    }
    
    func showPrinterPicker() {
        let picker = UIPrinterPickerController()
        picker.delegate = self
        picker.present(animated: false, completionHandler: nil)
    }
}

extension PrinterPickerManager: UIPrinterPickerControllerDelegate {
    
}
