//
//  
//  ManageSubscriptionsCoordinator.swift
//  AirPrint
//
//  Created by Danyl Timofeyev on 11.12.2021.
//
//

import Foundation
import UIKit.UINavigationController
import Combine

protocol ManageSubscriptionsCoordinatorProtocol {
    func end()
}

final class ManageSubscriptionsCoordinator: CoordinatorProtocol, ManageSubscriptionsCoordinatorProtocol {
    var navigationController: UINavigationController?
    
    init(navigationController: UINavigationController?) {
        self.navigationController = navigationController
    }
    deinit {
        Logger.log(String(describing: self), type: .deinited)
    }
    
    func start() {
        let viewModel = ManageSubscriptionsViewModel(coordinator: self)
        let controller = ManageSubscriptionsViewController(viewModel: viewModel)
        navigationController?.pushViewController(controller, animated: true)
    }
    
    func end() {
        navigationController?.popViewController(animated: true)
    }
}
