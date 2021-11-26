//
//  
//  ResultPreviewViewModel.swift
//  AirPrint
//
//  Created by Danyl Timofeyev on 26.11.2021.
//
//

import Foundation
import Combine

final class ResultPreviewViewModel {
    enum Action {
        case dummyAction
    }
    
    let input = PassthroughSubject<ResultPreviewViewModel.Action, Never>()
    let output = PassthroughSubject<ResultPreviewViewController.State, Never>()
    
    private let coordinator: ResultPreviewCoordinatorProtocol & CoordinatorProtocol
    private var bag = Set<AnyCancellable>()

    init(coordinator: ResultPreviewCoordinatorProtocol & CoordinatorProtocol) {
        self.coordinator = coordinator
        dispatchActions()
    }
    deinit {
        Logger.log(String(describing: self), type: .deinited)
    }
}

// MARK: - Internal

private extension ResultPreviewViewModel {
    
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
