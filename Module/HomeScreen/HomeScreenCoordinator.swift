//
//  
//  HomeScreenCoordinator.swift
//  AirPrint
//
//  Created by Danyl Timofeyev on 26.11.2021.
//
//

import Foundation
import UIKit.UINavigationController
import Combine

protocol HomeScreenCoordinatorProtocol {
    func showMainMenuAndHandleActions()
    func closeMenu()
    func showCameraScaner() -> AnyPublisher<[UIImage], Never>
    func showPhotoPicker() -> AnyPublisher<UIImage, Never>

    var output: PassthroughSubject<HomeScreenMenuViewModel.Action, Never> { get }
}

final class HomeScreenCoordinator: CoordinatorProtocol, HomeScreenCoordinatorProtocol {
    enum Response {
        
    }
    var navigationController: UINavigationController?
    weak var childCoordinator: HomeScreenMenuCoordinator?
    
    private lazy var cameraScaner: CameraScanManager = CameraScanManagerImpl()
    private lazy var photoalbumManager: PhotoalbumManager = PhotoalbumManagerImpl()
    private lazy var cloudFilesManager: CloudFilesManager = CloudFilesManagerImpl()
    
    var output = PassthroughSubject<HomeScreenMenuViewModel.Action, Never>()
    private var bag = Set<AnyCancellable>()
    
    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }
    deinit {
        Logger.log(String(describing: self), type: .deinited)
    }
    
    func start() {
        let viewModel = HomeScreenViewModel(coordinator: self)
        let controller = HomeScreenViewController(viewModel: viewModel)
        navigationController?.pushViewController(controller, animated: true)
    }
    
    func showCameraScaner() -> AnyPublisher<[UIImage], Never> {
        cameraScaner.displayScanningController(navigationController!)
        return cameraScaner.output
    }
    
    func showPhotoPicker() -> AnyPublisher<UIImage, Never> {
        photoalbumManager.displayPhotoLibrary(navigationController!)
        return photoalbumManager.output
    }
        
    func showMainMenuAndHandleActions() {
        let coordinator = HomeScreenMenuCoordinator(navigationController: navigationController)
        coordinator.start()
        childCoordinator = coordinator
        coordinator.output.eraseToAnyPublisher()
            .sink(receiveValue: { [weak self] homeMenuActionSelected in
            self?.output.send(homeMenuActionSelected)
        })
        .store(in: &self.bag)
    }
    
    func closeMenu() {
        childCoordinator?.end()
    }
    
    func end() {
        
    }
}
