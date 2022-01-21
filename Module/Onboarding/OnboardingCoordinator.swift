//
//  
//  OnboardingCoordinator.swift
//  AirPrint
//
//  Created by Danyl Timofeyev on 26.11.2021.
//
//

import Foundation
import UIKit.UINavigationController
import Combine

final class OnboardingCoordinator: CoordinatorProtocol {
    unowned let window: UIWindow
    var navigationController: UINavigationController?
    
    private lazy var onboardingData: [OnboardingPageModel] = [
        OnboardingPageModel(
            mainImageName: "onboarding-image-1",
            paginImageName: "onboarding-pagination-1",
            mainTextLine1: "Print files from your phone",
            mainTextLine2: "quickly and easily",
            smallDescription: "Choose files to print from your iCloud or phone gallery",
            isLastOnboardingPage: false,
            continueButtonAction: { [weak self] in
                self?.showPage2()
            }, closeButtonAction: nil),
        OnboardingPageModel(
            mainImageName: "onboarding-image-2",
            paginImageName: "onboarding-pagination-2",
            mainTextLine1: "Add your signature to a",
            mainTextLine2: "document in a second",
            smallDescription: "Select the type of edits you want to make to your document including an option to add a signature",
            isLastOnboardingPage: false,
            continueButtonAction: { [weak self] in
                self?.showPage3()
        }, closeButtonAction: nil),
        OnboardingPageModel(
            mainImageName: "onboarding-image-3",
            paginImageName: "onboarding-pagination-3",
            mainTextLine1: "Scan documents with a",
            mainTextLine2: "couple of clicks",
            smallDescription: "Scan your documents, cards, and whiteboards with your phone, making them more readable and editable",
            isLastOnboardingPage: true,
            continueButtonAction: { [weak self] in
                Onboarding.shared?.onboardingFinishAction()
            }, closeButtonAction: nil)
    ]
    
    init(window: UIWindow) {
        self.window = window
    }
    deinit {
        Logger.log(String(describing: self), type: .deinited)
    }
    
    func start() {
        let controller = OnboardingViewController(model: onboardingData[0])
        navigationController = UINavigationController(rootViewController: controller)
        navigationController?.setNavigationBarHidden(true, animated: false)
        window.rootViewController = navigationController
        window.makeKeyAndVisible()
    }
    func end() { }
    
    private func showPage2() {
        let controller = OnboardingViewController(model: onboardingData[1])
        navigationController?.pushViewController(controller, animated: false)
    }
    
    private func showPage3() {
        let controller = OnboardingViewController(model: onboardingData[2])
        navigationController?.pushViewController(controller, animated: false)
    }
    
    private func showSubscriptionPage() {
        Onboarding.shared?.onboardingFinishAction()
    }
}
