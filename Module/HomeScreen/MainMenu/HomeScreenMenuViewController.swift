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

final class HomeScreenMenuViewController: UIViewController {
    enum State {
        case showSubscriptionPopup(withContent: (UIImage, UIImage, String, String))
    }
    @IBOutlet weak var buttonsContainerView: UIView!
    @IBOutlet weak var cancelButton: UIButton!

    @IBOutlet weak var scanDocumentButton: UIButton!
    @IBOutlet weak var printPhotoButton: UIButton!
    @IBOutlet weak var printDocumentButton: UIButton!
    @IBOutlet weak var printWebPage: UIButton!
    @IBOutlet weak var printFromClipboard: UIButton!
    
    @IBOutlet weak var subscriptionPopup: UIView!
    @IBOutlet weak var subscriptionButtonsContainer: UIView!
    @IBOutlet weak var subscriptionPopupImageView: UIImageView!
    @IBOutlet weak var subscriptionCloseButton: UIButton!
    @IBOutlet weak var subscriptionTitleFirstLine: UILabel!
    @IBOutlet weak var subscriptionTitleSecondLine: UILabel!
    @IBOutlet weak var subscriptionContinueButton: UIButton!
    @IBOutlet weak var secondBlurredShadowView: BlurredShadowView2!
    @IBOutlet weak var firstBlurredShadowView: BlurredShadowView1!
    
    private let viewModel: HomeScreenMenuViewModel
    private var bag = Set<AnyCancellable>()
    
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
        super.viewDidAppear(animated)
        firstBlurredShadowView.animationDuration = 2000
        secondBlurredShadowView.animationDuration = 2000
        secondBlurredShadowView.setup()
        firstBlurredShadowView.setup()
    }
}

// MARK: - Internal

private extension HomeScreenMenuViewController {
    
    func configureView() {
        viewModel.output
            .sink(receiveValue: { [weak self] state in
                switch state {
                case .showSubscriptionPopup(let content):
                    self?.subscriptionPopupImageView.image = content.0
                    self?.subscriptionContinueButton.setBackgroundImage(content.1, for: .normal)
                    self?.subscriptionTitleFirstLine.text = content.2
                    self?.subscriptionTitleSecondLine.text = content.3
                    self?.subscriptionPopup.isHidden = false
                }
            })
            .store(in: &bag)
        
        scanDocumentButton.publisher().sink(receiveValue: { [weak self] _ in
            self?.viewModel.input.send(.scanAction)
        })
        .store(in: &bag)
        printPhotoButton.publisher().sink(receiveValue: { [weak self] _ in
            self?.viewModel.input.send(.printPhoto)
        })
        .store(in: &bag)
        printDocumentButton.publisher().sink(receiveValue: { [weak self] _ in
            self?.viewModel.input.send(.printDocument)
        })
        .store(in: &bag)
        cancelButton.publisher().sink(receiveValue: { [weak self] _ in
            self?.viewModel.input.send(.closeAction)
        })
        .store(in: &bag)
        printWebPage.publisher().sink(receiveValue: { [weak self] _ in
            self?.viewModel.input.send(.printWebPage)
        })
        .store(in: &bag)
        printFromClipboard.publisher().sink(receiveValue: { [weak self] _ in
            self?.viewModel.input.send(.printFromClipboard)
        })
        .store(in: &bag)
        
        subscriptionCloseButton.publisher().sink(receiveValue: { [weak self] _ in
            self?.subscriptionPopup.isHidden = true
            self?.viewModel.input.send(.closeAction)
        })
        .store(in: &bag)
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
