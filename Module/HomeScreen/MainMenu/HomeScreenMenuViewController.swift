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

final class HomeScreenMenuViewController: UIViewController, ActivityIndicatorPresentable {
    enum State {
        case showSubscriptionPopup(withContent: (UIImage, UIImage, String, String))
        case hideSubscriptionPopup
        case loadingState(_ isLoading: Bool)
    }
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
    @IBOutlet weak var secondBlurredShadowView: BlurredShadowView2!
    @IBOutlet weak var firstBlurredShadowView: BlurredShadowView1!
    @IBOutlet weak var restoreSubscriptionButton: UIButton!
    
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
        buttonsContainerView.isHidden = true
    }
    override func viewWillAppear(_ animated: Bool) {
        let runLoopMode = CFRunLoopMode.commonModes.rawValue
        CFRunLoopPerformBlock(CFRunLoopGetMain(), runLoopMode) {
            UIView.transition(with: self.view, duration: 0.5, options: .transitionFlipFromTop, animations: {
                self.buttonsContainerView.isHidden = false
            })
        }
        CFRunLoopWakeUp(CFRunLoopGetMain())
    }
    override func viewDidAppear(_ animated: Bool) {
        firstBlurredShadowView.animationDuration = 2000
        secondBlurredShadowView.animationDuration = 2000
        secondBlurredShadowView.setup()
        firstBlurredShadowView.setup()
    }
}

// MARK: - Internal

private extension HomeScreenMenuViewController {
    func configureView() {
        subscriptionPriceLabel.text = viewModel.purchases.getPriceForPurchase(model: .weekly)
        
        viewModel.output.sink(receiveValue: { [weak self] state in
            switch state {
            case .showSubscriptionPopup(let content):
                self?.showSubscriptionsPopup(with: content)
            case .loadingState(let isLoading):
                isLoading ?
                self?.startActivityAnimation() :
                self?.stopActivityAnimation()
            case .hideSubscriptionPopup:
                self?.closeSubscriptionsPopup()
            }
        }).store(in: &bag)
        scanDocumentButton.publisher().sink(receiveValue: { [weak self] _ in
            self?.viewModel.input.send(.scanAction)
        }).store(in: &bag)
        printPhotoButton.publisher().sink(receiveValue: { [weak self] _ in
            self?.viewModel.input.send(.printPhoto)
        }).store(in: &bag)
        printDocumentButton.publisher().sink(receiveValue: { [weak self] _ in
            self?.viewModel.input.send(.printDocument)
        }).store(in: &bag)
        cancelButton.publisher().sink(receiveValue: { [weak self] _ in
            guard let self = self else { return }
            UIView.transition(with: self.view, duration: 0.5, options: .transitionFlipFromBottom, animations: {
                self.buttonsContainerView.isHidden = true
            }, completion: { _ in
                self.viewModel.input.send(.closeAction)
            })
        }).store(in: &bag)
        printWebPage.publisher().sink(receiveValue: { [weak self] _ in
            self?.viewModel.input.send(.printWebPage)
        }).store(in: &bag)
        printFromClipboard.publisher().sink(receiveValue: { [weak self] _ in
            self?.viewModel.input.send(.printFromClipboard)
        }).store(in: &bag)
        subscriptionCloseButton.publisher().sink(receiveValue: { [weak self] _ in
            self?.closeSubscriptionsPopup()
        }).store(in: &bag)
        subscriptionContinueButton.publisher().sink(receiveValue: { [weak self] _ in
            self?.viewModel.input.send(.subscriptionBuy)
        }).store(in: &bag)
        restoreSubscriptionButton.publisher().sink(receiveValue: { [weak self] _ in
            self?.viewModel.input.send(.restoreSubscription)
        }).store(in: &bag)
    }
    
    func showSubscriptionsPopup(with content: (UIImage, UIImage, String, String)) {
        buttonsContainerView.isHidden = true
        subscriptionPopupImageView.image = content.0
        subscriptionContinueButton.setBackgroundImage(content.1, for: .normal)
        subscriptionTitleFirstLine.text = content.2
        subscriptionTitleSecondLine.text = content.3
        subscriptionContinueButton.dropShadow(color: .white, opacity: 0.0, offSet: CGSize(width: 0, height: 0), radius: 15, scale: true)
        purchaseConntinueAnimationsCancelable = subscriptionContinueButton.animateBounceAndShadow()
        subscriptionCloseButton.animateFadeIn(1, delay: 4, finalAlpha: 0.6)
        
        UIView.transition(with: self.view, duration: 0.7, options: .transitionCurlDown, animations: { [weak self] in
            self?.subscriptionPopup.isHidden = false
        })
    }
    
    func closeSubscriptionsPopup() {
        subscriptionPopup.isHidden = true
        purchaseConntinueAnimationsCancelable?.cancel()
        subscriptionContinueButton.layer.removeAllAnimations()
        UIView.transition(with: self.view, duration: 0.7, options: .transitionCurlUp, animations: { [weak self] in
            self?.subscriptionPopup.isHidden = true
        }, completion: { [weak self] _ in
            self?.viewModel.input.send(.closeAction)
        })
    }
    
    func applyStyling() {
        buttonsContainerView.addCornerRadius(StylingConstants.cornerRadiusDefault)
        buttonsContainerView.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMinXMinYCorner]
        scanDocumentButton.addCornerRadius(StylingConstants.cornerRadiusDefault)
        scanDocumentButton.addBorder(1.0, .black)
        printDocumentButton.addCornerRadius(StylingConstants.cornerRadiusDefault)
        printDocumentButton.addBorder(1.0, .black)
        printPhotoButton.addCornerRadius(StylingConstants.cornerRadiusDefault)
        printPhotoButton.addBorder(1.0, .black)
        cancelButton.addCornerRadius(StylingConstants.cornerRadiusDefault)
        printWebPage.addCornerRadius(StylingConstants.cornerRadiusDefault)
        printWebPage.addBorder(1.0, .black)
        buttonsContainerView.dropShadow(color: .black, opacity: 0.6, offSet: .zero, radius: 30, scale: true)
        subscriptionButtonsContainer.addCornerRadius(30.0)
        subscriptionButtonsContainer.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMinXMinYCorner]
        subscriptionButtonsContainer.dropShadow(color: .black, opacity: 0.6, offSet: .zero, radius: 30, scale: true)
        let emitterForStepOne = ParticleEmitterView()
        emitterForStepOne.isUserInteractionEnabled = false
        emitterForStepOne.translatesAutoresizingMaskIntoConstraints = false
        
        subscriptionPopup.insertSubview(emitterForStepOne, at: 0)
        emitterForStepOne.widthAnchor.constraint(equalTo: subscriptionPopup.widthAnchor).isActive = true
        emitterForStepOne.heightAnchor.constraint(equalTo: subscriptionPopup.heightAnchor).isActive = true
        emitterForStepOne.centerYAnchor.constraint(equalTo: subscriptionPopup.centerYAnchor).isActive = true
        emitterForStepOne.centerXAnchor.constraint(equalTo: subscriptionPopup.centerXAnchor).isActive = true
    }
}
