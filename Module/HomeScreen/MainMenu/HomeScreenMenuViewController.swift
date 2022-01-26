//
//  
//  HomeScreenMenuViewController.swift
//  AirPrint
//
//  Created by Danyl Timofeyev on 29.11.2021.
//
//

import UIKit
import Combine

// MARK: - HomeScreenMenuViewController

final class HomeScreenMenuViewController: UIViewController,
                                            ActivityIndicatorPresentable,
                                            SubscriptionsMultiPopupProvidable,
                                            AlertPresentable,
                                            AnalyticServiceProvider {
    enum State {
        case showSubscriptionPopup(withContent: (UIImage, UIImage, String, String))
        case hideSubscriptionPopup
        case loadingState(_ isLoading: Bool)
        case displayAlert(text: String, title: String?, action: VoidClosure?, buttonTitle: String?)
        case displayHowTrialWorks
    }
    
    @IBOutlet weak var menuContainer: UIView!
    @IBOutlet weak var buttonsContainerView: UIView!
    @IBOutlet weak var cancelButton: TapAnimatedButton!
    @IBOutlet weak var scanDocumentButton: TapAnimatedButton!
    @IBOutlet weak var printPhotoButton: TapAnimatedButton!
    @IBOutlet weak var printDocumentButton: TapAnimatedButton!
    @IBOutlet weak var printWebPage: TapAnimatedButton!
    @IBOutlet weak var printFromClipboard: TapAnimatedButton!
    @IBOutlet weak var subscriptionPriceLabel: UILabel!
    @IBOutlet weak var subscriptionPopup: UIView!
    @IBOutlet weak var subscriptionButtonsContainer: UIView!
    @IBOutlet weak var subscriptionPopupImageView: UIImageView!
    @IBOutlet weak var subscriptionCloseButton: UIButton!
    @IBOutlet weak var subscriptionTitleFirstLine: UILabel!
    @IBOutlet weak var subscriptionTitleSecondLine: UILabel!
    @IBOutlet weak var subscriptionContinueButton: UIButton!
    @IBOutlet weak var firstBlurredShadowView: BlurredShadowView1!
    @IBOutlet weak var restoreSubscriptionButton: UIButton!
    @IBOutlet weak var plansButton: UIButton!
    @IBOutlet weak var howTrialWorksButton: UIButton!

    private let viewModel: HomeScreenMenuViewModel
    private var bag = Set<AnyCancellable>()
    private var purchaseConntinueAnimationsCancelable: AnyCancellable?
    init(viewModel: HomeScreenMenuViewModel) {
        self.viewModel = viewModel
        super.init(nibName: String(describing: HomeScreenMenuViewController.self), bundle: nil)
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    deinit {
        Logger.log(String(describing: self), type: .deinited)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureView()
        applyStyling()
    }
    override func viewDidAppear(_ animated: Bool) {
        firstBlurredShadowView.animationDuration = 2000
        firstBlurredShadowView.setup()
        analytics.eventVisitScreen(screen: "home_menu_screen")
    }
}

// MARK: - Internal

private extension HomeScreenMenuViewController {
    @objc func handleTapCloseMainMenu(_ sender: UITapGestureRecognizer? = nil) {
        menuContainer.isHidden = true
        viewModel.input.send(.closeAction)
    }
    
    func configureView() {
        let isPaidUser = viewModel.isPaidUser
        printPhotoButton.isSelected = isPaidUser
        printDocumentButton.isSelected = isPaidUser
        printWebPage.isSelected = isPaidUser
        printFromClipboard.isSelected = isPaidUser
        
//        let tap = UITapGestureRecognizer(target: self, action: #selector(self.handleTapCloseMainMenu(_:)))
//        let tapView = UIView()
//        view.addSubview(tapView)
//        tapView.translatesAutoresizingMaskIntoConstraints = false
//        tapView.bottomAnchor.constraint(equalTo: buttonsContainerView.topAnchor, constant: 0).isActive = true
//        tapView.topAnchor.constraint(equalTo: view.topAnchor, constant: 0).isActive = true
//        tapView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 0).isActive = true
//        tapView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 0).isActive = true
//        tapView.addGestureRecognizer(tap)
//
        subscriptionPriceLabel.text = viewModel.purchases.getPriceForPurchase(model: .weekly) ?? PurchesService.previousWeeklyPrice
        viewModel.output.sink(receiveValue: { [weak self] state in
            guard let self = self else { return }
            switch state {
            case .showSubscriptionPopup(let content):
                self.showSubscriptionsPopup(with: content)
            case .loadingState(let isLoading):
                isLoading ?
                self.startActivityAnimation() :
                self.stopActivityAnimation()
            case .hideSubscriptionPopup:
                self.closeSubscriptionsPopup()
            case .displayHowTrialWorks:
                self.viewModel.input.send(.howTrialWorks(container: self.view))
            case .displayAlert(let text, let title, let action, let buttonTitle):
                self.displayAlert(fromParentView: self.view, with: text, title: title, action: action, buttonTitle: buttonTitle)
            }
        }).store(in: &bag)
        scanDocumentButton.publisher().sink(receiveValue: { [weak self] _ in
            self?.analytics.eventMenuOptionPressed(option: "scan")
            self?.viewModel.input.send(.scanAction)
        }).store(in: &bag)
        printPhotoButton.publisher().sink(receiveValue: { [weak self] _ in
            self?.analytics.eventMenuOptionPressed(option: "photo")
            self?.viewModel.input.send(.printPhoto)
        }).store(in: &bag)
        printDocumentButton.publisher().sink(receiveValue: { [weak self] _ in
            self?.analytics.eventMenuOptionPressed(option: "document")
            self?.viewModel.input.send(.printDocument)
        }).store(in: &bag)
        cancelButton.publisher().sink(receiveValue: { [weak self] _ in
            guard let self = self else { return }
            self.menuContainer.isHidden = true
            self.viewModel.input.send(.closeAction)
        }).store(in: &bag)
        printWebPage.publisher().sink(receiveValue: { [weak self] _ in
            self?.analytics.eventMenuOptionPressed(option: "webpage")
            self?.viewModel.input.send(.printWebPage)
        }).store(in: &bag)
        printFromClipboard.publisher().sink(receiveValue: { [weak self] _ in
            self?.analytics.eventMenuOptionPressed(option: "clipboard")
            self?.viewModel.input.send(.printFromClipboard)
        }).store(in: &bag)
        subscriptionCloseButton.publisher().sink(receiveValue: { [weak self] _ in
            self?.closeSubscriptionsPopup()
        }).store(in: &bag)
        subscriptionContinueButton.publisher().sink(receiveValue: { [weak self] _ in
            self?.viewModel.input.send(.purchase(.weekly))
        }).store(in: &bag)
        restoreSubscriptionButton.publisher().sink(receiveValue: { [weak self] _ in
            self?.viewModel.input.send(.restoreSubscription)
        }).store(in: &bag)
        plansButton.publisher().sink(receiveValue: { [weak self] _ in
            guard let self = self else { return }
            self.viewModel.input.send(.otherPlans(container: self.view))
        }).store(in: &bag)
        howTrialWorksButton.publisher().sink(receiveValue: { [weak self] _ in
            guard let self = self else { return }
            self.viewModel.input.send(.howTrialWorks(container: self.view))
        }).store(in: &bag)
    }
    
    func showSubscriptionsPopup(with content: (UIImage, UIImage, String, String)) { 
        menuContainer.isHidden = true
        subscriptionPopupImageView.image = content.0
        subscriptionContinueButton.setBackgroundImage(content.1, for: .normal)
        subscriptionTitleFirstLine.text = content.2
        subscriptionTitleSecondLine.text = content.3
        subscriptionContinueButton.dropShadow(color: .white, opacity: 0.0, offSet: CGSize(width: 0, height: 0), radius: 15, scale: true)
        purchaseConntinueAnimationsCancelable = subscriptionContinueButton.animateBounceAndShadow()
        subscriptionCloseButton.animateFadeIn(1, delay: 4, finalAlpha: 0.6)
        UIView.transition(with: self.view, duration: 0.4, options: .transitionCrossDissolve, animations: { [weak self] in
            self?.subscriptionPopup.isHidden = false
        })
    }
    
    func closeSubscriptionsPopup() {
        subscriptionPopup.isHidden = true
        purchaseConntinueAnimationsCancelable?.cancel()
        subscriptionContinueButton.layer.removeAllAnimations()
        UIView.transition(with: self.view, duration: 0.4, options: .transitionCrossDissolve, animations: { [weak self] in
            self?.subscriptionPopup.isHidden = true
        }, completion: { [weak self] _ in
            self?.viewModel.input.send(.closeAction)
        })
    }
    
    func applyStyling() {
        buttonsContainerView.addCornerRadius(StylingConstants.cornerRadiusDefault)
        buttonsContainerView.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMinXMinYCorner]
        scanDocumentButton.addCornerRadius(StylingConstants.cornerRadiusDefault)
        printDocumentButton.addCornerRadius(StylingConstants.cornerRadiusDefault)
        printPhotoButton.addCornerRadius(StylingConstants.cornerRadiusDefault)
        cancelButton.addCornerRadius(StylingConstants.cornerRadiusDefault)
        printWebPage.addCornerRadius(StylingConstants.cornerRadiusDefault)
        buttonsContainerView.dropShadow(color: .black, opacity: 0.3, offSet: .zero, radius: 15, scale: true)
        subscriptionButtonsContainer.addCornerRadius(30.0)
        subscriptionButtonsContainer.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMinXMinYCorner]
        subscriptionButtonsContainer.dropShadow(color: .black, opacity: 0.3, offSet: .zero, radius: 15, scale: true)
        let emitterForStepOne = ParticleEmitterView()
        emitterForStepOne.isUserInteractionEnabled = false
        emitterForStepOne.translatesAutoresizingMaskIntoConstraints = false
        //emitterForStepOne.isHidden = true
        subscriptionPopup.insertSubview(emitterForStepOne, at: 0)
        emitterForStepOne.widthAnchor.constraint(equalTo: subscriptionPopup.widthAnchor).isActive = true
        emitterForStepOne.heightAnchor.constraint(equalTo: subscriptionPopup.heightAnchor).isActive = true
        emitterForStepOne.centerYAnchor.constraint(equalTo: subscriptionPopup.centerYAnchor).isActive = true
        emitterForStepOne.centerXAnchor.constraint(equalTo: subscriptionPopup.centerXAnchor).isActive = true
    }
}
