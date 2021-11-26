//
//  
//  OnboardingViewModel.swift
//  AirPrint
//
//  Created by Danyl Timofeyev on 26.11.2021.
//
//

import Foundation
import Combine

final class OnboardingViewModel {
    enum Action {
        case dummyAction
    }
    
    let input = PassthroughSubject<OnboardingViewModel.Action, Never>()
    let output = PassthroughSubject<OnboardingViewController.State, Never>()
    
    private let coordinator: OnboardingCoordinatorProtocol & CoordinatorProtocol
    private var bag = Set<AnyCancellable>()

    init(coordinator: OnboardingCoordinatorProtocol & CoordinatorProtocol) {
        self.coordinator = coordinator
        dispatchActions()
    }
    deinit {
        Logger.log(String(describing: self), type: .deinited)
    }
}

// MARK: - Internal

private extension OnboardingViewModel {
    
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
