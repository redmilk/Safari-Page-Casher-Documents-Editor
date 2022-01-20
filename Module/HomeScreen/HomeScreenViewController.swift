//
//  
//  HomeScreenViewController.swift
//  AirPrint
//
//  Created by Danyl Timofeyev on 26.11.2021.
//
//

import UIKit
import Combine

fileprivate let multiSubscriptionPopupViewTag: Int = 123

final class HomeScreenViewController: UIViewController,
                                      ActivityIndicatorPresentable,
                                      AlertPresentable,
                                      SubscriptionsMultiPopupProvidable {
    
    enum State {
        case allCurrentData([PrintableDataBox])
        case addedItems([PrintableDataBox])
        case deletedItems([PrintableDataBox])
        case selectedItems([PrintableDataBox])
        case subscriptionStatus(
            hasActiveSubscriptions: Bool,
            shouldDisplayMultiSubscrPopup: Bool,
            shouldShowHowItWorks: Bool)
        case selectionCount(Int)
        case selectionMode
        case exitSelectionMode
        case loadingState(Bool)
        case empty
        case timerTick(timerText: String)
        case displayAlert(text: String, title: String?, action: VoidClosure?, buttonTitle: String?)
        case displayHowTrialWorks
        case collapseAllSubscriptionPopupsWhichArePresented
        case gotUpdatedPricesForGift(yearly: String, yearlyStrike: NSAttributedString)
    }
    
    @IBOutlet weak var centerImageView: UIImageView!
    /// Gift menu
    @IBOutlet private weak var mainContainer: UIView!
    @IBOutlet private weak var giftOrHowItWorksContainer: UIView!
    @IBOutlet private weak var subscriptionMenuContainer: UIView!
    @IBOutlet private weak var subscriptionContinueButton: TapAnimatedButton!
    @IBOutlet private weak var giftOrHowItWorksOpenButton: TapAnimatedButton!
    @IBOutlet private weak var subscriptionDiscountLabel: UILabel!
    @IBOutlet private weak var subscriptionCloseButton: TapAnimatedButton!
    @IBOutlet private weak var giftContainerHeightConstraint: NSLayoutConstraint!
    @IBOutlet private weak var giftContainerTopSpacing: NSLayoutConstraint!
    @IBOutlet private weak var giftTimerContainer: UIView!
    @IBOutlet private weak var giftTimerLabel: UILabel!
    @IBOutlet private weak var giftIconImageView: UIImageView!
    @IBOutlet private weak var giftTitleLabel: UILabel!
    @IBOutlet private weak var restorePurchaseButton: TapAnimatedButton!
    @IBOutlet private weak var giftYearlyPriceLabel: UILabel!
    /// Filled state controls
    @IBOutlet private weak var collectionView: UICollectionView!
    @IBOutlet private weak var layoutChangeButton: TapAnimatedButton!
    @IBOutlet private weak var plusButtonSmall: TapAnimatedButton!
    @IBOutlet private weak var checkmarkButton: TapAnimatedButton!
    @IBOutlet private weak var deleteButton: TapAnimatedButton!
    /// Empty state controls
    @IBOutlet private weak var emptyStateContainer: UIView!
    @IBOutlet private weak var plusButtonDescriptionContainer: UIStackView!
    @IBOutlet private weak var plusButton: TapAnimatedButton!
    @IBOutlet private weak var giftContentView: UIView!
    /// Common state controls
    @IBOutlet private weak var printButton: TapAnimatedButton!
    @IBOutlet private weak var navigationBarExtenderView: UIView!
    @IBOutlet private weak var settingsButton: TapAnimatedButton!
    @IBOutlet private weak var bottomBarContainer: UIView!
    /// Selection mode
    @IBOutlet private weak var deleteButtonsContainer: UIView!
    @IBOutlet private weak var deleteAllButton: TapAnimatedButton!
    @IBOutlet private weak var deleteSelectedButton: TapAnimatedButton!
    @IBOutlet private weak var closeSelectionModeButton: TapAnimatedButton!
    @IBOutlet private weak var selectionModeInfoLabel: UILabel!
    @IBOutlet private weak var selectionModeTopContainer: UIView!
    /// Action clarify dialog
    @IBOutlet private weak var dialogContainer: UIView!
    @IBOutlet private weak var dialogButtonsContainer: UIView!
    @IBOutlet private weak var dialogDeleteButton: TapAnimatedButton!
    @IBOutlet private weak var dialogCancelButton: TapAnimatedButton!

    @IBOutlet weak var howTrialWorksButton: TapAnimatedButton!
    @IBOutlet weak var otherPlansButton: TapAnimatedButton!
    
    private lazy var collectionManager = HomeCollectionManager(collectionView: collectionView)
    private let viewModel: HomeScreenViewModel
    private var bag = Set<AnyCancellable>()
    private var purchaseConntinueAnimationsCancelable: AnyCancellable?
    private var giftOrHowItWorksButtonAnimation: AnyCancellable?
    
    private var dashedLineLayer: CAShapeLayer?
    private var gradient: CAGradientLayer?
    private var hasItems: Bool = false
    private var selectionCount: Int = 0
    private var shouldShowHowItWorks: Bool = false

    init(viewModel: HomeScreenViewModel) {
        self.viewModel = viewModel
        super.init(nibName: String(describing: HomeScreenViewController.self), bundle: nil)
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    deinit {
        Logger.log(String(describing: self), type: .deinited)
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        viewModel.input.send(.memoryWarning)
        displayAlert(
            fromParentView: self.view,
            with: "Your device's memory is too low. Unfortunately, the application will partially purge your previously added files that have not yet been edited", title: "Warning")
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        handleStates()
        applyStyling()
        collectionManager.input.send(.configure)
        viewModel.configureViewModel()
        configureView()
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        viewModel.input.send(.viewDidAppear)
        addDashedLineAnimation()
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
        viewModel.input.send(.viewDisapear)
    }
}

// MARK: - Internal

private extension HomeScreenViewController {
    
    /// Handle ViewModel's states
    func handleStates() {
        viewModel.output.sink(receiveValue: { [weak self] state in
            switch state {
            case .allCurrentData(let allData):
                self?.collectionManager.input.send(.replaceAllWithItems(allData))
                self?.changeViewStateBasedOnItemsCount(hasItems: true)
            case .addedItems(let addNewItems):
                self?.collectionManager.input.send(.incrementItems(addNewItems))
                self?.changeViewStateBasedOnItemsCount(hasItems: true)
            case .deletedItems(let deletedItems):
                self?.collectionManager.input.send(.removeItems(deletedItems))
            case .selectedItems(let selectedItems):
                self?.selectionModeInfoLabel.text = "Selected items: \(selectedItems.count)"
                self?.collectionManager.input.send(.updateItems(selectedItems))
            case .empty:
                self?.changeViewStateBasedOnItemsCount(hasItems: false)
                self?.deleteButton.isHidden = true
            case .selectionMode:
                self?.collectionManager.input.send(.toggleSelectionMode)
            case .exitSelectionMode:
                self?.collectionManager.input.send(.toggleSelectionMode)
            case .selectionCount(let selectionCount):
                self?.selectionCount = selectionCount
                self?.deleteSelectedButton.isEnabled = selectionCount > 0
                self?.selectionModeInfoLabel.text = "Selected items: \(selectionCount)"
            case .timerTick(let timerText):
                self?.giftTimerLabel.text = timerText
            case .loadingState(let isLoading):
                isLoading ? self?.startActivityAnimation() : self?.stopActivityAnimation()
            case .subscriptionStatus(
                let hasActiveSubscriptions,
                let shouldDisplayMultiSubscrPopup,
                let shouldShowHowItWorks):
                guard let self = self else { return }
                self.updateGiftOrHowItWorksPresentation(
                    hasActiveSubscriptions: hasActiveSubscriptions, shouldShowHowItWorks: shouldShowHowItWorks)
                if shouldDisplayMultiSubscrPopup {
                    self.displayMultisubscriptionsPopup(inContainer: self.view, optionToShowFirst: .weekly)
                    PurchesService.shouldDisplaySubscriptionsForCurrentUser = false
                }
            case .displayAlert(let text, let title, let action, let buttonTitle):
                guard let parentViewForAlert = self?.view else { return }
                self?.displayAlert(fromParentView: parentViewForAlert, with: text, title: title, action: action, buttonTitle: buttonTitle)
            case .gotUpdatedPricesForGift(let yearly, let yearlyStrike):
                self?.giftYearlyPriceLabel.text = yearly
                self?.subscriptionDiscountLabel.attributedText = yearlyStrike
            case .displayHowTrialWorks:
                break
            case .collapseAllSubscriptionPopupsWhichArePresented:
                self?.removeMultisubscriptionsPopupIfDisplayed()
                self?.collapseGiftSubscriptionPopup()
            }
        }).store(in: &bag)
    }
    
    func configureView() {
        Publishers.Merge(plusButton.publisher(), plusButtonSmall.publisher())
            .sink(receiveValue: { [weak self] _ in
                self?.viewModel.input.send(.openMenu)
            }).store(in: &bag)
        
        printButton.publisher().sink(receiveValue: { [weak self] _ in
            self?.startActivityAnimation()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: { [weak self] in
                self?.viewModel.input.send(.didTapPrint)
            })
        }).store(in: &bag)
        
        settingsButton.publisher().print("SETTINGS").sink(receiveValue: { [weak self] _ in
            self?.viewModel.input.send(.didTapSettings)
        }).store(in: &bag)
        
        deleteSelectedButton.publisher().sink(receiveValue: { [weak self] _ in
            self?.setHiddenClarifyDeleteDialog(false)
        }).store(in: &bag)
        
        deleteButton.publisher().sink(receiveValue: { [weak self] _ in
            guard let dataBox = self?.collectionManager.currentCenterCellInPagingLayout else { return }
            dataBox.isSelected = true
            self?.setHiddenClarifyDeleteDialog(false)
        }).store(in: &bag)
        
        deleteAllButton.publisher().sink(receiveValue: { [weak self] _ in
            self?.viewModel.input.send(.deleteAll)
            self?.setHiddenClarifyDeleteDialog(false)
        }).store(in: &bag)
        
        dialogDeleteButton.publisher().sink(receiveValue: { [weak self] _ in
            guard let self = self else { return }
            self.setHiddenClarifyDeleteDialog(true)
            self.viewModel.input.send(.itemsDeleteConfirmed)
            self.changeViewStateBasedOnSelectionMode(isInSelectionMode: false)
            self.collectionManager.input.send(.disableSelectionMode)
        }).store(in: &bag)
        
        dialogCancelButton.publisher().sink(receiveValue: { [weak self] _ in
            self?.viewModel.input.send(.itemsDeleteRejected)
            self?.setHiddenClarifyDeleteDialog(true)
            self?.collectionManager.input.send(.reloadCollection)
        }).store(in: &bag)
        
        layoutChangeButton.publisher().sink(receiveValue: { [weak self] _ in
            self?.collectionManager.input.send(.toggleLayout)
        }).store(in: &bag)
        
        giftOrHowItWorksOpenButton.publisher()
            .sink(receiveValue: { [weak self] _ in
                guard let self = self else { return }
                if self.shouldShowHowItWorks {
                    return self.displayMultisubscriptionsPopup(inContainer: self.view, optionToShowFirst: .howItWorks)
                }
                UIView.transition(with: self.view, duration: 0.5, options: .transitionCrossDissolve, animations: {
                    self.giftOrHowItWorksContainer.isHidden = false
                })
                self.subscriptionContinueButton.dropShadow(color: .white, opacity: 0.0, offSet: CGSize(width: 0, height: 0), radius: 15, scale: true)
                self.purchaseConntinueAnimationsCancelable = self.subscriptionContinueButton.animateBounceAndShadow()
                self.subscriptionCloseButton.animateFadeIn(1, delay: 4, finalAlpha: 0.6)
                self.addParticles()
            }).store(in: &bag)
        
        subscriptionContinueButton.publisher().sink(receiveValue: { [weak self] _ in
            self?.viewModel.input.send(.purchase(.annual))
        }).store(in: &bag)
        restorePurchaseButton.publisher().sink(receiveValue: { [weak self] _ in
            self?.viewModel.input.send(.restoreSubscription)
        }).store(in: &bag)
        otherPlansButton.publisher().sink(receiveValue: { [weak self] _ in
            guard let self = self else { return }
            self.displayMultisubscriptionsPopup(inContainer: self.giftOrHowItWorksContainer, optionToShowFirst: .planOptions)
        }).store(in: &bag)
        howTrialWorksButton.publisher().sink(receiveValue: { [weak self] _ in
            guard let self = self else { return }
            self.displayMultisubscriptionsPopup(inContainer: self.giftOrHowItWorksContainer, optionToShowFirst: .howItWorks)
        }).store(in: &bag)
        subscriptionCloseButton.publisher()
            .sink(receiveValue: { [weak self] _ in
                guard let self = self else { return }
                UIView.transition(with: self.view, duration: 0.5, options: .transitionCrossDissolve, animations: {
                    self.giftOrHowItWorksContainer.isHidden = true
                })
                self.subscriptionContinueButton.layer.removeAllAnimations()
                self.giftOrHowItWorksContainer.viewWithTag(1)!.removeFromSuperview()
                self.purchaseConntinueAnimationsCancelable?.cancel()
            }).store(in: &bag)
        checkmarkButton.publisher().sink(receiveValue: { [weak self] _ in
            self?.collectionManager.input.send(.toggleSelectionMode)
        }).store(in: &bag)
        closeSelectionModeButton.publisher().sink(receiveValue: { [weak self] _ in
            self?.setHiddenClarifyDeleteDialog(true)
            self?.collectionManager.input.send(.toggleSelectionMode)
            self?.viewModel.input.send(.itemsDeleteRejected)
            self?.changeViewStateBasedOnSelectionMode(isInSelectionMode: false)
        }).store(in: &bag)
        
        collectionManager.output.sink(receiveValue: { [weak self] action in 
            switch action {
            case .didPressCell(let dataBox):
                self?.viewModel.input.send(.getSelectionCount)
                self?.viewModel.input.send(.didPressCell(dataBox: dataBox))
            case .layoutMode(let isGrid):
                guard let self = self else { return }
                self.deleteButton.isHidden = isGrid
                self.layoutChangeButton.isSelected = isGrid
            case .selectionMode(let isOn):
                self?.changeViewStateBasedOnSelectionMode(isInSelectionMode: isOn)
            case .didSelectCheckmark:
                self?.viewModel.input.send(.getSelectionCount)
            }
        }).store(in: &bag)
        
        NotificationCenter.default.publisher(for: .pdfImportProcessDidStart, object: nil)
            .sink(receiveValue: { [weak self] _ in
                self?.startActivityAnimation()
            }).store(in: &bag)
        NotificationCenter.default.publisher(for: .pdfImportProcessDidStop, object: nil)
            .sink(receiveValue: { [weak self] _ in
                self?.stopActivityAnimation()
            }).store(in: &bag)
        
        showEmptyState()
        setHiddenClarifyDeleteDialog(true)
        changeViewStateBasedOnSelectionMode(isInSelectionMode: false)
        deleteButton.isHidden = true
        layoutChangeButton.isSelected = true
        giftOrHowItWorksContainer.isHidden.toggle()
        deleteSelectedButton.isEnabled = false
    }
    
    private func removeMultisubscriptionsPopupIfDisplayed() {
        guard giftOrHowItWorksContainer != nil else { return }
        giftOrHowItWorksContainer.subviews.forEach {
            if $0.tag == multiSubscriptionPopupViewTag {
                $0.removeFromSuperview()
                return
            }
        }
    }
    
    /// universal subscription popup
    private func displayMultisubscriptionsPopup(
        inContainer container: UIView,
        optionToShowFirst: SubscriptionPlanPopup.State
    ) {
        let (publisher, popUp) = displayMultiSubscriptions(optionToShowFirst, fromParentView: container)
        popUp.tag = 123
        publisher.sink(receiveValue: { [weak self] response in
            switch response {
            case .restoreSubscription:
                self?.viewModel.input.send(.restoreSubscription)
            case .onPurchase(let isSecondOptionSelected):
                self?.viewModel.input.send(.purchase(isSecondOptionSelected ? .annual : .monthly))
            case .onWeeklyPurchase:
                self?.viewModel.input.send(.purchase(.weekly))
            case .onClose:
                popUp.removeFromSuperview()
            }
        }).store(in: &bag)
    }
    
    private func changeViewStateBasedOnItemsCount(hasItems: Bool) {
        guard hasItems != self.hasItems else { return }
        self.hasItems.toggle()
        self.hasItems ? showFilledState() : showEmptyState()
    }
    
    private func showFilledState() {
        UIView.transition(with: self.mainContainer, duration: viewModel.userSession.itemsTotal > 1 ? 0.5 : 0, options: [.transitionFlipFromTop], animations: {
            self.emptyStateContainer.isHidden = true
            self.collectionView.isHidden = !true
        })
        plusButtonSmall.isEnabled = true
        checkmarkButton.isEnabled = true
        layoutChangeButton.isHidden = !true
        printButton.isEnabled = true
        giftContentView.isHidden = true
    }
    
    private func showEmptyState() {
        UIView.transition(with: self.mainContainer, duration: 0.5, options: [.transitionFlipFromBottom], animations: { [weak self] in
            guard let self = self, self.emptyStateContainer != nil, self.collectionView != nil else { return }
            self.emptyStateContainer.isHidden = false
            self.collectionView.isHidden = !false
        })
        plusButtonSmall.isEnabled = false
        checkmarkButton.isEnabled = false
        layoutChangeButton.isHidden = !false
        printButton.isEnabled = false
        giftContentView.isHidden = false
    }
    
    private func changeViewStateBasedOnSelectionMode(isInSelectionMode: Bool) {
        deleteButtonsContainer.isHidden = !isInSelectionMode
        plusButtonSmall.isHidden = isInSelectionMode
        printButton.isHidden = isInSelectionMode
        checkmarkButton.isHidden = isInSelectionMode
        selectionModeTopContainer.isHidden = !isInSelectionMode
    }
    
    private func setHiddenClarifyDeleteDialog(_ isHidden: Bool) {
        dialogContainer.isHidden = isHidden
    }
    
    private func collapseGiftSubscriptionPopup() {
        giftOrHowItWorksContainer.isHidden = true
        giftOrHowItWorksContainer.layer.removeAllAnimations()
        view.viewWithTag(multiSubscriptionPopupViewTag)?.removeFromSuperview()
    }
    enum SubscrContent {
        case none
        case gift
        case howItWorks
    }
    private func updateGiftOrHowItWorksPresentation(hasActiveSubscriptions: Bool, shouldShowHowItWorks: Bool) {
        var willBeShown: SubscrContent = .none
        var randomFlag: Bool?
        
        if !hasActiveSubscriptions && shouldShowHowItWorks {
            randomFlag = PurchesService.currentRandomFlag
            if let shouldChooseRandom = randomFlag {
                willBeShown = shouldChooseRandom ? .gift : .howItWorks
            }
        } else if shouldShowHowItWorks {
            willBeShown = .howItWorks
            /// has active subscription, nothing to show
        } else if hasActiveSubscriptions {
            giftOrHowItWorksButtonAnimation?.cancel()
            giftOrHowItWorksOpenButton.layer.removeAllAnimations()
            willBeShown = .none
            /// no active subscription and should show how it works
            /// only show gift
        } else {
            willBeShown = .gift
        }
        
        var isHiden: Bool!
        var howItWorks: Bool!
        switch willBeShown {
        case .none:
            isHiden = true
        case .howItWorks:
            isHiden = false
            howItWorks = true
        case .gift:
            howItWorks = false
            isHiden = false
        }
        giftContainerHeightConstraint.constant = isHiden ? 0 : 56
        giftContainerTopSpacing.constant = isHiden ? 0 : 15
        giftIconImageView.image = UIImage(named: howItWorks ? "icon-how-it-works" : "icon-gift")
        giftTitleLabel.text = howItWorks ? "How it works" : "Special gift for you"
        self.shouldShowHowItWorks = howItWorks//shouldShowHowItWorks
        giftOrHowItWorksOpenButton.dropShadow(color: .white, opacity: 0.0, offSet: CGSize(width: 0, height: 0), radius: 15, scale: true)
        giftOrHowItWorksButtonAnimation = giftOrHowItWorksOpenButton.animateBounceAndShadow()
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.9, initialSpringVelocity: 0.2, options: [.curveEaseIn], animations: { [weak self] in
            self?.mainContainer.layoutIfNeeded()
        }, completion: nil)
        addDashedLineAnimation()
    }
    
    private func applyStyling() {
        plusButtonDescriptionContainer.addCornerRadius(8)
        emptyStateContainer.addCornerRadius(StylingConstants.cornerRadiusDefault)
        printButton.addCornerRadius(StylingConstants.cornerRadiusDefault)
        navigationBarExtenderView.addCornerRadius(30)
        navigationBarExtenderView.layer.maskedCorners = [.layerMaxXMaxYCorner, .layerMinXMaxYCorner]
        selectionModeTopContainer.addCornerRadius(30)
        selectionModeTopContainer.layer.maskedCorners = [.layerMaxXMaxYCorner, .layerMinXMaxYCorner]
        bottomBarContainer.addCornerRadius(30)
        bottomBarContainer.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMinXMinYCorner]
        dialogButtonsContainer.addCornerRadius(30)
        dialogButtonsContainer.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMinXMinYCorner]
        deleteButtonsContainer.addCornerRadius(30)
        deleteButtonsContainer.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMinXMinYCorner]
        giftContentView.addCornerRadius(28)
        subscriptionMenuContainer.addCornerRadius(30)
        subscriptionMenuContainer.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMinXMinYCorner]
        subscriptionDiscountLabel.attributedText = String.makeStrikeThroughText("89.99")
        subscriptionMenuContainer.dropShadow(color: .black, opacity: 0.8, offSet: .zero, radius: 30, scale: true)
        dialogButtonsContainer.dropShadow(color: .black, opacity: 0.6, offSet: .zero, radius: 30, scale: true)
        giftTimerContainer.addGradientBorder(to: giftTimerContainer, radius: 16, width: 2, colors: [UIColor(hex: 0x04FFF0), UIColor(hex: 0x0487FF), UIColor(hex: 0x9948FF)])
    }
    
    private func addParticles() {
        let emitter = ParticleEmitterView()
        emitter.tag = 1
        emitter.alpha = 0.6
        emitter.isUserInteractionEnabled = false
        emitter.translatesAutoresizingMaskIntoConstraints = false
        giftOrHowItWorksContainer.insertSubview(emitter, at: 0)
        emitter.topAnchor.constraint(equalTo: giftOrHowItWorksContainer.topAnchor).isActive = true
        emitter.heightAnchor.constraint(equalToConstant: giftOrHowItWorksContainer.bounds.height - subscriptionMenuContainer.bounds.height).isActive = true
        emitter.leadingAnchor.constraint(equalTo: giftOrHowItWorksContainer.leadingAnchor).isActive = true
        emitter.trailingAnchor.constraint(equalTo: giftOrHowItWorksContainer.trailingAnchor).isActive = true
    }
    
    private func addDashedLineAnimation() {
        self.dashedLineLayer?.removeFromSuperlayer()
        self.gradient?.removeFromSuperlayer()
        self.gradient = CAGradientLayer()
        let dashedLineLayer: CAShapeLayer = {
            let bounds = emptyStateContainer.bounds
            gradient?.frame = bounds
            gradient?.type = .conic
            gradient?.colors = [UIColor(hex: 0x04EEF2).cgColor, UIColor(hex: 0x049FFC).cgColor, UIColor(hex: 0x9848FF).cgColor, UIColor(hex: 0x04EEF2).cgColor]
            let layer = CAShapeLayer()
            layer.path = UIBezierPath(roundedRect: bounds, byRoundingCorners: .allCorners, cornerRadii: CGSize(width: StylingConstants.cornerRadiusDefault, height: StylingConstants.cornerRadiusDefault)).cgPath
            layer.strokeColor = UIColor.black.cgColor
            layer.fillColor = nil
            layer.lineWidth = 5
            layer.lineDashPattern = [4, 7]
            gradient?.mask = layer
            emptyStateContainer.layer.addSublayer(gradient!)
            return layer
        }()
        self.dashedLineLayer = dashedLineLayer
        
        let dashedLineAnimation: CABasicAnimation = {
            let animation = CABasicAnimation(keyPath: "lineDashPhase")
            animation.fromValue = 0
            animation.toValue = dashedLineLayer.lineDashPattern?.reduce(0) { $0 - $1.intValue } ?? 0
            animation.duration = 1
            animation.repeatCount = .infinity
            animation.isRemovedOnCompletion = false
            return animation
        }()
        dashedLineLayer.add(dashedLineAnimation, forKey: "dashed-line")
    }
}

