//
//  
//  MiscSettingsModulesCoordinator.swift
//  AirPrint
//
//  Created by Danyl Timofeyev on 16.12.2021.
//
//

import Foundation
import UIKit.UINavigationController
import Combine

protocol MiscSettingsModulesCoordinatorProtocol {
   
}

final class MiscSettingsModulesCoordinator: CoordinatorProtocol, MiscSettingsModulesCoordinatorProtocol {
    var navigationController: UINavigationController?
    private let isPrivacyPolicy: Bool
    
    init(navigationController: UINavigationController?, isPrivacyPolicy: Bool) {
        self.navigationController = navigationController
        self.isPrivacyPolicy = isPrivacyPolicy
    }
    deinit {
        Logger.log(String(describing: self), type: .deinited)
    }
    
    func start() {
        let viewModel = MiscSettingsModulesViewModel(coordinator: self, isPrivacyPolicy: isPrivacyPolicy)
        let controller = MiscSettingsModulesViewController(viewModel: viewModel)
        navigationController?.pushViewController(controller, animated: true)
    }
    
    func end() {

    }
}
