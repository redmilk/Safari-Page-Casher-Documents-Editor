//
//  ___FILEHEADER___
//

import Foundation
import UIKit.UINavigationController
import Combine

protocol ___VARIABLE_productName:identifier___CoordinatorProtocol {
   
}

final class ___VARIABLE_productName:identifier___Coordinator: CoordinatorProtocol, ___VARIABLE_productName:identifier___CoordinatorProtocol {
    var navigationController: UINavigationController?
    
    init(navigationController: UINavigationController?) {
        self.navigationController = navigationController
    }
    deinit {
        Logger.log(String(describing: self), type: .deinited)
    }
    
    func start() {
        let viewModel = ___VARIABLE_productName:identifier___ViewModel(coordinator: self)
        let controller = ___VARIABLE_productName:identifier___ViewController(viewModel: viewModel)

    }
    
    func end() {

    }
}
