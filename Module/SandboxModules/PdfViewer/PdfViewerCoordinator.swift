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
import PDFKit.PDFDocument

protocol PdfViewerCoordinatorProtocol {
   
}

final class PdfViewerCoordinator: CoordinatorProtocol, PdfViewerCoordinatorProtocol {
    var navigationController: UINavigationController?
    let pdf: PDFDocument
    
    init(pdf: PDFDocument, navigationController: UINavigationController?) {
        self.pdf = pdf
        self.navigationController = navigationController
    }
    deinit {
        Logger.log(String(describing: self), type: .deinited)
    }
    
    func start() {
        let viewModel = PdfViewerViewModel(coordinator: self, pdf: pdf)
        let controller = PdfViewerViewController(viewModel: viewModel)
        navigationController?.pushViewController(controller, animated: true)
    }
    
    func end() {
        
    }
}
