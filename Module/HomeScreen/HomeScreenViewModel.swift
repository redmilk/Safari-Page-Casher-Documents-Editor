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
import UIKit

final class HomeScreenViewModel: UserSessionServiceProvidable,
                                 PdfServiceProvidable,
                                 SharedActivityResultsProvidable,
                                 PurchesServiceProvidable,
                                 SubscriptionsMultiPopupProvidable {
    enum Action {
        case didPressCell(dataBox: PrintableDataBox)
        case openMenu
        case deleteAll(shouldConfirm: Bool)
        case viewDidAppear
        case viewDisapear
        case itemsDeleteConfirmed
        case itemsDeleteRejected
        case getSelectionCount
        case didTapPrint
        case didTapSettings
        case purchase(Purchase)
        case restoreSubscription
        case memoryWarning
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
        purchases.input.send(.congifure)
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
        
        guard !(UIPasteboard.general.images ?? []).isEmpty || !(UIPasteboard.general.string ?? "").isEmpty else {
                return output.send(.displayAlert(text: "Photos or text not found, nothing to paste here",
                                                 title: "Empty buffer", action: nil, buttonTitle: nil))
        }
        if !(UIPasteboard.general.string ?? "").isEmpty {
            guard let content = UIPasteboard.general.string,
                  let pdf = pdfService.createPDFWithText(content) else { return }
            let dataBox = PrintableDataBox(
                id: Date().millisecondsSince1970.description,
                image: self.pdfService.makeImageFromPDFDocument(pdf, withImageSize: UIScreen.main.bounds.size, ofPageIndex: 0),
                document: pdf)
            userSession.input.send(.addItems([dataBox]))
        } else {
            guard let images = UIPasteboard.general.images, !images.isEmpty else { return }
            let dataBoxList = images.map { PrintableDataBox(id: Date().millisecondsSince1970.description,
                                                            image: $0, document: nil) }
            userSession.input.send(.addItems(dataBoxList))
        }
        
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
            case .deleteAll(let shouldConfirm):
                shouldConfirm ? self?.userSession.input.send(.deleteAll) :
                self?.userSession.input.send(.deleteAllWithoutConfirmation)
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
                self?.coordinator.displayPrintSettings(didPresentCallback: { [weak self] in
                    self?.output.send(.loadingState(false))
                })
            case .getSelectionCount:
                self?.userSession.input.send(.getSelectionCount)
            case .purchase(let purchase):
                self?.purchaseSubscriptionPlan(purchase)
            case .restoreSubscription:
                self?.restoreLastSubscription()
            case .memoryWarning:
                guard let itemsTotal = self?.userSession.itemsTotal, itemsTotal > 20 else { return }
                self?.output.send(.displayAlert(text: "Your device's memory is too low. Unfortunately, the application will partially purge your previously added files that have not yet been edited", title: "Warning", action: nil, buttonTitle: nil))
                self?.userSession.input.send(.handleMemoryWarning)
            }
        }).store(in: &bag)
        
        coordinator.photoalbumOutput.receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] dataBox in
            self?.userSession.input.send(.addItems([dataBox]))
        }).store(in: &bag)
        
        coordinator.cameraScanerOutput.sink(receiveValue: { [weak self] dataBoxList in
            self?.userSession.input.send(.addItems(dataBoxList))
        }).store(in: &bag)
        
        coordinator.cloudFilesOutput.sink(receiveValue: { [weak self] dataBoxList in
            Logger.log("pdf dataBoxList count: \(dataBoxList.count.description)")
            self?.userSession.input.send(.addItems(dataBoxList))
        }).store(in: &bag)
        
        coordinator.webpageOutput.sink(receiveValue: { [weak self] dataBoxList in
            self?.userSession.input.send(.addItems(dataBoxList))
        }).store(in: &bag)
        
        userSession.output.sink(receiveValue: { [weak self] response in
            switch response {
            case .empty: self?.output.send(.empty)
            case .allCurrentData(let allData): self?.output.send(.allCurrentData(allData))
            case .addedItems(let addNewItems): self?.output.send(.addedItems(addNewItems))
            case .deletedItems(let deletedItems): self?.output.send(.deletedItems(deletedItems))
            case .selectedItems(let selectedItems): self?.output.send(.selectedItems(selectedItems))
            case .selectionCount(let selectionCount): self?.output.send(.selectionCount(selectionCount))
            }
        }).store(in: &bag)
        
        purchases.startTimerForGiftOffer()
        purchases.output.sink(receiveValue: { [weak self] response in
            switch response {
            case .timerTick(let timerTickText):
                self?.output.send(.timerTick(timerText: timerTickText))
            case .hasActiveSubscriptions(let hasActiveSubscriptions, let shouldShowHowItWorks):

                guard let self = self else { return }
                let shouldDisplayMultiSubscrPopup = PurchesService.shouldDisplaySubscriptionsForCurrentUser
                self.output.send(.subscriptionStatus(
                    hasActiveSubscriptions: hasActiveSubscriptions,
                    shouldDisplayMultiSubscrPopup: shouldDisplayMultiSubscrPopup,
                    shouldShowHowItWorks: shouldShowHowItWorks))
            case .gotUpdatedPrices(_, _, let yearly):
                guard let yearlyStrike = self?.purchases.getFormattedYearPriceForPurchase(isPurePrice: true, size: 14) else { return }
                self?.output.send(.gotUpdatedPricesForGift(yearly: yearly, yearlyStrike: yearlyStrike))
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
    
    private func purchaseSubscriptionPlan(_ plan: Purchase) {
        output.send(.loadingState(true))
        purchases.buy(model: plan).sink(receiveCompletion: { [weak self] completion in
            self?.output.send(.loadingState(false))
            switch completion {
            case .failure(let purchaseError):
                guard let self = self else { return }
                let errorText = self.purchases.handleErrorAsErrorText(purchaseError)
                self.output.send(.displayAlert(text: errorText, title: "Something went wrong" , action: nil, buttonTitle: nil))
            case _: break
            }
        }, receiveValue: { [weak self] in
            self?.output.send(.displayAlert(text: "Selected subscription plan was successfully purchased", title: "Success", action: {
                self?.output.send(.collapseAllSubscriptionPopupsWhichArePresented)
            }, buttonTitle: nil))
        }).store(in: &bag)
    }
    
    private func restoreLastSubscription() {
        output.send(.loadingState(true))
        purchases.restoreLastExpiredPurchase().sink(receiveCompletion: { [weak self] completion in
            guard let self = self else { return }
            self.output.send(.loadingState(false))
            switch completion {
            case .failure(let error):
                let errorMessage = self.purchases.handleErrorAsErrorText(error)
                self.output.send(.displayAlert(text: errorMessage, title: "Failed to restore", action: nil, buttonTitle: nil))
                Logger.logError(error)
            case _: break
            }
        }, receiveValue: { [weak self] isSuccess in
            if isSuccess {
                self?.output.send(.displayAlert(text: "Your previous subscription plan was successfully restored", title: "Success", action: { self?.output.send(.collapseAllSubscriptionPopupsWhichArePresented) }, buttonTitle: nil))
            } else {
                self?.output.send(.displayAlert(text: "Any data related to your previous subscription plan wasn't found", title: "Nothing to restore", action: nil, buttonTitle: nil))
            }
        }).store(in: &bag)
    }
}
