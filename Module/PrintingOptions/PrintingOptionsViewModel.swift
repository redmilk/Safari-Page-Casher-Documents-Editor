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
import PDFKit.PDFDocument

final class PrintingOptionsViewModel: PdfServiceProvidable, UserSessionServiceProvidable {
    enum Action {
        case showDefaultPrintingDialog
    }
    
    let input = PassthroughSubject<PrintingOptionsViewModel.Action, Never>()
    let output = PassthroughSubject<PrintingOptionsViewController.State, Never>()
    
    private let coordinator: PrintingOptionsCoordinatorProtocol & CoordinatorProtocol
    private var bag = Set<AnyCancellable>()

    init(coordinator: PrintingOptionsCoordinatorProtocol & CoordinatorProtocol) {
        self.coordinator = coordinator
        handleActions()
    }
    deinit {
        Logger.log(String(describing: self), type: .deinited)
    }
}

// MARK: - Internal

private extension PrintingOptionsViewModel {
    
    /// Handle ViewController's actions
    func handleActions() {
        input.sink(receiveValue: { [weak self] action in
            switch action {
            case .showDefaultPrintingDialog:
                guard let pdfData = self?.prepareSessionPrintingData() else { return }
                self?.coordinator.displayDefaultPrintingOptionsDialog(withPdfData: pdfData)
            }
        })
        .store(in: &bag)
    }
        
    func prepareSessionPrintingData() -> Data? {
        guard let resultPdf = pdfService.convertPrintableDataBoxesToSinglePDFDocument(userSession.sessionResult) else {
            return nil
        }
        return resultPdf.dataRepresentation()
    }
}
