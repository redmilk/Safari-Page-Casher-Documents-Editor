//
//  
//  PrintingOptionsViewModel.swift
//  AirPrint
//
//  Created by Danyl Timofeyev on 26.11.2021.
//
//

import Foundation
import Combine

final class PrintingOptionsViewModel {
    enum Action {
        case dummyAction
    }
    
    let input = PassthroughSubject<PrintingOptionsViewModel.Action, Never>()
    let output = PassthroughSubject<PrintingOptionsViewController.State, Never>()
    
    private let coordinator: PrintingOptionsCoordinatorProtocol & CoordinatorProtocol
    private var bag = Set<AnyCancellable>()

    init(coordinator: PrintingOptionsCoordinatorProtocol & CoordinatorProtocol) {
        self.coordinator = coordinator
        dispatchActions()
    }
    deinit {
        Logger.log(String(describing: self), type: .deinited)
    }
}

// MARK: - Internal

private extension PrintingOptionsViewModel {
    
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
