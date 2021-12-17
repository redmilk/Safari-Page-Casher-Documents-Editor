//
//  
//  ManageSubscriptionsViewModel.swift
//  AirPrint
//
//  Created by Danyl Timofeyev on 11.12.2021.
//
//

import Foundation
import Combine

final class ManageSubscriptionsViewModel {
    enum Action {
        case dummyAction
    }
    
    let input = PassthroughSubject<ManageSubscriptionsViewModel.Action, Never>()
    let output = PassthroughSubject<ManageSubscriptionsViewController.State, Never>()
    
    private let coordinator: ManageSubscriptionsCoordinatorProtocol & CoordinatorProtocol
    private var bag = Set<AnyCancellable>()

    init(coordinator: ManageSubscriptionsCoordinatorProtocol & CoordinatorProtocol) {
        self.coordinator = coordinator
        dispatchActions()
    }
    deinit {
        Logger.log(String(describing: self), type: .deinited)
    }
}

// MARK: - Internal

private extension ManageSubscriptionsViewModel {
    
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
