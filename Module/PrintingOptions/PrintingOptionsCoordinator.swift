//
//  
//  PrintingOptionsCoordinator.swift
//  AirPrint
//
//  Created by Danyl Timofeyev on 26.11.2021.
//
//

import Foundation
import UIKit.UINavigationController
import Combine

protocol PrintingOptionsCoordinatorProtocol {
    func displayDefaultPrintingOptionsDialog(withPdfData data: Data)
}

final class PrintingOptionsCoordinator: CoordinatorProtocol, PrintingOptionsCoordinatorProtocol {
    weak var navigationController: UINavigationController?
    
    lazy var printingOptionsManager = PrintingOptionsManager(finishCallback: { [weak self] in
        self?.end()
    })
    
    init(navigationController: UINavigationController?) {
        self.navigationController = navigationController
    }
    deinit {
        Logger.log(String(describing: self), type: .deinited)
    }
    
    func start() {
        let viewModel = PrintingOptionsViewModel(coordinator: self)
        let controller = PrintingOptionsViewController(viewModel: viewModel)
        navigationController?.pushViewController(controller, animated: false)
    }
    
    func displayDefaultPrintingOptionsDialog(withPdfData data: Data) {
        printingOptionsManager.printUserSessionDataToLocalPrinter(pdfData: data, jobName: "Printing AirPrint's app current session result...")
    }
    
    func end() {
        navigationController?.popToRootViewController(animated: false)
    }
}
