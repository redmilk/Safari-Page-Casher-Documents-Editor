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

final class ManageSubscriptionsViewModel: PurchesServiceProvidable {
    enum Action {
        case subscription(Purchase)
        case checkCurrentSubscriptionPlan
    }
    
    let input = PassthroughSubject<ManageSubscriptionsViewModel.Action, Never>()
    let output = PassthroughSubject<ManageSubscriptionsViewController.State, Never>()
    
    private let coordinator: ManageSubscriptionsCoordinatorProtocol & CoordinatorProtocol
    private var bag = Set<AnyCancellable>()

    init(coordinator: ManageSubscriptionsCoordinatorProtocol & CoordinatorProtocol) {
        self.coordinator = coordinator
        dispatchActions()
    }
    deinit {
        Logger.log(String(describing: self), type: .deinited)
    }
}

// MARK: - Internal

private extension ManageSubscriptionsViewModel {
    
    /// Handle ViewController's actions
    private func dispatchActions() {
        input.sink(receiveValue: { [weak self] action in
            switch action {
            case .subscription(let purchase):
                switch purchase {
                case .weekly: self?.purchaseSubscriptionPlan(.weekly)
                case .monthly: self?.purchaseSubscriptionPlan(.monthly)
                case .annual: self?.purchaseSubscriptionPlan(.annual)
                }
            case .checkCurrentSubscriptionPlan:
                self?.highlightCurrentSubscriptionPlan()
            }
        })
        .store(in: &bag)
    }
    
    private func purchaseSubscriptionPlan(_ plan: Purchase) {
        output.send(.loadingState(true))
        purchases.buy(model: plan).sink(receiveCompletion: { [weak self] completion in
            self?.output.send(.loadingState(false))
            switch completion {
            case .failure(let purchaseError):
                Logger.log(purchaseError.localizedDescription, type: .purchase)
                Logger.logError(purchaseError)
            case _: break
            }
        }, receiveValue: { [weak self] in
            //self?.output.send(.currentSubscriptionPlan(plan))
            Logger.log("Successfully purchased annual subscription", type: .purchase)
            self?.highlightCurrentSubscriptionPlan()
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
