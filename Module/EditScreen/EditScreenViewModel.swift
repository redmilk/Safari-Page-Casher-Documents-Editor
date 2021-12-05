//
//  
//  EditScreenViewModel.swift
//  AirPrint
//
//  Created by Danyl Timofeyev on 26.11.2021.
//
//

import Foundation
import Combine

final class EditScreenViewModel {
    enum Action {
        case displayFileEditor
    }
    
    let input = PassthroughSubject<EditScreenViewModel.Action, Never>()
    let output = PassthroughSubject<EditScreenViewController.State, Never>()
    
    private let coordinator: EditScreenCoordinatorProtocol & CoordinatorProtocol
    private var bag = Set<AnyCancellable>()

    init(coordinator: EditScreenCoordinatorProtocol & CoordinatorProtocol) {
        self.coordinator = coordinator
        dispatchActions()
    }
    deinit {
        Logger.log(String(describing: self), type: .deinited)
    }
}

// MARK: - Internal

private extension EditScreenViewModel {
    
    /// Handle ViewController's actions
    private func dispatchActions() {
        input.sink(receiveValue: { [weak self] action in
            switch action {
            case .displayFileEditor: break
            }
        })
        .store(in: &bag)
    }
}
