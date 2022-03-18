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
import UIKit

final class HomeScreenMenuViewModel: PurchesServiceProvidable, SubscriptionsMultiPopupProvidable {
    enum Action {
        case scanAction
        case printPhoto
        case printDocument
        case printWebPage
        case printFromClipboard
        case closeAction
        case purchase(Purchase)
        case restoreSubscription
        case howTrialWorks(container: UIView)
        case otherPlans(container: UIView)
    }
    
    let input = PassthroughSubject<HomeScreenMenuViewModel.Action, Never>()
    let output = PassthroughSubject<HomeScreenMenuViewController.State, Never>()
    
    var isPaidUser: Bool {
        purchases.isUserHasActiveSubscription
    }
    
    private let coordinator: HomeScreenMenuCoordinatorProtocol & CoordinatorProtocol
    private var bag = Set<AnyCancellable>()
    
    private var proceedWithActionAfterSubscriptionReady: Action?
    private var actionContent: (UIImage, UIImage, String, String)?
    
    private let subscriptionPopupContent = [
        (UIImage(named: "menu-subscription-photos")!,
         UIImage(named: "button-green-blank")!,
         "Print photos directly from", "the gallery"),
        
        (UIImage(named: "menu-subscription-document")!,
         UIImage(named: "button-yellow-blank")!,
         "Select documents from", "your iCloud"),
        
        (UIImage(named: "menu-subscription-webprint")!,
         UIImage(named: "button-red-blank")!,
         "Ability to quickly print", "web page"),
        
        (UIImage(named: "menu-subscription-clipboard")!,
         UIImage(named: "button-blue-blank")!,
         "Copy and paste the text", "you want to print")
    ]

    init(coordinator: HomeScreenMenuCoordinatorProtocol & CoordinatorProtocol) {
        self.coordinator = coordinator
        handleActions()
        
        purchases.output.sink(receiveValue: { [weak self] response in
            switch response {
            case .hasActiveSubscriptions(let hasActiveSubscriptions, let shouldShowHowItWorks):
                guard hasActiveSubscriptions,
                        let action = self?.proceedWithActionAfterSubscriptionReady,
                        let popUpContent = self?.actionContent else { return }
                self?.coordinator.endWithSelectedAction(action)
            case _: break
            }
        }).store(in: &bag)
    }
    deinit {
        Logger.log(String(describing: self), type: .deinited)
    }
    
    private func handleActions() {
        input.sink(receiveValue: { [weak self] action in
            guard let hasSubscription = self?.purchases.isUserHasActiveSubscription, hasSubscription else {
                var content: (UIImage, UIImage, String, String)?
                switch action {
                case .printDocument:
                    self?.proceedWithActionAfterSubscriptionReady = action
                    content = self?.subscriptionPopupContent[1]
                    self?.actionContent = content
                case .printFromClipboard:
                    self?.proceedWithActionAfterSubscriptionReady = action
                    content = self?.subscriptionPopupContent[3]
                    self?.actionContent = content
                case .printPhoto:
                    self?.proceedWithActionAfterSubscriptionReady = action
                    content = self?.subscriptionPopupContent[0]
                    self?.actionContent = content
                case .printWebPage:
                    self?.proceedWithActionAfterSubscriptionReady = action
                    content = self?.subscriptionPopupContent[2]
                    self?.actionContent = content
                case .closeAction, .scanAction:
                    self?.coordinator.endWithSelectedAction(action)
                case . purchase(let plan):
                    self?.purchaseSubscriptionPlan(plan)
                case .restoreSubscription:
                    self?.restoreLastSubscription()
                case .otherPlans(let container):
                    self?.displayMultisubscriptionsPopup(inContainer: container, optionToShowFirst: .planOptions)
                case .howTrialWorks(let container):
                    self?.displayMultisubscriptionsPopup(inContainer: container, optionToShowFirst: .howItWorks)
                }
                if let content = content {
                    self?.output.send(.showSubscriptionPopup(withContent: content))
                }
                return
            }
            self?.coordinator.endWithSelectedAction(action)
        })
        .store(in: &bag)
    }
     
    /// universal subscription popup
    private func displayMultisubscriptionsPopup(
        inContainer container: UIView,
        optionToShowFirst: SubscriptionPlanPopup.State
    ) {
        let (publisher, popUp) = displayMultiSubscriptions(optionToShowFirst, fromParentView: container)
        publisher.sink(receiveValue: { [weak self] response in
            switch response {
            case .restoreSubscription:
                self?.restoreLastSubscription()
            case .onPurchase(let isSecondOptionSelected):
                self?.purchaseSubscriptionPlan(isSecondOptionSelected ? .annual : .monthly)
            case .onWeeklyPurchase:
                self?.purchaseSubscriptionPlan(.weekly)
            case .onClose:
                popUp.removeFromSuperview()
            }
        }).store(in: &bag)
    }
    
    private func purchaseSubscriptionPlan(_ plan: Purchase) {
        output.send(.loadingState(true))
        purchases.buy(model: plan).sink(receiveCompletion: { [weak self] completion in
            self?.output.send(.loadingState(false))
            switch completion {
            case .failure(let purchaseError):
                guard let self = self else { return }
                let errorText = self.purchases.handleErrorAsErrorText(purchaseError)
                self.output.send(.displayAlert(text: errorText, title: "Purchase error", action: nil, buttonTitle: nil))
            case _: break
            }
        }, receiveValue: { [weak self] in
            if self?.purchases.isUserHasActiveSubscription ?? false {
                self?.output.send(.displayAlert(text: "Selected subscription plan was successfully purchased", title: "Success", action: nil, buttonTitle: nil))
                Logger.log("Successfully purchased annual subscription", type: .purchase)
                if let userActionBeforeSubscriptionDialog = self?.proceedWithActionAfterSubscriptionReady {
                    self?.coordinator.endWithSelectedAction(userActionBeforeSubscriptionDialog)
                }
            }
            Logger.log("Purchase is not detected", type: .purchase)
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
                self.output.send(.displayAlert(text: errorMessage, title: "Restore error", action: nil, buttonTitle: nil))
                Logger.logError(error)
            case _: break
            }
        }, receiveValue: { [weak self] isSuccess in
            if isSuccess && self?.purchases.isUserHasActiveSubscription ?? false {
                self?.output.send(.displayAlert(text: "Your previous subscription plan was restored successfully", title: "Success", action: nil, buttonTitle: nil))
                Logger.log("Restore subscription: Purchase is not detected", type: .purchase)
                if let userActionBeforeSubscriptionDialog = self?.proceedWithActionAfterSubscriptionReady {
                    self?.coordinator.endWithSelectedAction(userActionBeforeSubscriptionDialog)
                }
            } else {
                self?.output.send(.displayAlert(text: "Any data related to your previous subscription plan wasn't found", title: "Nothing to restore", action: nil, buttonTitle: nil))
            }
        }).store(in: &bag)
    }
}
