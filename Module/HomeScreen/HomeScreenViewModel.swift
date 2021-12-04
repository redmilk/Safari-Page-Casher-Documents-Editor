//
//  
//  HomeScreenViewModel.swift
//  AirPrint
//
//  Created by Danyl Timofeyev on 26.11.2021.
//
//

import Foundation
import Combine

final class HomeScreenViewModel: UserSessionServiceProvidable, PdfServiceProvidable {
    enum Action {
        case openMenu
        case deleteItem(PrintableDataBox)
    }
    
    let input = PassthroughSubject<HomeScreenViewModel.Action, Never>()
    let output = PassthroughSubject<HomeScreenViewController.State, Never>()
    
    private let coordinator: HomeScreenCoordinatorProtocol & CoordinatorProtocol
    private var bag = Set<AnyCancellable>()

    init(coordinator: HomeScreenCoordinatorProtocol & CoordinatorProtocol) {
        self.coordinator = coordinator
    }
    deinit {
        Logger.log(String(describing: self), type: .deinited)
    }
    func configureViewModel() {
        handleActions()
    }
}

// MARK: - Private

private extension HomeScreenViewModel {
    
    func handleActions() {
        /// Logger.log("handleActions")
        input.sink(receiveValue: { [weak self] action in
            switch action {
            case .openMenu:
                self?.coordinator.showMainMenuAndHandleActions()
            case .deleteItem(let data):
                self?.userSession.input.send(.deleteItem(data))
            }
        })
        .store(in: &bag)
        
        coordinator.photoalbumOutput.receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] dataBox in
            self?.userSession.input.send(.addItems([dataBox]))
        })
        .store(in: &bag)
        
        coordinator.cameraScanerOutput.sink(receiveValue: { [weak self] imageList in
            let data = imageList.map {
                PrintableDataBox(id: Date().millisecondsSince1970.description, image: $0, document: nil)
            }
            self?.userSession.input.send(.addItems(data))
        })
        .store(in: &bag)
        
        coordinator.cloudFilesOutput.sink(receiveValue: { [weak self] pdf in
            guard let pdfPagesAsDocuments = self?.pdfService.makeSeparatePdfDocumentFromPdf(pdf),
                  let self = self else { return }
            let imageThumbnails = pdfPagesAsDocuments.map { PrintableDataBox(id: Date().millisecondsSince1970.description, image: self.pdfService.makeImageFromPdfDocument($0, withImageSize: UIScreen.main.bounds.size, ofPageIndex: 0), document: $0) }
            self.userSession.input.send(.addItems(imageThumbnails))
            Logger.log("pdf thumbnail count: \(imageThumbnails.count.description)")
            
        })
        .store(in: &bag)
        
        coordinator.webpageOutput.sink(receiveValue: { [weak self] dataBoxList in
            self?.userSession.input.send(.addItems(dataBoxList))
        })
        .store(in: &bag)
        
        userSession.output.sink(receiveValue: { [weak self] data in
            if data.count == 0 {
                self?.output.send(.empty)
            } else {
                self?.output.send(.newCollectionData(data))
            }
        })
        .store(in: &bag)
    }
}
