//
//  
//  PdfViewerCoordinator.swift
//  AirPrint
//
//  Created by Danyl Timofeyev on 23.11.2021.
//
//

import Foundation
import UIKit.UINavigationController

protocol PdfViewerCoordinatorProtocol {
   
}

final class PdfViewerCoordinator: CoordinatorProtocol, PdfViewerCoordinatorProtocol {
    var navigationController: UINavigationController?
    let pdfUrl: URL
    
    init(pdfUrl: URL, navigationController: UINavigationController?) {
        self.pdfUrl = pdfUrl
        self.navigationController = navigationController
    }
    deinit {
        Logger.log(String(describing: self), type: .deinited)
    }
    
    func start() {
        let viewModel = PdfViewerViewModel(coordinator: self, pdfUrl: pdfUrl)
        let controller = PdfViewerViewController(viewModel: viewModel)
        navigationController?.pushViewController(controller, animated: true)
    }
    
    func end() {

    }
}
