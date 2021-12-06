//
//  
//  EditScreenCoordinator.swift
//  AirPrint
//
//  Created by Danyl Timofeyev on 26.11.2021.
//
//

import Foundation
import UIKit.UINavigationController
import Combine

protocol EditScreenCoordinatorProtocol {

}

final class EditScreenCoordinator: NSObject, CoordinatorProtocol, EditScreenCoordinatorProtocol {
    var navigationController: UINavigationController?
    
    private lazy var pdfEditManager = PDFEditManager(fileURL: fileURL, finishCallback: { [weak self] in
        //self?.end()
    })
    private let fileURL: URL
    
    init(navigationController: UINavigationController?, fileURL: URL) {
        self.fileURL = fileURL
        super.init()
        self.navigationController = navigationController
    }
    deinit {
        Logger.log(String(describing: self), type: .deinited)
    }
    
    func start() {
        let viewModel = EditScreenViewModel(coordinator: self)
        let controller = EditScreenViewController(viewModel: viewModel)
        let navigation = UINavigationController(rootViewController: controller)
        navigation.overrideUserInterfaceStyle = .dark
        navigation.modalPresentationStyle = .fullScreen
        navigationController?.present(navigation, animated: false, completion: { [weak self, weak navigation] in
            self?.pdfEditManager.editFile(navigation: navigation)
            navigation?.delegate = self
        })
    }
        
    func end() {
        navigationController?.presentedViewController?.dismiss(animated: false, completion: nil)
    }
}

extension EditScreenCoordinator: UINavigationControllerDelegate {
    func navigationController(_ navigationController: UINavigationController, didShow viewController: UIViewController, animated: Bool) {
        if viewController is EditScreenViewController {
            end()
        }
    }
}
