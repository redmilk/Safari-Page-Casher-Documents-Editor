//
//  
//  AppSubscriptionCoordinator.swift
//  AirPrint
//
//  Created by Danyl Timofeyev on 26.11.2021.
//
//

import Foundation
import UIKit.UINavigationController
import Combine

protocol AppSubscriptionCoordinatorProtocol {
   
}

final class AppSubscriptionCoordinator: CoordinatorProtocol, AppSubscriptionCoordinatorProtocol {
    var navigationController: UINavigationController?
    
    init() {

    }
    deinit {
        Logger.log(String(describing: self), type: .deinited)
    }
    
    func start() {
        let viewModel = AppSubscriptionViewModel(coordinator: self)
        let controller = AppSubscriptionViewController(viewModel: viewModel)

    }
    
    func end() {

    }
}
