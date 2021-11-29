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

final class HomeScreenViewModel {
    enum Action {
        case openMenu
    }
    
    let input = PassthroughSubject<HomeScreenViewModel.Action, Never>()
    let output = PassthroughSubject<HomeScreenViewController.State, Never>()
    
    private let coordinator: HomeScreenCoordinatorProtocol & CoordinatorProtocol
    private var bag = Set<AnyCancellable>()

    init(coordinator: HomeScreenCoordinatorProtocol & CoordinatorProtocol) {
        self.coordinator = coordinator
        handleActions()
    }
    deinit {
        Logger.log(String(describing: self), type: .deinited)
    }
}

// MARK: - Private

private extension HomeScreenViewModel {
    
    func handleActions() {
        input.sink(receiveValue: { [weak self] action in
            switch action {
            case .openMenu:
                self?.showMainMenuAndHandleActions()
            }
        })
        .store(in: &bag)
    }
    
    func showMainMenuAndHandleActions() {
        self.coordinator.showMenu().sink(receiveValue: { [weak self] homeMenuActionSelected in
            switch homeMenuActionSelected {
            case .scanAction:
                self?.output.send(.shouldDisplayScanFlow)
            case .printDocument:
                self?.output.send(.shouldDisplayCloudStorage)
            case .printPhoto:
                self?.output.send(.shouldDisplayPhotoAlbum)
            case _: break
            }
        })
        .store(in: &self.bag)
    }
}
