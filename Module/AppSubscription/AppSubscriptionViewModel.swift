//
//  
//  AppSubscriptionViewModel.swift
//  AirPrint
//
//  Created by Danyl Timofeyev on 26.11.2021.
//
//

import Foundation
import Combine

final class AppSubscriptionViewModel {
    enum Action {
        case dummyAction
    }
    
    let input = PassthroughSubject<AppSubscriptionViewModel.Action, Never>()
    let output = PassthroughSubject<AppSubscriptionViewController.State, Never>()
    
    private let coordinator: AppSubscriptionCoordinatorProtocol & CoordinatorProtocol
    private var bag = Set<AnyCancellable>()

    init(coordinator: AppSubscriptionCoordinatorProtocol & CoordinatorProtocol) {
        self.coordinator = coordinator
        dispatchActions()
    }
    deinit {
        Logger.log(String(describing: self), type: .deinited)
    }
}

// MARK: - Internal

private extension AppSubscriptionViewModel {
    
    /// Handle ViewController's actions
    private func dispatchActions() {
        input.sink(receiveValue: { [weak self] action in
            switch action {
            case .dummyAction:
                break
            }
        })
        .store(in: &bag)
    }
}
