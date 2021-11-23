//
//  
//  ExampleCoordinator.swift
//  AirPrint
//
//  Created by Danyl Timofeyev on 18.11.2021.
//
//

import Foundation
import UIKit.UINavigationController
import Combine

protocol ExampleCoordinatorProtocol {
    func displayPdfViewer(withPdfUrl url: URL)
}

final class ExampleCoordinator: CoordinatorProtocol, ExampleCoordinatorProtocol {
    var navigationController: UINavigationController?
    unowned let window: UIWindow
    
    init(window: UIWindow) {
        self.window = window
    }
    deinit {
        Logger.log(String(describing: self), type: .deinited)
    }
    
    func start() {
        let viewModel = ExampleViewModel(coordinator: self)
        let controller = ExampleViewController(viewModel: viewModel)
        navigationController = UINavigationController(rootViewController: controller)
        window.rootViewController = navigationController
        window.makeKeyAndVisible()
    }
    
    func displayPdfViewer(withPdfUrl url: URL) {
        let coordinator = PdfViewerCoordinator(pdfUrl: url, navigationController: navigationController)
        coordinator.start()
    }
    
    func end() {

    }
}
