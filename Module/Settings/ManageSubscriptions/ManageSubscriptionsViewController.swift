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

final class ManageSubscriptionsViewController: UIViewController {
    enum State {
        case dummyState
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
}

// MARK: - Internal

private extension ManageSubscriptionsViewController {
    
    /// Handle ViewModel's states
    func handleStates() {
        viewModel.output.sink(receiveValue: { state in
            switch state {
            case .dummyState:
                break
            }
        })
        .store(in: &bag)
    }
    
    func configureView() {
        let textAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white]
        navigationController?.navigationBar.titleTextAttributes = textAttributes
        navigationController?.navigationBar.tintColor = .white
        title = "Manage Subscriptions"
        navigationBarExtender.addCornerRadius(30)
        //navigationBarExtender.dropShadow(color: .black, opacity: 0.6, offSet: .zero, radius: 30, scale: true)
        weekPlanButton.isSelected.toggle()
        monthlyPlanButton.addCornerRadius(14)
        monthlyPlanButton.addBorder(1, UIColor(hex: 0x4E50BD33).withAlphaComponent(0.2))
        yearPlanButton.addCornerRadius(14)
        yearPlanButton.addBorder(1, UIColor(hex: 0x4E50BD33).withAlphaComponent(0.2))
        weekPlanButton.addCornerRadius(14)
        weekPlanButton.backgroundColor = UIColor(hex: 0x1E1D51)
        
        weekPlanButton.publisher().receive(on: DispatchQueue.main).sink(receiveValue: { [weak self] button in
            self?.weekPlanButton.isSelected = true
            self?.weekPlanButton.backgroundColor = UIColor(hex: 0x1E1D51)
            self?.monthlyPlanButton.isSelected = false
            self?.yearPlanButton.isSelected = false
            self?.monthlyPlanButton.addCornerRadius(14)
            self?.monthlyPlanButton.addBorder(1, UIColor(hex: 0x4E50BD33).withAlphaComponent(0.2))
            self?.yearPlanButton.addCornerRadius(14)
            self?.yearPlanButton.addBorder(1, UIColor(hex: 0x4E50BD33).withAlphaComponent(0.2))
            self?.monthlyPlanButton.backgroundColor = UIColor(hex: 0x282961)
            self?.yearPlanButton.backgroundColor = UIColor(hex: 0x282961)
        })
        .store(in: &bag)
        
        monthlyPlanButton.publisher().receive(on: DispatchQueue.main).sink(receiveValue: { [weak self] button in
            self?.weekPlanButton.isSelected = false
            self?.monthlyPlanButton.isSelected = true
            self?.monthlyPlanButton.backgroundColor = UIColor(hex: 0x1E1D51)
            self?.yearPlanButton.isSelected = false
            self?.weekPlanButton.addCornerRadius(14)
            self?.weekPlanButton.addBorder(1, UIColor(hex: 0x4E50BD33).withAlphaComponent(0.2))
            self?.yearPlanButton.addCornerRadius(14)
            self?.yearPlanButton.addBorder(1, UIColor(hex: 0x4E50BD33).withAlphaComponent(0.2))
            self?.weekPlanButton.backgroundColor = UIColor(hex: 0x282961)
            self?.yearPlanButton.backgroundColor = UIColor(hex: 0x282961)
        })
        .store(in: &bag)
        
        yearPlanButton.publisher().receive(on: DispatchQueue.main).sink(receiveValue: { [weak self] button in
            self?.weekPlanButton.isSelected = false
            self?.monthlyPlanButton.isSelected = false
            self?.yearPlanButton.isSelected = true
            self?.yearPlanButton.backgroundColor = UIColor(hex: 0x1E1D51)
            self?.weekPlanButton.addCornerRadius(14)
            self?.weekPlanButton.addBorder(1, UIColor(hex: 0x4E50BD33).withAlphaComponent(0.2))
            self?.monthlyPlanButton.addCornerRadius(14)
            self?.monthlyPlanButton.addBorder(1, UIColor(hex: 0x4E50BD33).withAlphaComponent(0.2))
            self?.weekPlanButton.backgroundColor = UIColor(hex: 0x282961)
            self?.monthlyPlanButton.backgroundColor = UIColor(hex: 0x282961)
        })
        .store(in: &bag)
    }
}
