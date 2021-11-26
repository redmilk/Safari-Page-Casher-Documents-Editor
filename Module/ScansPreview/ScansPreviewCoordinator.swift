//
//  
//  ScansPreviewCoordinator.swift
//  AirPrint
//
//  Created by Danyl Timofeyev on 26.11.2021.
//
//

import Foundation
import UIKit.UINavigationController
import Combine

protocol ScansPreviewCoordinatorProtocol {
   
}

final class ScansPreviewCoordinator: CoordinatorProtocol, ScansPreviewCoordinatorProtocol {
    var navigationController: UINavigationController?
    
    init() {

    }
    deinit {
        Logger.log(String(describing: self), type: .deinited)
    }
    
    func start() {
        let viewModel = ScansPreviewViewModel(coordinator: self)
        let controller = ScansPreviewViewController(viewModel: viewModel)

    }
    
    func end() {

    }
}
