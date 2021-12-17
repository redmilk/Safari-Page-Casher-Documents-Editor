//
//  
//  SharedMediaFetcherViewModel.swift
//  AirPrint
//
//  Created by Danyl Timofeyev on 17.12.2021.
//
//

import Foundation
import Combine

final class SharedMediaFetcherViewModel {
    enum Action {
        case dummyAction
    }
    
    let input = PassthroughSubject<SharedMediaFetcherViewModel.Action, Never>()
    let output = PassthroughSubject<SharedMediaFetcherViewController.State, Never>()
    
    private let coordinator: SharedMediaFetcherCoordinatorProtocol & CoordinatorProtocol
    private var bag = Set<AnyCancellable>()

    init(coordinator: SharedMediaFetcherCoordinatorProtocol & CoordinatorProtocol) {
        self.coordinator = coordinator
        dispatchActions()
    }
    deinit {
        Logger.log(String(describing: self), type: .deinited)
    }
}

// MARK: - Internal

private extension SharedMediaFetcherViewModel {
    
    /// Handle ViewController's actions
    private func dispatchActions() {
        input.sink(receiveValue: { action in
            switch action {
            case .dummyAction:
                break
            }
        })
        .store(in: &bag)
    }
}
