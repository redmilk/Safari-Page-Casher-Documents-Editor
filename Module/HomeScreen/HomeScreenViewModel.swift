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

import PDFKit.PDFDocument

final class HomeScreenViewModel: UserSessionServiceProvidable, PdfServiceProvidable {
    enum Action {
        case openMenu
        case didPressCellWithData(PrintableDataBox)
        case deleteItems([PrintableDataBox])
        case enterSelectionMode
        case exitSelectionMode
        case selectItem(PrintableDataBox)
        case didTapPrint
        case reloadCollection
    }
    
    let input = PassthroughSubject<HomeScreenViewModel.Action, Never>()
    let output = PassthroughSubject<HomeScreenViewController.State, Never>()
    
    var deletePendingItems: [PrintableDataBox] = []
    
    private var isViewInSelectionMode: Bool = false
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
   
    func resolveCellTapAction(_ dataBox: PrintableDataBox) {
        if isViewInSelectionMode {
            deletePendingItems.append(dataBox)
            output.send(.selectionMode)
            userSession.input.send(.selectItemsToDelete([dataBox]))
        } else {
            openFileEditorWithData(dataBox)
        }
    }
    
    func openFileEditorWithData(_ dataBox: PrintableDataBox) {
        guard let fileURL = prepareAndSaveDataBoxAsPDFDocumentIntoTempDir(dataBox) else { return }
        if let pdftest = PDFDocument(url: fileURL) {
            print(pdftest.pageCount)
        }
        coordinator.displayFileEditor(fileURL: fileURL)
        /// helper for editor session
        func prepareAndSaveDataBoxAsPDFDocumentIntoTempDir(_ dataBox: PrintableDataBox) -> URL? {
            userSession.input.send(.createTempFileForEditing(withNameAndFormat: "\(dataBox.id).pdf", forDataBox: dataBox))
            guard let tempfileURL = userSession.editingTempFile?.fileURL,
                  let pdf = pdfService.convertPrintableDataBoxesToSinglePDFDocument([dataBox]) else {
                Logger.log("Missing temp file for edit inside userSession")
                return nil
            }
            pdfService.savePdfIntoTempDirectory(pdf, filepath: tempfileURL)
            return tempfileURL
        }
    }
    
    func handleActions() {
        input.sink(receiveValue: { [weak self] action in
            switch action {
            case .openMenu:
                self?.coordinator.showMainMenuAndHandleActions()
            case .deleteItems(let dataBox):
                self?.userSession.input.send(.deleteItems(dataBox))
            case .didPressCellWithData(let dataBox):
                self?.resolveCellTapAction(dataBox)
            case .selectItem(let dataBox):
                self?.userSession.input.send(.selectItemsToDelete([dataBox]))
            case .enterSelectionMode:
                self?.isViewInSelectionMode.toggle()
                guard let self = self else { return }
                self.output.send(self.isViewInSelectionMode ? .selectionMode : .exitSelectionMode)
            case .exitSelectionMode:
                self?.isViewInSelectionMode = false
                self?.output.send(.exitSelectionMode)
            case .reloadCollection:
                self?.userSession.input.send(.populateWithCurrentSessionData)
            case .didTapPrint:
                self?.coordinator.displayPrintSettings()
            }
        })
        .store(in: &bag)
        
        coordinator.photoalbumOutput.receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] dataBox in
            self?.userSession.input.send(.addItems([dataBox]))
        })
        .store(in: &bag)
        
        coordinator.cameraScanerOutput.sink(receiveValue: { [weak self] dataBoxList in
            self?.userSession.input.send(.addItems(dataBoxList))
        })
        .store(in: &bag)
        
        coordinator.cloudFilesOutput.sink(receiveValue: { [weak self] dataBoxList in
            Logger.log("pdf dataBoxList count: \(dataBoxList.count.description)")
            self?.userSession.input.send(.addItems(dataBoxList))
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
