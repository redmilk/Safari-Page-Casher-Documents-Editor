//
//  SubscriptionPlanPopup.swift
//  AirPrint
//
//  Created by Danyl Timofeyev on 21.12.2021.
//

import Foundation
import UIKit
import Combine

protocol SubscriptionPresentable where Self: UIViewController & PurchesServiceProvidable {
    func presentSubscriptionDialog()
    var bag: Set<AnyCancellable> { get set }
}

extension SubscriptionPresentable {
    func presentSubscriptionDialog() {
        purchases.isActiveSubscription.sink(receiveValue: { isActive in
            guard let hasActiveSubscriptions = isActive else {
                return Logger.log("Something went wrong, check internet connection")
            }
            let hasCanceledSubscription = false /// get from apphud
            if !hasActiveSubscriptions && !hasCanceledSubscription {
                
            }
        }).store(in: &bag)
    }
    
    private func displaySubscriptionPlanSelection() {
        let subscriptionPopup = SubscriptionPlanPopup()
        self.view.addSubview(subscriptionPopup)
        subscriptionPopup.constraintToSides(inside: self.view)
        subscriptionPopup.input.send(.configure(.weekly))
        subscriptionPopup.output.sink(receiveValue: { [weak self] response in
            guard let self = self else { return }
            switch response {
            case .onPurchase(let isSecondOptionSelected):
                self.purchases.buy(model: isSecondOptionSelected ? .annual : .monthly)
                    .sink(receiveCompletion: { completion in
                        if case .failure(let error) = completion {
                            Logger.logError(error)
                        }
                        subscriptionPopup.isHidden = true
                    }, receiveValue: { isSuccess in
                        if isSuccess {
                            Logger.log("Successfully purchased", type: .token)
                        } else {
                            Logger.log("Something went wrong", type: .token)
                        }
                        subscriptionPopup.isHidden = true
                    }).store(in: &self.bag)
            case .onClose:
                subscriptionPopup.isHidden = true
            }
        }).store(in: &bag)
    }
}

final class SubscriptionPlanPopup: UIView {
    enum State {
        case weekly
        case planOptions
        case howItWorks
    }
    enum Action {
        case configure(State)
    }
    enum Response {
        case onPurchase(isSecondOptionSelected: Bool)
        case onClose
    }
    
    let input = PassthroughSubject<Action, Never>()
    let output = PassthroughSubject<Response, Never>()
    
    @IBOutlet weak var weeklyContainer: UIView!
    @IBOutlet weak var planSelectionContainer: UIView!
    @IBOutlet weak var howItWorksContainer: UIView!
    
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var firstButton: UIButton!
    @IBOutlet weak var secondButton: UIButton!
    @IBOutlet weak var purchaseButton: UIButton!
    @IBOutlet weak var termsButton: UIButton!
    @IBOutlet weak var privacyButton: UIButton!
    @IBOutlet weak var restoreButton: UIButton!
    @IBOutlet weak var backgroundContainer: UIView!
    @IBOutlet weak var backgroundImageView: UIImageView!
    @IBOutlet weak var howItWorksContinue: UIButton!
    @IBOutlet weak var pickYourPlanLabel: UILabel!
    @IBOutlet weak var pickYourPlanDescriptionStack: UIStackView!
    
    private var isSecondOptionSelected = false
    private var bag = Set<AnyCancellable>()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initialSetup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        initialSetup()
    }
    
    private func initialSetup() {
        Bundle.main.loadNibNamed(String(describing: self), owner: self, options: nil)
        addSubview(contentView)
        contentView.constraintToSides(inside: self)
        input
            .sink(receiveValue: { [weak self] action in
                switch action {
                case .configure(let state):
                    self?.configureView()
                    self?.configureState(state)
                }
            })
            .store(in: &bag)
    }
    
    private func configureView() {
        planSelectionContainer.addCornerRadius(30)
        howItWorksContainer.addCornerRadius(30)
        weeklyContainer.addCornerRadius(30)
        
        planSelectionContainer.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        planSelectionContainer.dropShadow(color: .black, opacity: 0.4, offSet: .zero, radius: 30, scale: true)
        howItWorksContainer.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        howItWorksContainer.dropShadow(color: .black, opacity: 0.4, offSet: .zero, radius: 30, scale: true)
        weeklyContainer.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        weeklyContainer.dropShadow(color: .black, opacity: 0.4, offSet: .zero, radius: 30, scale: true)
        
        firstButton.publisher().sink(receiveValue: { [weak self] _ in
            self?.firstButton.isSelected.toggle()
            self?.secondButton.isSelected.toggle()
            self?.isSecondOptionSelected = false
        }).store(in: &bag)
        
        secondButton.publisher().sink(receiveValue: { [weak self] _ in
            self?.secondButton.isSelected.toggle()
            self?.firstButton.isSelected.toggle()
            self?.isSecondOptionSelected = true
        }).store(in: &bag)
        
        purchaseButton.publisher().sink(receiveValue: { [weak self] _ in
            guard let self = self else { return }
            self.output.send(.onPurchase(isSecondOptionSelected: self.isSecondOptionSelected))
        }).store(in: &bag)
        
        closeButton.publisher().sink(receiveValue: { [weak self] _ in
            self?.output.send(.onClose)
        }).store(in: &bag)
//
//        let emitter = ParticleEmitterView()
//        emitter.isUserInteractionEnabled = false
//        planSelectionContainer.insertSubview(emitter, at: 0)
//        emitter.constraintToSides(inside: planSelectionContainer)
    }
    
    private func configureState(_ state: State) {
        switch state {
        case .weekly: showWeeklyTrial()
        case .planOptions: showPlanSelection()
        case .howItWorks: showHowItWorks()
        }
    }
    
    private func showWeeklyTrial() {
        weeklyContainer.isHidden = false
        planSelectionContainer.isHidden = true
        howItWorksContainer.isHidden = true
        backgroundContainer.isHidden = true
        pickYourPlanLabel.isHidden = true
        pickYourPlanDescriptionStack.isHidden = true
    }
    
    private func showPlanSelection() {
        weeklyContainer.isHidden = true
        planSelectionContainer.isHidden = false
        howItWorksContainer.isHidden = true
        backgroundContainer.isHidden = true
        pickYourPlanLabel.isHidden = false
        pickYourPlanDescriptionStack.isHidden = false
    }
    
    private func showHowItWorks() {
        weeklyContainer.isHidden = true
        planSelectionContainer.isHidden = true
        howItWorksContainer.isHidden = false
        backgroundContainer.isHidden = false
        pickYourPlanLabel.isHidden = true
        pickYourPlanDescriptionStack.isHidden = true
    }
}
