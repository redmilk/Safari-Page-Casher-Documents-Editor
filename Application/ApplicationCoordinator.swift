//
//  ApplicationCoordinator.swift
//  AirPrint
//
//  Created by Danyl Timofeyev on 18.11.2021.
//

import Foundation
import UIKit.UIWindow
import UIKit.UINavigationController

final class ApplicationCoordinator: CoordinatorProtocol, UserSessionServiceProvidable {
    
    unowned let window: UIWindow
    var navigationController: UINavigationController?
    var childCoordinators: [CoordinatorProtocol] = []
    
    init(window: UIWindow) {
        self.window = window
    }
    
    func start() {
        /// we fetch from somewhere if it's user's first app launch
        let shouldShowOnboarding: Bool = Onboarding.shared?.shouldShowOnboarding ?? true
        shouldShowOnboarding ? showOnboarding() : showContent()
    }
    func end() { }
        
    private func showOnboarding() {
        Onboarding.shared?.onboardingFinishAction = { [weak self] in
            self?.childCoordinators.removeAll()
            self?.showContent()
            Onboarding.shared?.shouldShowOnboarding = false
            Onboarding.shared = nil
        }
        let coordinator = OnboardingCoordinator(window: window)
        childCoordinators.append(coordinator)
        coordinator.start()
    }
    
    private func showContent() {
        navigationController = UINavigationController()
        window.rootViewController = navigationController
        window.makeKeyAndVisible()
        let homeScreen = HomeScreenCoordinator(navigationController: navigationController!)
        homeScreen.start()
    }
}
