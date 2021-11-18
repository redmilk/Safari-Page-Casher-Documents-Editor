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
   
}

final class ExampleCoordinator: CoordinatorProtocol, ExampleCoordinatorProtocol {
    var navigationController: UINavigationController?
    let window: UIWindow
    
    init(window: UIWindow) {
        self.window = window
    }
    deinit {
        Logger.log(String(describing: self), type: .deinited)
    }
    
    func start() {
        let viewModel = ExampleViewModel(coordinator: self)
        let controller = ExampleViewController(viewModel: viewModel)
        window.rootViewController = controller
        window.makeKeyAndVisible()
    }
    
    func end() {

    }
}
