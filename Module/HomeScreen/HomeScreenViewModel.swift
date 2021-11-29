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
        dispatchActions()
    }
    deinit {
        Logger.log(String(describing: self), type: .deinited)
    }
}

// MARK: - Internal

private extension HomeScreenViewModel {
    
    /// Handle ViewController's actions
    private func dispatchActions() {
        input.sink(receiveValue: { [weak self] action in
            switch action {
            case .openMenu:
                self?.coordinator.showMenu()
            }
        })
        .store(in: &bag)
    }
}
