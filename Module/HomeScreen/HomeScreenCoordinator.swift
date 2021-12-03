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
import PDFKit.PDFDocument
import Combine

protocol HomeScreenCoordinatorProtocol {
    var cameraScanerOutput: AnyPublisher<[UIImage], Never> { get }
    var photoalbumOutput: AnyPublisher<UIImage, Never> { get }
    var cloudFilesOutput: AnyPublisher<PDFDocument, Never> { get }
    
    func showMainMenuAndHandleActions()
    func closeMenu()
    func showCameraScaner()
    func showPhotoPicker()
    func showCloudFilesPicker()
}

final class HomeScreenCoordinator: CoordinatorProtocol, HomeScreenCoordinatorProtocol {
    
    //var output = PassthroughSubject<HomeScreenMenuViewModel.Action, Never>()
    
    var navigationController: UINavigationController?
    
    var cameraScanerOutput: AnyPublisher<[UIImage], Never> {
        cameraScaner.output.eraseToAnyPublisher()
    }
    var photoalbumOutput: AnyPublisher<UIImage, Never> {
        photoalbumManager.output.eraseToAnyPublisher()
    }
    var cloudFilesOutput: AnyPublisher<PDFDocument, Never> {
        cloudFilesManager.output.eraseToAnyPublisher()
    }
    
    private lazy var cameraScaner: CameraScanManager = CameraScanManagerImpl()
    private lazy var photoalbumManager: PhotoalbumManager = PhotoalbumManagerImpl()
    private lazy var cloudFilesManager: CloudFilesManager = CloudFilesManagerImpl()
    private var childCoordinator: HomeScreenMenuCoordinatorProtocol?
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
    
    func showCameraScaner() {
        cameraScaner.displayScanningController(navigationController!)
    }
    
    func showPhotoPicker() {
        photoalbumManager.displayPhotoLibrary(navigationController!)
    }
    
    func showCloudFilesPicker() {
        cloudFilesManager.displayDocumentsSelectionMenu(navigationController!)
    }
        
    func showMainMenuAndHandleActions() {
        let coordinator = HomeScreenMenuCoordinator(navigationController: navigationController)
        coordinator.start()
        childCoordinator = coordinator
        coordinator.output
            .sink(receiveValue: { [weak self] homeMenuActionSelected in
                switch homeMenuActionSelected {
                case .closeAction: break
                case .printPhoto: self?.showPhotoPicker()
                case .scanAction: break
                case .printDocument: break
                }

            self?.closeMenu()
        })
        .store(in: &self.bag)
    }
    
    func closeMenu() {
        childCoordinator?.end()
        childCoordinator = nil
    }
    
    func end() {
        
    }
}
