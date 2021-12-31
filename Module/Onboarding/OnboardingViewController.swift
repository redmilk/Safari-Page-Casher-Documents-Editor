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
import Lottie

var currentAnimationIndex: Int = -1

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
    @IBOutlet weak var printerAnim: AnimationView!
    @IBOutlet weak var scanerAnim: AnimationView!
    @IBOutlet weak var signatureAnim: AnimationView!
    
    @IBOutlet weak var primaryImageView: UIImageView!
    @IBOutlet weak var pagingImageView: UIImageView!
    @IBOutlet weak var primaryLabel: UILabel!
    @IBOutlet weak var primaryLabelSecondLine: UILabel!
    @IBOutlet weak var descriptionText: UILabel!
    @IBOutlet weak var continueButton: UIButton!
    private var animationView: AnimationView?
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
                
        continueButton.publisher()
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] _ in
                guard let self = self else { return }
                self.model.continueButtonAction()
                if self.model.isLastOnboardingPage {
                } else {
                    self.model.continueButtonAction()
                }
            })
            .store(in: &bag)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
//        printerAnim.play()
//
//        scanerAnim.play()
//        scanerAnim.isHidden = true
//        signatureAnim.play()
//        signatureAnim.isHidden = true
//        printerAnim.play()
        changeAnimation()
    }
    
    private func changeAnimation() {
        currentAnimationIndex += 1
        
        switch currentAnimationIndex {
        case 0:
            printerAnim.isHidden = true
            scanerAnim.isHidden = false
            signatureAnim.isHidden = true
            scanerAnim.loopMode = .autoReverse
            scanerAnim.animationSpeed = 1.5
            signatureAnim.pause()
            printerAnim.pause()
            scanerAnim.play()
            scanerAnim.contentMode = .scaleAspectFit
        case 1:
            printerAnim.isHidden = true
            scanerAnim.isHidden = true
            signatureAnim.isHidden = false
            signatureAnim.loopMode = .autoReverse
            signatureAnim.animationSpeed = 1.5
            signatureAnim.contentMode = .scaleAspectFit
            signatureAnim.pause()
            printerAnim.pause()
            signatureAnim.play()
            
        case 2:
            printerAnim.isHidden = false
            printerAnim.loopMode = .autoReverse
            printerAnim.animationSpeed = 0.5
            printerAnim.contentMode = .scaleAspectFit
            scanerAnim.isHidden = true
            signatureAnim.isHidden = true
            signatureAnim.pause()
            printerAnim.play()
            scanerAnim.pause()

        case _: break
        }
    }
}
