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

final class HomeScreenMenuViewModel {
    enum Action {
        case scanAction
        case printPhoto
        case printDocument
        case printWebPage
        case printFromClipboard
        case closeAction
    }
    
    let input = PassthroughSubject<HomeScreenMenuViewModel.Action, Never>()
    let output = PassthroughSubject<HomeScreenMenuViewController.State, Never>()
    
    private let coordinator: HomeScreenMenuCoordinatorProtocol & CoordinatorProtocol
    private var bag = Set<AnyCancellable>()
    private var isAlreadySubscribed: Bool {
        return false
    }
    
    private let subscriptionPopupContent = [
        (UIImage(named: "menu-subscription-photos")!,
         UIImage(named: "menu-subscription-photo-button")!,
         "Print photos directly from", "the gallery"),
        
        (UIImage(named: "menu-subscription-document")!,
         UIImage(named: "menu-subscription-doc-button")!,
         "Select documents from", "your iCloud"),
        
        (UIImage(named: "menu-subscription-webpage")!,
         UIImage(named: "menu-subscription-web-button")!,
         "Ability to quickly print", "web page"),
        
        (UIImage(named: "menu-subscription-clipboard")!,
         UIImage(named: "menu-subscription-clipb-button")!,
         "Copy and paste the text", "you want to print")
    ]

    init(coordinator: HomeScreenMenuCoordinatorProtocol & CoordinatorProtocol) {
        self.coordinator = coordinator
        handleActions()
    }
    deinit {
        Logger.log(String(describing: self), type: .deinited)
    }
    
    private func handleActions() {
        input.sink(receiveValue: { [weak self] action in
            guard let hasSubscription = self?.isAlreadySubscribed, hasSubscription else {
                var content: (UIImage, UIImage, String, String)?
                switch action {
                case .printDocument: content = self?.subscriptionPopupContent[1]
                case .printFromClipboard: content = self?.subscriptionPopupContent[3]
                case .printPhoto: content = self?.subscriptionPopupContent[0]
                case .printWebPage: content = self?.subscriptionPopupContent[2]
                case .closeAction, .scanAction: self?.coordinator.endWithSelectedAction(action)
                case _: return
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
}
