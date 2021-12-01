//
//  
//  HomeScreenViewModel.swift
//  AirPrint
//
//  Created by Danyl Timofeyev on 26.11.2021.
//
//

import Foundation
import Combine

final class HomeScreenViewModel: UserSessionServiceProvidable {
    enum Action {
        case openMenu(menuOptionsPresenter: UIViewController)
        case deleteItem(PrintableDataBox)
    }
    
    let input = PassthroughSubject<HomeScreenViewModel.Action, Never>()
    let output = PassthroughSubject<HomeScreenViewController.State, Never>()
    
    private let coordinator: HomeScreenCoordinatorProtocol & CoordinatorProtocol
    private var bag = Set<AnyCancellable>()
    private lazy var cameraScaner: CameraScanManager = CameraScanManagerImpl()
    private lazy var photoalbumManager: PhotoalbumManager = PhotoalbumManagerImpl()
    private lazy var cloudFilesManager: CloudFilesManager = CloudFilesManagerImpl()

    init(coordinator: HomeScreenCoordinatorProtocol & CoordinatorProtocol) {
        self.coordinator = coordinator
    }
    deinit {
        Logger.log(String(describing: self), type: .deinited)
    }
    func configureViewModel() {
        handleActions()
    }
}

// MARK: - Private

private extension HomeScreenViewModel {
    
    func handleActions() {
        input.sink(receiveValue: { [weak self] action in
            switch action {
            case .openMenu(let menuOptionsPresenter):
                self?.showMainMenuAndHandleActions(menuOptionsPresenter: menuOptionsPresenter)
            case .deleteItem(let data):
                self?.userSession.input.send(.deleteItem(data))
            }
        })
        .store(in: &bag)
        
        cameraScaner.output
            .sink(receiveValue: { [weak self] imageList in
                print("SCANNED IMAGES COUNT")
                print(imageList.count.description)
                let data = imageList.map { PrintableDataBox(id: UUID().uuidString, image: $0, document: nil) }
                self?.userSession.input.send(.addItems(data))
            })
            .store(in: &bag)
        
        photoalbumManager.output.receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] image in
                print("GOT IMAGE FROM PHOTOALBUM")
                let data = PrintableDataBox(id: UUID().uuidString, image: image, document: nil)
                self?.userSession.input.send(.addItems([data]))
            })
            .store(in: &bag)
        
        cloudFilesManager.output.sink(receiveValue: { [weak self] pdf in
            print("GOT PDF FROM CLOUS")
            print(pdf.pageCount.description)
        })
        .store(in: &bag)
        
        userSession.output.sink(receiveValue: { [weak self] data in
            if data.count == 0 {
                self?.output.send(.empty)
            } else {
                self?.output.send(.newCollectionData(data))
            }
        })
        .store(in: &bag)
    }
    
    func showMainMenuAndHandleActions(menuOptionsPresenter: UIViewController) {
        self.coordinator.showMenu().sink(receiveValue: { [weak self, weak menuOptionsPresenter] homeMenuActionSelected in
            guard let self = self, let menuOptionsPresenter = menuOptionsPresenter else { return }
            switch homeMenuActionSelected {
            case .scanAction:
                self.cameraScaner.displayScanningController(menuOptionsPresenter)
            case .printDocument:
                self.cloudFilesManager.displayDocumentsSelectionMenu(menuOptionsPresenter)
            case .printPhoto:
                self.photoalbumManager.displayPhotoLibrary(menuOptionsPresenter)
            case _: break
            }
        })
        .store(in: &self.bag)
    }
}
