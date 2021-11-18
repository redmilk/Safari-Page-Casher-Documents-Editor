//
//  ApplicationCoordinator.swift
//  AirPrint
//
//  Created by Danyl Timofeyev on 18.11.2021.
//

import Foundation
import UIKit.UIWindow

final class ApplicationCoordinator: CoordinatorProtocol {
    
    let window: UIWindow
    var navigationController: UINavigationController?
    
    init(window: UIWindow) {
        self.window = window
    }
    
    func start() {
        /// we fetch from somewhere if it's user's first app launch
        var isFirstLaunch: Bool = true
        isFirstLaunch ? self.showAppTutorial() : self.showContent()
    }
    
    private func showAppTutorial() {
        let appTutorialModule = ExampleCoordinator(window: window)
        appTutorialModule.start()
    }
    
    private func showContent() {
//        let homeScreenModule = HomeScreenCoordinator(window: window)
//        homeScreenModule.start()
    }
}
