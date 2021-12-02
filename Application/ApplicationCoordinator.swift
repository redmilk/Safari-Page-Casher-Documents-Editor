//
//  ApplicationCoordinator.swift
//  AirPrint
//
//  Created by Danyl Timofeyev on 18.11.2021.
//

import Foundation
import UIKit.UIWindow
import UIKit.UINavigationController

final class ApplicationCoordinator: CoordinatorProtocol {
    
    let window: UIWindow
    var navigationController: UINavigationController?
    
    init(window: UIWindow) {
        self.window = window
    }
    
    func start() {
        /// we fetch from somewhere if it's user's first app launch
        let isFirstLaunch: Bool = false
        isFirstLaunch ? self.showAppTutorial() : self.showContent()
    }
    func end() { }
        
    private func showAppTutorial() {
        let coordinator = ExampleCoordinator(window: window)
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
