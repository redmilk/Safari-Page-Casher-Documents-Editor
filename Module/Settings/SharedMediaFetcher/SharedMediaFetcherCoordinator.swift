//
//  
//  SharedMediaFetcherCoordinator.swift
//  AirPrint
//
//  Created by Danyl Timofeyev on 17.12.2021.
//
//

import Foundation
import UIKit.UINavigationController
import Combine

protocol SharedMediaFetcherCoordinatorProtocol {
   
}

final class SharedMediaFetcherCoordinator: CoordinatorProtocol, SharedMediaFetcherCoordinatorProtocol {
    var navigationController: UINavigationController?
    
    init(navigationController: UINavigationController?) {
        self.navigationController = navigationController
    }
    deinit {
        Logger.log(String(describing: self), type: .deinited)
    }
    
    func start() {
        let viewModel = SharedMediaFetcherViewModel(coordinator: self)
        let controller = SharedMediaFetcherViewController(viewModel: viewModel)
        navigationController?.pushViewController(controller, animated: true)
    }
    
    func end() {

    }
}
