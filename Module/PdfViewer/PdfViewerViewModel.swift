//
//  
//  PdfViewerViewModel.swift
//  AirPrint
//
//  Created by Danyl Timofeyev on 23.11.2021.
//
//

import Foundation
import Combine
import PDFKit

final class PdfViewerViewModel {
    enum Action {
        case dummyAction
    }
    
    let input = PassthroughSubject<PdfViewerViewModel.Action, Never>()
    let output = CurrentValueSubject<PdfViewerViewController.State?, Never>(nil)
    
    private let coordinator: PdfViewerCoordinatorProtocol & CoordinatorProtocol
    private var bag = Set<AnyCancellable>()
    
    let pdfUrl: URL

    init(coordinator: PdfViewerCoordinatorProtocol & CoordinatorProtocol, pdfUrl: URL) {
        self.coordinator = coordinator
        self.pdfUrl = pdfUrl
        output.send(.renderPdf(PDFDocument(url: pdfUrl)!))
        dispatchActions()
    }
    deinit {
        Logger.log(String(describing: self), type: .deinited)
    }
}

// MARK: - Internal

private extension PdfViewerViewModel {
    
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
