//
//  
//  HomeScreenMenuViewModel.swift
//  AirPrint
//
//  Created by Danyl Timofeyev on 29.11.2021.
//
//

import Foundation
import Combine

final class HomeScreenMenuViewModel {
    enum Action {
        case scanAction
        case printPhoto
        case printDocument
        
        case closeAction
    }
    
    let input = PassthroughSubject<HomeScreenMenuViewModel.Action, Never>()
    let output = PassthroughSubject<HomeScreenMenuViewController.State, Never>()
    
    private let coordinator: HomeScreenMenuCoordinatorProtocol & CoordinatorProtocol
    private var bag = Set<AnyCancellable>()

    init(coordinator: HomeScreenMenuCoordinatorProtocol & CoordinatorProtocol) {
        self.coordinator = coordinator
        dispatchActions()
    }
    deinit {
        Logger.log(String(describing: self), type: .deinited)
    }
}

// MARK: - Internal

private extension HomeScreenMenuViewModel {
    
    /// Handle ViewController's actions
    private func dispatchActions() {
        input.sink(receiveValue: { [weak self] action in
            switch action {
            case .scanAction:
                break
            case .printPhoto:
                break
            case .printDocument:
                break
            case .closeAction:
                self?.coordinator.end()
            }
        })
        .store(in: &bag)
    }
}
