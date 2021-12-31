//
//  
//  ManageSubscriptionsViewModel.swift
//  AirPrint
//
//  Created by Danyl Timofeyev on 11.12.2021.
//
//

import Foundation
import Combine
import UIKit

final class ManageSubscriptionsViewModel: PurchesServiceProvidable,
                                          SubscriptionsMultiPopupProvidable {
    enum Action {
        case subscription(Purchase)
        case checkCurrentSubscriptionPlan
        case restoreSubscription
        case viewDidLoad
    }
    
    let input = PassthroughSubject<ManageSubscriptionsViewModel.Action, Never>()
    let output = PassthroughSubject<ManageSubscriptionsViewController.State, Never>()
    
    private let coordinator: ManageSubscriptionsCoordinatorProtocol & CoordinatorProtocol
    private var bag = Set<AnyCancellable>()

    init(coordinator: ManageSubscriptionsCoordinatorProtocol & CoordinatorProtocol) {
        self.coordinator = coordinator
        
        input.sink(receiveValue: { [weak self] action in
            switch action {
            case .viewDidLoad:
                self?.purchases.updatedAllPrices()
                self?.highlightCurrentSubscriptionPlan()
            case .subscription(let purchase):
                switch purchase {
                case .weekly: self?.purchaseSubscriptionPlan(.weekly)
                case .monthly: self?.purchaseSubscriptionPlan(.monthly)
                case .annual: self?.purchaseSubscriptionPlan(.annual)
                case _: break
                }
            case .checkCurrentSubscriptionPlan:
                self?.highlightCurrentSubscriptionPlan()
            case .restoreSubscription:
                self?.restoreLastSubscription()
            }
        })
        .store(in: &bag)
        
        purchases.output.sink(receiveValue: { [weak self] response in
            guard let self = self else { return }
            switch response {
            case .gotUpdatedPrices(let weekly, let monthly, let yearly):
                self.output.send(.gotUpdatedPrices(weekly, monthly, yearly, self.purchases.isUserEverHadSubscriptions))
            case .hasActiveSubscriptions(let hasActiveSubscription):
                break
            case _: break
            }
        }).store(in: &self.bag)
    }
    deinit {
        Logger.log(String(describing: self), type: .deinited)
    }
}

// MARK: - Internal

private extension ManageSubscriptionsViewModel {
    
    private func purchaseSubscriptionPlan(_ plan: Purchase) {
        output.send(.loadingState(true))
        purchases.buy(model: plan).sink(receiveCompletion: { [weak self] completion in
            self?.output.send(.loadingState(false))
            switch completion {
            case .failure(let purchaseError):
                if let errorText = self?.purchases.handleErrorAsErrorText(purchaseError) {
                    self?.output.send(.displayAlert(text: errorText, title: "Purchase error", action: nil, buttonTitle: nil))
                }
            case _: break
            }
        }, receiveValue: { [weak self] in
            self?.output.send(.removeSubscriptionPop)
            self?.highlightCurrentSubscriptionPlan()
            if self?.purchases.isUserHasActiveSubscription ?? false {
                self?.output.send(.displayAlert(text: "Subscription plan was successfully purchased", title: "Success", action: nil, buttonTitle: nil))
                Logger.log("Successfully purchased annual subscription", type: .purchase)
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
                let errorText = self.purchases.handleErrorAsErrorText(error)
                self.output.send(.displayAlert(text: errorText, title: "Restore error", action: nil, buttonTitle: nil))
            case _: break
            }
        }, receiveValue: { [weak self] isSuccess in
            self?.output.send(.removeSubscriptionPop)
            self?.highlightCurrentSubscriptionPlan()
            if isSuccess && self?.purchases.isUserHasActiveSubscription ?? false {
                self?.output.send(.displayAlert(text: "Your previous subscription plan was restored successfully", title: "Success", action: nil, buttonTitle: nil))
                Logger.log("Successfully restored previous subscription", type: .purchase)
            } else {
                self?.output.send(.displayAlert(text: "Any data related to your previous subscription plan wasn't found", title: "Nothing to restore", action: nil, buttonTitle: nil))
            }
        }).store(in: &bag)
    }
    
    private func highlightCurrentSubscriptionPlan() {
        if purchases.checkIfPurchaseIsActive(.weekly) {
            output.send(.currentSubscriptionPlan(.weekly))
        }
        if purchases.checkIfPurchaseIsActive(.monthly) {
            output.send(.currentSubscriptionPlan(.monthly))
        }
        if purchases.checkIfPurchaseIsActive(.annual) {
            output.send(.currentSubscriptionPlan(.annual))
        }
    }
}
