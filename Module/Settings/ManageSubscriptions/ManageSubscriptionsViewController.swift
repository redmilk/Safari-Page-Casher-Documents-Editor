//
//  
//  ManageSubscriptionsViewController.swift
//  AirPrint
//
//  Created by Danyl Timofeyev on 11.12.2021.
//
//

import UIKit
import Combine


fileprivate let multiSubscriptionPopupViewTag: Int = 123

// MARK: - ManageSubscriptionsViewController

final class ManageSubscriptionsViewController: UIViewController,
                                               ActivityIndicatorPresentable,
                                               UIGestureRecognizerDelegate,
                                               SubscriptionsMultiPopupProvidable,
                                               AlertPresentable,
                                               PurchesServiceProvidable,
                                               AnalyticServiceProvider {
    
    enum State {
        case currentSubscriptionPlan(Purchase)
        case loadingState(Bool)
        case removeSubscriptionPop
        case displayAlert(text: String, title: String?, action: VoidClosure?, buttonTitle: String?)
        case gotUpdatedPrices(String, String, String, Bool) /// w,m,y, isUserEverHadSubscr
    }
    
    @IBOutlet weak var monthlyPriceLabel: UILabel!
    @IBOutlet weak var yearlyPriceLabel: UILabel!
    /// for trial case
    @IBOutlet weak var weeklyPlanTextLabel: UILabel!
    @IBOutlet weak var yearlyPriceDescriptionLabel: UILabel!
    @IBOutlet weak var weeklyPriceLabel: UILabel!
    @IBOutlet weak var navigationBarExtender: UIView!
    @IBOutlet weak var weekPlanButton: UIButton!
    @IBOutlet weak var monthlyPlanButton: UIButton!
    @IBOutlet weak var yearPlanButton: UIButton!
    @IBOutlet weak var howTrialWorksButton: UIButton!
    
    @IBOutlet weak var versionLabel: UILabel!
    @IBOutlet weak var buttonsContainerWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var navigationBarExtenderHeight: NSLayoutConstraint!
    
    private var backButton: UIBarButtonItem!
    private let viewModel: ManageSubscriptionsViewModel
    private var bag = Set<AnyCancellable>()
    
    init(viewModel: ManageSubscriptionsViewModel) {
        self.viewModel = viewModel
        super.init(nibName: String(describing: ManageSubscriptionsViewController.self), bundle: nil)
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
        handleStates()
        viewModel.input.send(.viewDidLoad)
        if UIDevice.current.userInterfaceIdiom == .pad {
            navigationBarExtenderHeight.isActive = false
            buttonsContainerWidthConstraint.isActive = false
        }
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.input.send(.checkCurrentSubscriptionPlan)
        navigationController?.interactivePopGestureRecognizer?.isEnabled = false
        analytics.eventVisitScreen(screen: "manage_subscriptions")
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.interactivePopGestureRecognizer?.isEnabled = true
    }
}

// MARK: - Internal

private extension ManageSubscriptionsViewController {
    
    /// Handle ViewModel's states
    func handleStates() {
        viewModel.output.sink(receiveValue: { [weak self] state in
            guard let self = self else { return }
            switch state {
            case .loadingState(let isHidden):
                isHidden ? self.startActivityAnimation() : self.stopActivityAnimation()
            case .currentSubscriptionPlan(let purchase):
                switch purchase {
                case .weekly: self.toggleWeeklyPlan()
                case .monthly: self.toggleMonthlyPlan()
                case .annual: self.toggleYearlyPlan()
                }
            case .displayAlert(let text, let title, let action, _):
                self.displayAlert(fromParentView: self.view, with: text, title: title, action: action)
            case .removeSubscriptionPop:
                self.removeMultiSubscripionPopupIfOccures()
            case .gotUpdatedPrices(let weekly, let monthly, let yearly, let isUserEverHadSubscription):
                self.weeklyPlanTextLabel.text = isUserEverHadSubscription ?
                "Weekly Plan" : "Weekly Plan + 3 day free trial"
                self.weeklyPriceLabel.text = weekly
                self.monthlyPriceLabel.text =  monthly
                self.yearlyPriceDescriptionLabel.text = "Yearly Plan"
                let strikedSize: CGFloat = UIDevice.current.userInterfaceIdiom == .pad ? 18 : 13
                let fontSize: CGFloat = UIDevice.current.userInterfaceIdiom == .pad ? 17 : 12
                if let yearlyStriked = self.purchases.getFormattedYearPriceForPurchase(isPurePrice: true, size: strikedSize) {
                    let yearlyPrice = String.makeAttriabutedStringNoFormatting(yearly, size: fontSize)
                    let separator = String.makeAttriabutedStringNoFormatting(" / ", size: fontSize)
                    yearlyStriked.append(separator)
                    yearlyStriked.append(yearlyPrice)
                    self.yearlyPriceLabel.attributedText = yearlyStriked
                }
            }
        })
        .store(in: &bag)
    }
    
    func configureView() {
        backButton = UIBarButtonItem(
            image: UIImage(named: "settings-navigation-back")!,
            style: .plain,
            target: navigationController,
            action: nil)
        backButton.publisher().sink(receiveValue: { [weak self] _ in
            self?.navigationController?.popViewController(animated: true)
        }).store(in: &bag)
        navigationItem.leftBarButtonItem = backButton
        navigationController?.interactivePopGestureRecognizer?.delegate = self
        navigationBarExtender.layer.zPosition = 999
        let textAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white]
        navigationController?.navigationBar.titleTextAttributes = textAttributes
        navigationController?.navigationBar.tintColor = .white
        title = "Manage Subscriptions"
        navigationBarExtender.addCornerRadius(30)
        navigationBarExtender.layer.maskedCorners = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
        monthlyPlanButton.addCornerRadius(14)
        monthlyPlanButton.addBorder(1, .systemBlue.withAlphaComponent(0.3))
        yearPlanButton.addCornerRadius(14)
        yearPlanButton.addBorder(1, .systemBlue.withAlphaComponent(0.3))
        weekPlanButton.addCornerRadius(14)
        weekPlanButton.addBorder(1, .systemBlue.withAlphaComponent(0.3))
        
        weekPlanButton.publisher().receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] button in
                self?.analytics.eventPurchaseDidPressed(plan: "weekly")
                self?.viewModel.input.send(.subscription(.weekly))
        }).store(in: &bag)
        monthlyPlanButton.publisher().receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] button in
                self?.analytics.eventPurchaseDidPressed(plan: "monthly")
                self?.viewModel.input.send(.subscription(.monthly))
        }).store(in: &bag)
        yearPlanButton.publisher().receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] _ in
                self?.analytics.eventPurchaseDidPressed(plan: "annual")
                self?.viewModel.input.send(.subscription(.annual))
        }).store(in: &bag)
        howTrialWorksButton.publisher()
            .sink(receiveValue: { [weak self] _ in
                guard let self = self else { return }
                self.navigationController?.setNavigationBarHidden(true, animated: false)
                self.navigationBarExtender.isHidden = true
                self.displayMultisubscriptionsPopup(inContainer: self.view, optionToShowFirst: .howItWorks)
        }).store(in: &bag)
        
        self.weeklyPlanTextLabel.text = PurchesService.isUserHasActiveSubscriptionsStatusSinceLastUserSession ?
        "Weekly Plan" : "Weekly Plan + 3 day free trial"
        self.weeklyPriceLabel.text = PurchesService.previousWeeklyPrice
        self.monthlyPriceLabel.text =  PurchesService.previousMonthlyPrice
        self.yearlyPriceLabel.text = PurchesService.previousYearlyPrice
        self.yearlyPriceDescriptionLabel.text = "Yearly Plan: \(PurchesService.previousYearlyPrice) / year"
        
        let appVersionString: String = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String
        let buildNumber: String = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as! String
        versionLabel.text = "version \(appVersionString) build \(buildNumber)"
    }
    
    private func removeMultiSubscripionPopupIfOccures() {
        view.subviews.forEach {
            if $0.tag == multiSubscriptionPopupViewTag {
                $0.removeFromSuperview()
                self.navigationController?.setNavigationBarHidden(false, animated: false)
                self.navigationBarExtender.isHidden = false
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
        popUp.tag = multiSubscriptionPopupViewTag
        publisher.sink(receiveValue: { [weak self] response in
            guard let self = self else { return }
            switch response {
            case .restoreSubscription:
                self.viewModel.input.send(.restoreSubscription)
            case .onPurchase(let isSecondOptionSelected):
                self.viewModel.input.send(.subscription(isSecondOptionSelected ? .annual : .monthly))
            case .onWeeklyPurchase:
                self.viewModel.input.send(.subscription(.weekly))
            case .onClose:
                popUp.removeFromSuperview()
                self.navigationController?.setNavigationBarHidden(false, animated: false)
                self.navigationBarExtender.isHidden = false
            }
        }).store(in: &bag)
    }
    
    private func toggleWeeklyPlan() {
        weekPlanButton.isSelected = true
        weekPlanButton.isUserInteractionEnabled = false
        monthlyPlanButton.isUserInteractionEnabled = true
        yearPlanButton.isUserInteractionEnabled = true
        weekPlanButton.backgroundColor = UIColor(hex: 0x1E1D51)
        monthlyPlanButton.isSelected = false
        yearPlanButton.isSelected = false
        monthlyPlanButton.addCornerRadius(14)
        monthlyPlanButton.addBorder(1, UIColor(hex: 0x4E50BD33).withAlphaComponent(0.2))
        yearPlanButton.addCornerRadius(14)
        yearPlanButton.addBorder(1, UIColor(hex: 0x4E50BD33).withAlphaComponent(0.2))
        monthlyPlanButton.backgroundColor = UIColor(hex: 0x282961)
        yearPlanButton.backgroundColor = UIColor(hex: 0x282961)
    }
    private func toggleMonthlyPlan() {
        weekPlanButton.isSelected = false
        monthlyPlanButton.isSelected = true
        monthlyPlanButton.isUserInteractionEnabled = false
        weekPlanButton.isUserInteractionEnabled = true
        yearPlanButton.isUserInteractionEnabled = true
        monthlyPlanButton.backgroundColor = UIColor(hex: 0x1E1D51)
        yearPlanButton.isSelected = false
        weekPlanButton.addCornerRadius(14)
        weekPlanButton.addBorder(1, UIColor(hex: 0x4E50BD33).withAlphaComponent(0.2))
        yearPlanButton.addCornerRadius(14)
        yearPlanButton.addBorder(1, UIColor(hex: 0x4E50BD33).withAlphaComponent(0.2))
        weekPlanButton.backgroundColor = UIColor(hex: 0x282961)
        yearPlanButton.backgroundColor = UIColor(hex: 0x282961)
    }
    private func toggleYearlyPlan() {
        weekPlanButton.isSelected = false
        monthlyPlanButton.isSelected = false
        yearPlanButton.isSelected = true
        yearPlanButton.isUserInteractionEnabled = false
        weekPlanButton.isUserInteractionEnabled = true
        monthlyPlanButton.isUserInteractionEnabled = true
        yearPlanButton.backgroundColor = UIColor(hex: 0x1E1D51)
        weekPlanButton.addCornerRadius(14)
        weekPlanButton.addBorder(1, UIColor(hex: 0x4E50BD33).withAlphaComponent(0.2))
        monthlyPlanButton.addCornerRadius(14)
        monthlyPlanButton.addBorder(1, UIColor(hex: 0x4E50BD33).withAlphaComponent(0.2))
        weekPlanButton.backgroundColor = UIColor(hex: 0x282961)
        monthlyPlanButton.backgroundColor = UIColor(hex: 0x282961)
    }
}
