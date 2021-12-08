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
    var cameraScanerOutput: AnyPublisher<[PrintableDataBox], Never> { get }
    var photoalbumOutput: AnyPublisher<PrintableDataBox, Never> { get }
    var cloudFilesOutput: AnyPublisher<[PrintableDataBox], Never> { get }
    var webpageOutput: AnyPublisher<[PrintableDataBox], Never> { get }
    var copyFromClipboardCallback: VoidClosure! { get set }
    
    func showMainMenuAndHandleActions()
    func closeMenu()
    func displayPrintSettings()
    func displayFileEditor(fileURL: URL)
}

final class HomeScreenCoordinator: CoordinatorProtocol, HomeScreenCoordinatorProtocol {
    
    var navigationController: UINavigationController?
    
    var cameraScanerOutput: AnyPublisher<[PrintableDataBox], Never> {
        cameraScaner.output.eraseToAnyPublisher()
    }
    var photoalbumOutput: AnyPublisher<PrintableDataBox, Never> {
        photoalbumManager.output.eraseToAnyPublisher()
    }
    var cloudFilesOutput: AnyPublisher<[PrintableDataBox], Never> {
        cloudFilesManager.output.eraseToAnyPublisher()
    }
    var webpageOutput: AnyPublisher<[PrintableDataBox], Never> {
        webpageManager.output.eraseToAnyPublisher()
    }
    var copyFromClipboardCallback: VoidClosure!
    
    private lazy var cameraScaner: CameraScanManager = CameraScanManagerImpl()
    private lazy var photoalbumManager: PhotoalbumManager = PhotoalbumManagerImpl()
    private lazy var cloudFilesManager: CloudFilesManager = CloudFilesManagerImpl()
    private lazy var webpageManager = WebpageManager(initialUrlString: "www.apple.com")
    private lazy var presentationCallback: VoidClosure = { [weak self] in }
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
    
    private func showCameraScaner() {
        cameraScaner.displayScanningController(navigationController!.topViewController!, presentationCallback: { [weak self] in
            self?.closeMenu()
        })
    }
    
    private func showPhotoPicker() {
        photoalbumManager.displayPhotoLibrary(navigationController!.topViewController!, presentationCallback: { [weak self] in
            self?.closeMenu()
        })
    }
    
    private func showCloudFilesPicker() {
        cloudFilesManager.displayDocumentsSelectionMenu(navigationController!.topViewController!, presentationCallback: { [weak self] in
            self?.closeMenu()
        })
    }
    
    private func showWebView() {
        webpageManager.displayWebpage(navigationController!.topViewController!, presentationCallback: { [weak self] in
            self?.closeMenu()
        })
    }
    
    func showMainMenuAndHandleActions() {
        let coordinator = HomeScreenMenuCoordinator(navigationController: navigationController)
        coordinator.start()
        childCoordinator = coordinator
        coordinator.output
            .sink(receiveValue: { [weak self] homeMenuActionSelected in
                switch homeMenuActionSelected {
                case .closeAction: self?.closeMenu()
                case .printPhoto: self?.showPhotoPicker()
                case .scanAction: self?.showCameraScaner()
                case .printWebPage: self?.showWebView()
                case .printDocument: self?.showCloudFilesPicker()
                case .printFromClipboard:
                    self?.copyFromClipboardCallback()
                }
            })
        .store(in: &self.bag)
    }
    
    func displayPrintSettings() {
        let coordinator = PrintingOptionsCoordinator(navigationController: navigationController)
        coordinator.start()
    }
    
    func displayFileEditor(fileURL: URL) {
        let coordinator = EditScreenCoordinator(navigationController: navigationController, fileURL: fileURL)
        coordinator.start()
    }
    
    func closeMenu() {
        childCoordinator?.end()
        childCoordinator = nil
    }
    
    func end() {
        
    }
}
