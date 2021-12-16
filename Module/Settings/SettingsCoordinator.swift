//
//  
//  SettingsCoordinator.swift
//  AirPrint
//
//  Created by Danyl Timofeyev on 26.11.2021.
//
//

import Foundation
import UIKit.UINavigationController
import Combine

protocol SettingsCoordinatorProtocol {
    func showManageSubscriptions()
    func showMiscSettingsModules(isPrivacyPolicy: Bool)
}

final class SettingsCoordinator: CoordinatorProtocol, SettingsCoordinatorProtocol {
    var navigationController: UINavigationController?
    
    init(navigationController: UINavigationController?) {
        self.navigationController = navigationController
    }
    deinit {
        Logger.log(String(describing: self), type: .deinited)
    }
    
    func start() {
        let viewModel = SettingsViewModel(coordinator: self)
        let controller = SettingsViewController(viewModel: viewModel)
        navigationController?.navigationItem.titleView?.tintColor = .white
        navigationController?.pushViewController(controller, animated: true)
    }
    
    func showManageSubscriptions() {  
        let coordinator = ManageSubscriptionsCoordinator(navigationController: navigationController)
        coordinator.start()
    }
    
    func showMiscSettingsModules(isPrivacyPolicy: Bool) {
        let coordinator = MiscSettingsModulesCoordinator(navigationController: navigationController, isPrivacyPolicy: isPrivacyPolicy)
        coordinator.start()
    }
    
    func end() {

    }
}
