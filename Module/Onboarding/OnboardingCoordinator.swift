//
//  
//  OnboardingCoordinator.swift
//  AirPrint
//
//  Created by Danyl Timofeyev on 26.11.2021.
//
//

import Foundation
import UIKit.UINavigationController
import Combine

protocol OnboardingCoordinatorProtocol {
   
}

final class OnboardingCoordinator: CoordinatorProtocol, OnboardingCoordinatorProtocol {
    var navigationController: UINavigationController?
    
    init() {

    }
    deinit {
        Logger.log(String(describing: self), type: .deinited)
    }
    
    func start() {
        let viewModel = OnboardingViewModel(coordinator: self)
        let controller = OnboardingViewController(viewModel: viewModel)

    }
    
    func end() {

    }
}
