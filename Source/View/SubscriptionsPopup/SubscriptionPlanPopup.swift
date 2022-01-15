//
//  SubscriptionPlanPopup.swift
//  AirPrint
//
//  Created by Danyl Timofeyev on 21.12.2021.
//

import Foundation
import UIKit
import Combine

fileprivate let subscriptionsPopupViewTag: Int = 9876543210
protocol SubscriptionsMultiPopupProvidable {
    func displayMultiSubscriptions(_ subscriptionsScreen: SubscriptionPlanPopup.State, fromParentView view: UIView
    ) -> (publisher: AnyPublisher<SubscriptionPlanPopup.Response, Never>, popup: SubscriptionPlanPopup)
}
extension SubscriptionsMultiPopupProvidable {
    func displayMultiSubscriptions(
        _ subscriptionsScreen: SubscriptionPlanPopup.State,
        fromParentView view: UIView
    ) -> (publisher: AnyPublisher<SubscriptionPlanPopup.Response, Never>, popup: SubscriptionPlanPopup) {
        let subscriptionsView = SubscriptionPlanPopup()
        subscriptionsView.tag = subscriptionsPopupViewTag
        view.addAndFill(subscriptionsView)
        subscriptionsView.input.send(.configure(subscriptionsScreen))
        return (subscriptionsView.output.eraseToAnyPublisher(), subscriptionsView)
    }
}


// MARK: -
final class SubscriptionPlanPopup: UIView, PurchesServiceProvidable {
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
        case onWeeklyPurchase
        case restoreSubscription
        case onClose
    }
    
    let input = PassthroughSubject<Action, Never>()
    let output = PassthroughSubject<Response, Never>()
    
    @IBOutlet weak var weeklyContainer: UIView!
    @IBOutlet weak var planSelectionContainer: UIView!
    @IBOutlet weak var howItWorksContainer: UIView!
    @IBOutlet weak var mainContainer: UIView!
    @IBOutlet weak var blurViewStatic: BlurredShadowView2!
    
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var firstButton: UIButton!
    @IBOutlet weak var secondButton: UIButton!
    @IBOutlet weak var planSelectionContinueButton: UIButton!
    
    @IBOutlet weak var restoreSubscriptionsWeeklyButton: UIButton!
    @IBOutlet weak var restoreSubscriptionPlanSelection: UIButton!
    @IBOutlet weak var otherPlansWeekly: UIButton!
    
    @IBOutlet weak var hideOtherPlansButton: UIButton!
    @IBOutlet weak var pickYourPlanLabel: UILabel!
    @IBOutlet weak var pickYourPlanDescriptionStack: UIStackView!
    @IBOutlet weak var howItWorksTitle: UILabel!
    @IBOutlet weak var howItWorksContent: UIImageView!
    @IBOutlet weak var likeIconImage: UIImageView!
    @IBOutlet weak var hideOtherPlansButtonContainer: UIView!
    @IBOutlet weak var weeklyPlanPrice: UILabel!
    @IBOutlet weak var trialMessageLabel: UILabel!
    @IBOutlet weak var weeklyPurchaseContinue: UIButton!
    @IBOutlet weak var trialMessageBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var weeklyHowItWorksButton: UIButton!
    @IBOutlet weak var plansHowItWorksButton: UIButton!
    // prices
    @IBOutlet weak var yearlyPriceFirstPartLabel: UILabel!
    @IBOutlet weak var yearlyPriceSecondPart: UILabel!
    @IBOutlet weak var montlyPriceLabel: UILabel!
    
    private var bag = Set<AnyCancellable>()
    private var weeklyContinueAnimationsCancelable: AnyCancellable?
    private var planSelectionContinueAnimationsCanelable: AnyCancellable?
    private var isAdvantagesLabelsAnimationsWasPlayed: Bool = false
    private var isHowTrialWorkAnimationWasPlayed: Bool = false
    private var isSecondOptionSelected = false
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initialSetup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        initialSetup()
    }
    
    private func initialSetup() {
        let bundle = Bundle(for: Self.self)
        bundle.loadNibNamed(String(describing: Self.self), owner: self, options: nil)
        addSubview(contentView)
        contentView.constraintToSides(inside: self)
        input.sink(receiveValue: { [weak self] action in
            switch action {
            case .configure(let state):
                self?.configureView()
                self?.configureState(state)
            }
        }).store(in: &bag)
    }
    
    private func configureView() {
        trialMessageLabel.text = purchases.isUserEverHadSubscriptions ?
        "Start your full access. Manage anytime." : "After a 3-day free trial. Manage anytime."
        weeklyPlanPrice.text = purchases.getPriceForPurchase(model: .weekly) ?? PurchesService.previousWeeklyPrice
        montlyPriceLabel.text = purchases.getPriceForPurchase(model: .monthly) ?? PurchesService.previousMonthlyPrice
        let yearly = purchases.getPriceForPurchase(model: .annual) ?? PurchesService.previousYearlyPrice
        yearlyPriceFirstPartLabel.text = yearly
        yearlyPriceSecondPart.attributedText = purchases.getFormattedYearPriceForPurchase()
        blurViewStatic.isAnimated = false
        blurViewStatic.setup()
        firstButton.isSelected = true
        isSecondOptionSelected = false
        planSelectionContainer.addCornerRadius(30)
        weeklyContainer.addCornerRadius(30)
        hideOtherPlansButton.imageView?.contentMode = .center
        planSelectionContainer.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        planSelectionContainer.dropShadow(color: .black, opacity: 0.7, offSet: .zero, radius: 15, scale: true)
        weeklyContainer.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        weeklyContainer.dropShadow(color: .black, opacity: 0.7, offSet: .zero, radius: 15, scale: true)
        planSelectionContinueButton.dropShadow(color: .white, opacity: 0.0, offSet: CGSize(width: 0, height: 0), radius: 15, scale: true)
        
        firstButton.publisher().sink(receiveValue: { [weak self] _ in
            self?.firstButton.isSelected = true
            self?.secondButton.isSelected = false
            self?.isSecondOptionSelected = false
        }).store(in: &bag)
        
        secondButton.publisher().sink(receiveValue: { [weak self] _ in
            self?.secondButton.isSelected = true
            self?.firstButton.isSelected = false
            self?.isSecondOptionSelected = true
        }).store(in: &bag)
        
        planSelectionContinueButton.publisher().sink(receiveValue: { [weak self] _ in
            guard let self = self else { return }
            self.output.send(.onPurchase(isSecondOptionSelected: self.isSecondOptionSelected))
        }).store(in: &bag)
        
        closeButton.publisher().sink(receiveValue: { [weak self] _ in
            self?.output.send(.onClose)
            self?.weeklyContinueAnimationsCancelable?.cancel()
            self?.planSelectionContinueAnimationsCanelable?.cancel()
        }).store(in: &bag)
        
        otherPlansWeekly.publisher().sink(receiveValue: { [weak self] _ in
            self?.showPlanSelection()
        }).store(in: &bag)
        
        hideOtherPlansButton.publisher().sink(receiveValue: { [weak self] _ in
            self?.hideOtherPlansButtonContainer.alpha = 0.0
            UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.8, options: [], animations: {
                guard let translateY = self?.planSelectionContainer.transform.translatedBy(x: 0, y: -50) else { return }
                self?.planSelectionContainer.transform = translateY
            }, completion: nil)
            UIView.animate(withDuration: 0.6, delay: 0.2, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.8, options: [], animations: {
                let translateY = CGAffineTransform(translationX: 0, y: (self?.planSelectionContainer.bounds.height ?? 0))
                self?.planSelectionContainer.transform = translateY
                self?.pickYourPlanLabel.alpha = 1
                self?.pickYourPlanDescriptionStack.alpha = 1
            }, completion: { _ in
                self?.showWeeklyTrial()
                self?.animateDescriptions()
            })
        }).store(in: &bag)
        
        Publishers.Merge(weeklyHowItWorksButton.publisher(), plansHowItWorksButton.publisher())
            .sink(receiveValue: { [weak self] _ in
                self?.showHowItWorks()
        }).store(in: &bag)
        
        Publishers.Merge(restoreSubscriptionPlanSelection.publisher(), restoreSubscriptionsWeeklyButton.publisher())
            .sink(receiveValue: { [weak self] _ in
            self?.output.send(.restoreSubscription)
        }).store(in: &bag)

        weeklyPurchaseContinue.publisher().sink(receiveValue: { [weak self] _ in
            self?.output.send(.onWeeklyPurchase)
        }).store(in: &bag)
    }
    
    private func configureState(_ state: State) {
        switch state {
        case .weekly: showWeeklyTrial()
        case .planOptions: showPlanSelection()
        case .howItWorks: showHowItWorks()
        }
    }
    
    private func showWeeklyTrial() {
        closeButton.isHidden = false
        planSelectionContinueButton.layer.removeAllAnimations()
        planSelectionContinueAnimationsCanelable?.cancel()
        weeklyPurchaseContinue.layer.removeAllAnimations()
        weeklyPurchaseContinue.dropShadow(color: .white, opacity: 0.0, offSet: CGSize(width: 0, height: 0), radius: 15, scale: true)
        weeklyContinueAnimationsCancelable?.cancel()
        weeklyContinueAnimationsCancelable = weeklyPurchaseContinue.animateBounceAndShadow()
        weeklyContainer.isHidden = false
        planSelectionContainer.isHidden = true
        howItWorksContainer.isHidden = true
        pickYourPlanLabel.isHidden = false
        pickYourPlanDescriptionStack.isHidden = false
        animateDescriptions()
    }
    
    private func showPlanSelection() {
        weeklyPurchaseContinue.layer.removeAllAnimations()
        weeklyContinueAnimationsCancelable?.cancel()
        planSelectionContinueButton.layer.removeAllAnimations()
        planSelectionContinueButton.dropShadow(color: .white, opacity: 0.0, offSet: .zero, radius: 15, scale: true)
        planSelectionContinueAnimationsCanelable?.cancel()
        planSelectionContinueAnimationsCanelable = planSelectionContinueButton.animateBounceAndShadow()
        planSelectionContainer.isHidden = false
        closeButton.isHidden = true
        howItWorksContainer.isHidden = true
        pickYourPlanLabel.isHidden = false
        pickYourPlanDescriptionStack.isHidden = false
        let translateY = CGAffineTransform(translationX: 0, y: UIScreen.main.bounds.height)
        planSelectionContainer.transform = translateY
        pickYourPlanLabel.alpha = 0.2
        pickYourPlanDescriptionStack.alpha = 0.2
        UIView.animate(withDuration: 0.8, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.8, options: [], animations: {
            self.planSelectionContainer.transform = .identity
        }, completion: nil)
        
        UIView.animate(withDuration: 1, delay: 0.5, options: [.allowUserInteraction], animations: {
            self.hideOtherPlansButtonContainer.alpha = 1.0
        }, completion: nil)
        
        UIView.animateKeyframes(withDuration: 1, delay: 0.6, options: [.calculationModeCubic], animations: {
            UIView.addKeyframe(withRelativeStartTime: 0.0, relativeDuration: 0.0, animations: {
                self.likeIconImage.transform = CGAffineTransform.identity.scaledBy(x: 0.01, y: 0.01)
            })
            UIView.addKeyframe(withRelativeStartTime: 0.0, relativeDuration: 0.8, animations: {
                self.likeIconImage.transform = CGAffineTransform.identity.scaledBy(x: 1.5, y: 1.5)
            })
            UIView.addKeyframe(withRelativeStartTime: 0.8, relativeDuration: 0.2, animations: {
                self.likeIconImage.transform = CGAffineTransform.identity
            })
            UIView.addKeyframe(withRelativeStartTime: 0.2, relativeDuration: 0.6, animations: {
                self.likeIconImage.transform = CGAffineTransform.identity.rotated(by: CGFloat(Float.pi) / 4)
            })
            UIView.addKeyframe(withRelativeStartTime: 0.6, relativeDuration: 0.4, animations: {
                self.likeIconImage.transform = .identity
            })
        }, completion: nil)
    }
    
    private func showHowItWorks() {
        weeklyPurchaseContinue.layer.removeAllAnimations()
        weeklyContinueAnimationsCancelable?.cancel()
        planSelectionContinueButton.layer.removeAllAnimations()
        planSelectionContinueButton.dropShadow(color: .white, opacity: 0.0, offSet: .zero, radius: 15, scale: true)
        planSelectionContinueAnimationsCanelable?.cancel()
        planSelectionContinueAnimationsCanelable = weeklyPurchaseContinue.animateBounceAndShadow()
        weeklyPurchaseContinue.layer.removeAllAnimations()
        weeklyPurchaseContinue.dropShadow(color: .white, opacity: 0.0, offSet: CGSize(width: 0, height: 0), radius: 15, scale: true)
        weeklyContinueAnimationsCancelable?.cancel()
        weeklyContinueAnimationsCancelable = weeklyPurchaseContinue.animateBounceAndShadow()
        weeklyContainer.isHidden = false
        planSelectionContainer.isHidden = true
        howItWorksContainer.isHidden = false
        pickYourPlanDescriptionStack.isHidden = true
        pickYourPlanLabel.isHidden = true
        pickYourPlanLabel.alpha = 1
        pickYourPlanDescriptionStack.alpha = 1
        hideOtherPlansButtonContainer.alpha = 0.0
        closeButton.isHidden = false
    }
    
    private func animateDescriptions() {
        guard !isAdvantagesLabelsAnimationsWasPlayed else { return }
        var animDelay: TimeInterval = 0
        pickYourPlanDescriptionStack.arrangedSubviews.forEach { subview in
            subview.layer.removeAllAnimations()
            subview.transform = CGAffineTransform.identity.translatedBy(x: UIScreen.main.bounds.width, y: 0)
            UIView.animate(withDuration: 1.0, delay: animDelay, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.6, options: [.curveEaseIn], animations: {
                subview.transform = .identity
            }, completion: nil)
            animDelay += 0.3
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5, execute: { [weak self] in
            self?.isAdvantagesLabelsAnimationsWasPlayed = true
        })
    }
}
