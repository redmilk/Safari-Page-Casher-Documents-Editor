//
//  
//  HomeScreenCoordinator.swift
//  AirPrint
//
//  Created by Danyl Timofeyev on 26.11.2021.
//
//

import Foundation
import UIKit.UINavigationController
import Combine

protocol HomeScreenCoordinatorProtocol {
   
}

final class HomeScreenCoordinator: CoordinatorProtocol, HomeScreenCoordinatorProtocol {
    var navigationController: UINavigationController?
    unowned let window: UIWindow
    
    init(window: UIWindow) {
        self.window = window
    }
    deinit {
        Logger.log(String(describing: self), type: .deinited)
    }
    
    func start() {
        let viewModel = HomeScreenViewModel(coordinator: self)
        let controller = HomeScreenViewController(viewModel: viewModel)
        navigationController = UINavigationController(rootViewController: controller)
        window.rootViewController = navigationController
        window.makeKeyAndVisible()
    }
    
    func end() {

    }
}
