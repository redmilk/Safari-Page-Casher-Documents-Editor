//
//  
//  OnboardingViewController.swift
//  AirPrint
//
//  Created by Danyl Timofeyev on 26.11.2021.
//
//

import UIKit
import Combine

// MARK: - OnboardingViewController

struct OnboardingPageModel {
    let mainImageName: String
    let paginImageName: String
    let mainTextLine1: String
    let mainTextLine2: String
    let isLastOnboardingPage: Bool
    let continueButtonAction: VoidClosure
    let closeButtonAction: VoidClosure?
}

final class OnboardingViewController: UIViewController {
        
    @IBOutlet weak var primaryImageView: UIImageView!
    @IBOutlet weak var pagingImageView: UIImageView!
    @IBOutlet weak var primaryLabel: UILabel!
    @IBOutlet weak var primaryLabelSecondLine: UILabel!
    @IBOutlet weak var descriptionText: UILabel!
    @IBOutlet weak var continueButton: UIButton!
    
    // subscription flow
    @IBOutlet weak var dimmedView: UIView!
    @IBOutlet weak var closeButton: UIButton!
    // 1
    @IBOutlet weak var subscriptionFlowContainerOne: UIView!
    @IBOutlet weak var subscriptionFlowOneContinue: UIButton!
    // 2
    @IBOutlet weak var subscriptionFlowContainerTwo: UIView!
    @IBOutlet weak var firstPlanButton: UIButton!
    @IBOutlet weak var secondPlanButton: UIButton!
    @IBOutlet weak var subscriptionFlowTwoContinue: UIButton!
    
    private var bag = Set<AnyCancellable>()
    private let model: OnboardingPageModel
    
    init(model: OnboardingPageModel) {
        self.model = model
        super.init(nibName: String(describing: OnboardingViewController.self), bundle: nil)
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    deinit {
        Logger.log(String(describing: self), type: .deinited)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        primaryImageView.image = UIImage(named: model.mainImageName)!
        pagingImageView.image = UIImage(named: model.paginImageName)!
        primaryLabel.text = model.mainTextLine1
        primaryLabelSecondLine.text = model.mainTextLine2
        descriptionText.text = "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor"
        
        dimmedView.isHidden = true
        subscriptionFlowContainerOne.isHidden = true
        subscriptionFlowContainerTwo.isHidden = true
        
        continueButton.publisher()
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] _ in
                guard let self = self else { return }
                if self.model.isLastOnboardingPage {
                    self.dimmedView.isHidden = false
                    self.subscriptionFlowContainerOne.isHidden = false
                } else {
                    self.model.continueButtonAction()
                }
            })
            .store(in: &bag)
        
        subscriptionFlowOneContinue.publisher().sink(receiveValue: { [weak self] _ in
            self?.subscriptionFlowContainerOne.isHidden = true
            self?.subscriptionFlowContainerTwo.isHidden = false
        })
        .store(in: &bag)
        
        firstPlanButton.publisher().sink(receiveValue: { [weak self] _ in
            self?.firstPlanButton.isSelected.toggle()
            self?.secondPlanButton.isSelected.toggle()
        })
        .store(in: &bag)
        
        secondPlanButton.publisher().sink(receiveValue: { [weak self] _ in
            self?.secondPlanButton.isSelected.toggle()
            self?.firstPlanButton.isSelected.toggle()
        })
        .store(in: &bag)
        
        closeButton.publisher().sink(receiveValue: { [weak self] _ in
            self?.model.continueButtonAction()
        })
        .store(in: &bag)
        
        subscriptionFlowTwoContinue.publisher().sink(receiveValue: { [weak self] _ in
            self?.model.continueButtonAction()
            /// make purchase
        })
        .store(in: &bag)
        
        firstPlanButton.isSelected.toggle()
        
        subscriptionFlowContainerOne.addCornerRadius(30.0)
        subscriptionFlowContainerOne.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        subscriptionFlowContainerTwo.addCornerRadius(30.0)
        subscriptionFlowContainerTwo.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
    }
}
