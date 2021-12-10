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
            mainTextLine1: "Scan your documents",
            mainTextLine2: "quickly and easily",
            isLastOnboardingPage: false,
            continueButtonAction: { [weak self] in
                self?.showPage2()
            }, closeButtonAction: nil),
        OnboardingPageModel(
            mainImageName: "onboarding-image-2",
            paginImageName: "onboarding-pagination-2",
            mainTextLine1: "It is possible to add signature",
            mainTextLine2: "to the document",
            isLastOnboardingPage: false,
            continueButtonAction: { [weak self] in
                self?.showPage3()
        }, closeButtonAction: nil),
        OnboardingPageModel(
            mainImageName: "onboarding-image-3",
            paginImageName: "onboarding-pagination-3",
            mainTextLine1: "Simple printing of documents",
            mainTextLine2: "photos from the phone.",
            isLastOnboardingPage: true,
            continueButtonAction: { [weak self] in
                self?.showSubscriptionPage()
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
//
//        window.rootViewController = navigationController
//        window.makeKeyAndVisible()
    }
}
