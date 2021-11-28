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
import PDFKit.PDFDocument

final class PdfViewerViewModel {
    enum Action {
        case dummyAction
    }
    
    let input = PassthroughSubject<PdfViewerViewModel.Action, Never>()
    let output = CurrentValueSubject<PdfViewerViewController.State?, Never>(nil)
    
    private let coordinator: PdfViewerCoordinatorProtocol & CoordinatorProtocol
    private var bag = Set<AnyCancellable>()
    
    let pdf: PDFDocument
    var pdfUrl: URL { pdf.documentURL! } /// crash if generated from code and not saved

    init(coordinator: PdfViewerCoordinatorProtocol & CoordinatorProtocol, pdf: PDFDocument) {
        self.coordinator = coordinator
        self.pdf = pdf
        output.send(.renderPdf(pdf))
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
