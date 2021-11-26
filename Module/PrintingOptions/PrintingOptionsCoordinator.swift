//
//  
//  PrintingOptionsCoordinator.swift
//  AirPrint
//
//  Created by Danyl Timofeyev on 26.11.2021.
//
//

import Foundation
import UIKit.UINavigationController
import Combine

protocol PrintingOptionsCoordinatorProtocol {
   
}

final class PrintingOptionsCoordinator: CoordinatorProtocol, PrintingOptionsCoordinatorProtocol {
    var navigationController: UINavigationController?
    
    init() {

    }
    deinit {
        Logger.log(String(describing: self), type: .deinited)
    }
    
    func start() {
        let viewModel = PrintingOptionsViewModel(coordinator: self)
        let controller = PrintingOptionsViewController(viewModel: viewModel)

    }
    
    func end() {

    }
}
