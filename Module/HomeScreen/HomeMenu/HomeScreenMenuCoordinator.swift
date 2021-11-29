//
//  
//  HomeScreenMenuCoordinator.swift
//  AirPrint
//
//  Created by Danyl Timofeyev on 29.11.2021.
//
//

import Foundation
import UIKit.UINavigationController
import Combine

protocol HomeScreenMenuCoordinatorProtocol {
   
}

final class HomeScreenMenuCoordinator: CoordinatorProtocol, HomeScreenMenuCoordinatorProtocol {
    var navigationController: UINavigationController?
    
    init(navigationController: UINavigationController?) {
        self.navigationController = navigationController
    }
    deinit {
        Logger.log(String(describing: self), type: .deinited)
    }
    
    func start() {
        let viewModel = HomeScreenMenuViewModel(coordinator: self)
        let controller = HomeScreenMenuViewController(viewModel: viewModel)
        navigationController?.present(controller, animated: true, completion: nil)
    }
    
    func end() {

    }
}
