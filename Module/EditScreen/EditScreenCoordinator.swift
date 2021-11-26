//
//  
//  EditScreenCoordinator.swift
//  AirPrint
//
//  Created by Danyl Timofeyev on 26.11.2021.
//
//

import Foundation
import UIKit.UINavigationController
import Combine

protocol EditScreenCoordinatorProtocol {
   
}

final class EditScreenCoordinator: CoordinatorProtocol, EditScreenCoordinatorProtocol {
    var navigationController: UINavigationController?
    
    init() {

    }
    deinit {
        Logger.log(String(describing: self), type: .deinited)
    }
    
    func start() {
        let viewModel = EditScreenViewModel(coordinator: self)
        let controller = EditScreenViewController(viewModel: viewModel)

    }
    
    func end() {

    }
}
