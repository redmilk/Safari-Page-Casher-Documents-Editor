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
        case printWebPage
        
        case closeAction
    }
    
    let input = PassthroughSubject<HomeScreenMenuViewModel.Action, Never>()
    let output = PassthroughSubject<HomeScreenMenuViewController.State, Never>()
    
    private let coordinator: HomeScreenMenuCoordinatorProtocol & CoordinatorProtocol
    private var bag = Set<AnyCancellable>()

    init(coordinator: HomeScreenMenuCoordinatorProtocol & CoordinatorProtocol) {
        self.coordinator = coordinator
        handleActions()
    }
    deinit {
        Logger.log(String(describing: self), type: .deinited)
    }
    
    private func handleActions() {
        input.sink(receiveValue: { [weak self] action in
            self?.coordinator.endWithSelectedAction(action)
        })
        .store(in: &bag)
    }
}
