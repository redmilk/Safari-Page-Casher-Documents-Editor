//
//  
//  SettingsViewModel.swift
//  AirPrint
//
//  Created by Danyl Timofeyev on 26.11.2021.
//
//

import Foundation
import Combine

final class SettingsViewModel {
    enum Action {
        case manageSubscriptions
        case contactUs
        case privacyPolicy
        case termsOfUse
        case share
    }
    
    let input = PassthroughSubject<SettingsViewModel.Action, Never>()
    let output = PassthroughSubject<SettingsViewController.State, Never>()
    
    private let coordinator: SettingsCoordinatorProtocol & CoordinatorProtocol
    private var bag = Set<AnyCancellable>()

    init(coordinator: SettingsCoordinatorProtocol & CoordinatorProtocol) {
        self.coordinator = coordinator
        dispatchActions()
    }
    deinit {
        Logger.log(String(describing: self), type: .deinited)
    }
}

// MARK: - Internal

private extension SettingsViewModel {
    
    /// Handle ViewController's actions
    private func dispatchActions() {
        input.sink(receiveValue: { [weak self] action in
            switch action {
            case .manageSubscriptions:
                self?.coordinator.showManageSubscriptions()
            case .contactUs: break
            case .privacyPolicy: break
            case .termsOfUse: break
            case .share: break
            }
        })
        .store(in: &bag)
    }
}
