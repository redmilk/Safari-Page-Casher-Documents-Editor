//
//  PrintSettingsController.swift
//  AirPrint
//
//  Created by Danyl Timofeyev on 11.01.2022.
//

import Foundation

//class PrintSettingsController: UIPrintInteractionController {
//    
//    private var finishCallback: VoidClosure!
//    
//    override func viewDidAppear(_ animated: Bool) {
//        super.viewDidAppear(animated)
//    }
//    
//    func printUserSessionDataToLocalPrinter(pdfData: Data, jobName: String) {
//        let printInfo = UIPrintInfo(dictionary: nil)
//        printInfo.jobName = jobName
//        printInfo.outputType = .general
//        let printController = UIPrintInteractionController()
//        //printController.overrideUserInterfaceStyle = .dark
//        printController.delegate = self
//        printController.printInfo = printInfo
//        printController.showsNumberOfCopies = true
//        printController.printingItem = pdfData
//        printController.showsPaperSelectionForLoadedPapers = true
//        printController.present(animated: true, completionHandler: nil)
//    }
//}
//
//extension PrintSettingsController: UIPrintInteractionControllerDelegate {
//    func printInteractionControllerDidDismissPrinterOptions(_ printInteractionController: UIPrintInteractionController) {
//        finishCallback()
//    }
//    func printInteractionControllerWillStartJob(_ printInteractionController: UIPrintInteractionController) {
//        finishCallback()
//    }
//}
