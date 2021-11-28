//
//  
//  ExampleViewModel.swift
//  AirPrint
//
//  Created by Danyl Timofeyev on 18.11.2021.
//
//

import Foundation
import Combine
import PDFKit.PDFDocument

final class ExampleViewModel {
    enum Action {
        case dummyAction
        case displayPdfViewer(PDFDocument)
    }
    
    let input = PassthroughSubject<ExampleViewModel.Action, Never>()
    let output = PassthroughSubject<ExampleViewController.State, Never>()
    
    private let coordinator: ExampleCoordinatorProtocol & CoordinatorProtocol
    private var bag = Set<AnyCancellable>()

    init(coordinator: ExampleCoordinatorProtocol & CoordinatorProtocol) {
        self.coordinator = coordinator
        dispatchActions()
    }
    deinit {
        Logger.log(String(describing: self), type: .deinited)
    }
}

// MARK: - Internal

private extension ExampleViewModel {
    
    /// Handle ViewController's actions
    private func dispatchActions() {
        input.sink(receiveValue: { [weak self] action in
            switch action {
            case .displayPdfViewer(let pdf):
                self?.coordinator.displayPdfViewer(withPdf: pdf)
            case .dummyAction: break
            }
        })
        .store(in: &bag)
    }
}
