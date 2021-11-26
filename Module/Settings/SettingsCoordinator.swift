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
   
}

final class SettingsCoordinator: CoordinatorProtocol, SettingsCoordinatorProtocol {
    var navigationController: UINavigationController?
    
    init() {

    }
    deinit {
        Logger.log(String(describing: self), type: .deinited)
    }
    
    func start() {
        let viewModel = SettingsViewModel(coordinator: self)
        let controller = SettingsViewController(viewModel: viewModel)

    }
    
    func end() {

    }
}
