//
//  
//  ScansPreviewViewModel.swift
//  AirPrint
//
//  Created by Danyl Timofeyev on 26.11.2021.
//
//

import Foundation
import Combine

final class ScansPreviewViewModel {
    enum Action {
        case dummyAction
    }
    
    let input = PassthroughSubject<ScansPreviewViewModel.Action, Never>()
    let output = PassthroughSubject<ScansPreviewViewController.State, Never>()
    
    private let coordinator: ScansPreviewCoordinatorProtocol & CoordinatorProtocol
    private var bag = Set<AnyCancellable>()

    init(coordinator: ScansPreviewCoordinatorProtocol & CoordinatorProtocol) {
        self.coordinator = coordinator
        dispatchActions()
    }
    deinit {
        Logger.log(String(describing: self), type: .deinited)
    }
}

// MARK: - Internal

private extension ScansPreviewViewModel {
    
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
