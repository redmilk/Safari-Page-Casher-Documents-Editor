//
//  
//  HomeScreenMenuCoordinator.swift
//  AirPrint
//
//  Created by Danyl Timofeyev on 29.11.2021.
//
//

import Foundation
import UIKit.UINavigationController
import Combine

protocol HomeScreenMenuCoordinatorProtocol {
    var output: PassthroughSubject<HomeScreenMenuViewModel.Action, Never> { get }
    func endWithSelectedAction(_ action: HomeScreenMenuViewModel.Action)
}

final class HomeScreenMenuCoordinator: CoordinatorProtocol, HomeScreenMenuCoordinatorProtocol {
    var navigationController: UINavigationController?
    
    var output = PassthroughSubject<HomeScreenMenuViewModel.Action, Never>()

    private lazy var dimmView: UIView = {
        let size = CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height + 200)
        let rect = CGRect(origin: .zero, size: size)
        let view = UIView(frame: rect)
        view.backgroundColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 0.7516258912)
        navigationController?.view.addSubview(view)
        navigationController?.view.bringSubviewToFront(view)
        view.alpha = 0
        return view
    }()
    
    init(navigationController: UINavigationController?) {
        self.navigationController = navigationController
    }
    deinit {
        Logger.log(String(describing: self), type: .deinited)
    }
    
    func start() {
        let viewModel = HomeScreenMenuViewModel(coordinator: self)
        let controller = HomeScreenMenuViewController(viewModel: viewModel)
        dimmView.animateFadeInOut(0.6, isFadeIn: true, completion: nil)
        controller.isModalInPresentation = true
        navigationController?.present(controller, animated: true, completion: nil)
    }
    
    func endWithSelectedAction(_ action: HomeScreenMenuViewModel.Action) {
        dimmView.animateFadeInOut(0.6, isFadeIn: false, completion: { [weak self] in
            self?.dimmView.removeFromSuperview()
        })
        navigationController?.presentedViewController?.dismiss(animated: true, completion: { [weak self] in
            self?.output.send(action)
        })
    }
}
