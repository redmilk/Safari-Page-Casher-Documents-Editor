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


// MARK: - ManageSubscriptionsViewController

final class ManageSubscriptionsViewController: UIViewController, ActivityIndicatorPresentable, UIGestureRecognizerDelegate {
    enum State {
        case currentSubscriptionPlan(Purchase)
        case loadingState(Bool)
    }
    
    @IBOutlet weak var navigationBarExtender: UIView!
    @IBOutlet weak var weekPlanButton: UIButton!
    @IBOutlet weak var monthlyPlanButton: UIButton!
    @IBOutlet weak var yearPlanButton: UIButton!
    @IBOutlet weak var howToCancelSubscriptionButton: UIButton!
    @IBOutlet weak var howTrialWorksButton: UIButton!
    @IBOutlet weak var aboutSubscriptionButton: UIButton!
    
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
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.input.send(.checkCurrentSubscriptionPlan)
    }
}

// MARK: - Internal

private extension ManageSubscriptionsViewController {
    
    /// Handle ViewModel's states
    func handleStates() {
        viewModel.output.sink(receiveValue: { [weak self] state in
            switch state {
            case .loadingState(let isHidden):
                isHidden ? self?.startActivityAnimation() : self?.stopActivityAnimation()
            case .currentSubscriptionPlan(let purchase):
                switch purchase {
                case .weekly: self?.toggleWeeklyPlan()
                case .monthly: self?.toggleMonthlyPlan()
                case .annual: self?.toggleYearlyPlan()
                }
            }
        })
        .store(in: &bag)
    }
    
    func configureView() {
        let backButton = UIBarButtonItem(
            image: UIImage(named: "settings-navigation-back")!,
            style: .plain,
            target: navigationController,
            action: nil)
        backButton.publisher().sink(receiveValue: { [weak self] _ in
            self?.navigationController?.popViewController(animated: true)
        }).store(in: &bag)
        navigationItem.leftBarButtonItem = backButton
        navigationController?.interactivePopGestureRecognizer?.delegate = self
        
        let textAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white]
        navigationController?.navigationBar.titleTextAttributes = textAttributes
        navigationController?.navigationBar.tintColor = .white
        title = "Manage Subscriptions"
        navigationBarExtender.addCornerRadius(30)
        //navigationBarExtender.dropShadow(color: .black, opacity: 0.6, offSet: .zero, radius: 30, scale: true)
        //weekPlanButton.isSelected.toggle()
        monthlyPlanButton.addCornerRadius(14)
        monthlyPlanButton.addBorder(1, UIColor(hex: 0x4E50BD33).withAlphaComponent(0.2))
        yearPlanButton.addCornerRadius(14)
        yearPlanButton.addBorder(1, UIColor(hex: 0x4E50BD33).withAlphaComponent(0.2))
        weekPlanButton.addCornerRadius(14)
        weekPlanButton.addBorder(1, UIColor(hex: 0x4E50BD33).withAlphaComponent(0.2))
        
        weekPlanButton.publisher().receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] button in
                self?.viewModel.input.send(.subscription(.weekly))
        }).store(in: &bag)
        monthlyPlanButton.publisher().receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] button in
                self?.viewModel.input.send(.subscription(.monthly))
        }).store(in: &bag)
        yearPlanButton.publisher().receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] button in
                self?.viewModel.input.send(.subscription(.annual))
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
