//
//  PrintingOptionsManager.swift
//  AirPrint
//
//  Created by Danyl Timofeyev on 04.12.2021.
//

import Foundation

final class PrintingOptionsManager: NSObject {
    
    private let finishCallback: VoidClosure
    var didPresentCallback: VoidClosure?
    
    init(finishCallback: @escaping VoidClosure) {
        self.finishCallback = finishCallback
        super.init()
    }
    deinit {
        Logger.log(String(describing: self), type: .deinited)
    }
    
    func printUserSessionDataToLocalPrinter(pdfData: Data, jobName: String) {
        let printInfo = UIPrintInfo(dictionary: nil)
        printInfo.jobName = jobName
        printInfo.outputType = .general
        let printController = UIPrintInteractionController()
        //printController.overrideUserInterfaceStyle = .dark
        printController.delegate = self
        printController.printInfo = printInfo
        printController.showsNumberOfCopies = true
        printController.showsPaperSelectionForLoadedPapers = true
        printController.printingItem = pdfData
        printController.present(animated: false, completionHandler: { _, isPrinted, error in
            if isPrinted {
                NotificationCenter.default.post(name: Notification.Name.printingJobDone, object: nil)
            }
        })
    }
}

extension PrintingOptionsManager: UIPrintInteractionControllerDelegate {
    func printInteractionControllerDidPresentPrinterOptions(_ printInteractionController: UIPrintInteractionController) {
        didPresentCallback?()
    }
    func printInteractionControllerWillDismissPrinterOptions(_ printInteractionController: UIPrintInteractionController) {
        finishCallback()
    }
    func printInteractionControllerWillStartJob(_ printInteractionController: UIPrintInteractionController) {
        finishCallback()
    }
    func printInteractionControllerDidFinishJob(_ printInteractionController: UIPrintInteractionController) {
    }
}
