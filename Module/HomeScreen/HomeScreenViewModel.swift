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

final class HomeScreenViewModel: UserSessionServiceProvidable,
                                 PdfServiceProvidable,
                                 SharedActivityResultsProvidable,
                                 PurchesServiceProvidable {
    enum Action {
        case didPressCell(dataBox: PrintableDataBox)
        case openMenu
        case deleteSelectedItem
        case deleteAll
        case viewDidAppear
        case viewDisapear
        case itemsDeleteConfirmed
        case itemsDeleteRejected
        case getSelectionCount
        case didTapPrint
        case didTapSettings
    }
    
    let input = PassthroughSubject<HomeScreenViewModel.Action, Never>()
    let output = PassthroughSubject<HomeScreenViewController.State, Never>()

    private var coordinator: HomeScreenCoordinatorProtocol & CoordinatorProtocol
    private var bag = Set<AnyCancellable>()
    private var trackingEnterForeground: AnyCancellable?
    
    init(coordinator: HomeScreenCoordinatorProtocol & CoordinatorProtocol) {
        self.coordinator = coordinator
    }
    deinit {
        Logger.log(String(describing: self), type: .deinited)
    }
    func configureViewModel() {
        handleActions()
        coordinator.copyFromClipboardCallback = { [weak self] in
            self?.handleCopyFromClipboard()
        }
    }
}

// MARK: - Private

private extension HomeScreenViewModel {
   
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
    
    func handleCopyFromClipboard() {
        guard UIPasteboard.general.hasStrings,
              let content = UIPasteboard.general.string,
              let pdf = pdfService.createPDFWithText(content) else { return }
        Logger.log(content)
        let dataBox = PrintableDataBox(
            id: Date().millisecondsSince1970.description,
            image: self.pdfService.makeImageFromPDFDocument(pdf, withImageSize: UIScreen.main.bounds.size, ofPageIndex: 0),
            document: pdf)
        userSession.input.send(.addItems([dataBox]))
    }
    
    
    func searchForSharedItems() {
        let itemsCount = sharedResults.searchSharedItems()
        Logger.log("Shared items count: " + itemsCount.description)
        if let url = sharedResults.searchSharedURL() {
            coordinator.showWebView(initialURL: url)
        }
    }
    
    func handleActions() {
        input.sink(receiveValue: { [weak self] action in
            switch action {
            case .openMenu:
                self?.coordinator.showMainMenuAndHandleActions()
            case .didTapSettings:
                self?.coordinator.displaySettings()
            case .deleteAll:
                self?.userSession.input.send(.deleteAll)
            case .viewDidAppear:
                self?.searchForSharedItems()
                self?.trackEnterForeground()
            case .viewDisapear:
                self?.trackingEnterForeground?.cancel()
            case .itemsDeleteConfirmed:
                self?.userSession.input.send(.deleteSelected)
            case .itemsDeleteRejected:
                self?.userSession.input.send(.cancelSelection)
            case .didPressCell(let dataBox):
                self?.openFileEditorWithData(dataBox)
            case .didTapPrint:
                self?.coordinator.displayPrintSettings()
            case .deleteSelectedItem:
                break
            case .getSelectionCount:
                self?.userSession.input.send(.getSelectionCount)
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
        
        userSession.output.sink(receiveValue: { [weak self] response in
            switch response {
            case .empty: self?.output.send(.empty)
            case .allCurrentData(let allData): self?.output.send(.allCurrentData(allData))
            case .addedItems(let addNewItems): self?.output.send(.addedItems(addNewItems))
            case .deletedItems(let deletedItems): self?.output.send(.deletedItems(deletedItems))
            case .selectedItems(let selectedItems): self?.output.send(.selectedItems(selectedItems))
            case .selectionCount(let selectionCount): self?.output.send(.selectionCount(selectionCount))
            }
        })
        .store(in: &bag)
        
        purchases.startTimerForGiftOffer()
        purchases.output.sink(receiveValue: { [weak self] response in
            switch response {
            case .timerTick(let timerTickText):
                self?.output.send(.timerTick(timerText: timerTickText))
            }
        }).store(in: &bag)
    }
    
    func trackEnterForeground() {
        trackingEnterForeground?.cancel()
        trackingEnterForeground = NotificationCenter.default
            .publisher(for: UIApplication.willEnterForegroundNotification)
            .sink() { [weak self] _ in
                self?.searchForSharedItems()
            }
    }
    
    // MARK: - Purchase
    
    private func checkActiveSubscriptions() {
        purchases.isActiveSubscription
            .sink(receiveValue: { [weak self] isActive in
                if let isActive = isActive {
                    print("hasActive subscr")
                    if isActive {
                        //self?.purchase(.weekly)
                    } else {
                        self?.purchase(.annual)
                    }
                } else {
                    print("isActive == nil")
                }
            })
            .store(in: &bag)
    }
    
    private func purchase(_ plan: Purchase) {
        purchases
            .buy(model: plan)
            .sink(receiveCompletion: { completion in
                switch completion {
                case .failure(let purchaseError):
                    print(purchaseError.localizedDescription)
                case _: break
                }
            }, receiveValue: { isSucceed in
                if isSucceed {
                    print("purchase: successfully purchased")
                    
                } else {
                    print("purchase: something went wrong")
                    
                }
            })
            .store(in: &bag)
    }
    
}
