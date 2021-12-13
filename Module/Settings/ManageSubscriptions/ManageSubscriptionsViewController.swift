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
        viewModel.output.sink(receiveValue: { [weak self] state in
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
        
        weekPlanButton.publisher().receive(on: DispatchQueue.main).sink(receiveValue: { [weak self] button in
            self?.weekPlanButton.isSelected = true
            self?.monthlyPlanButton.isSelected = false
            self?.yearPlanButton.isSelected = false
        })
        .store(in: &bag)
        
        monthlyPlanButton.publisher().receive(on: DispatchQueue.main).sink(receiveValue: { [weak self] button in
            self?.weekPlanButton.isSelected = false
            self?.monthlyPlanButton.isSelected = true
            self?.yearPlanButton.isSelected = false
        })
        .store(in: &bag)
        
        yearPlanButton.publisher().receive(on: DispatchQueue.main).sink(receiveValue: { [weak self] button in
            self?.weekPlanButton.isSelected = false
            self?.monthlyPlanButton.isSelected = false
            self?.yearPlanButton.isSelected = true
        })
        .store(in: &bag)
    }
}
