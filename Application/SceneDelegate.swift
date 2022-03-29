//
//  SceneDelegate.swift
//  AirPrint
//
//  Created by Danyl Timofeyev on 18.11.2021.
//

import UIKit
import FacebookCore

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    static var currentScene: UIScene?
    var window: UIWindow?
    var applicationCoordinator: ApplicationCoordinator!

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
  
        guard let windowScene = (scene as? UIWindowScene) else { return }
        SceneDelegate.currentScene = scene
        window = UIWindow(windowScene: windowScene)
        window!.makeKeyAndVisible()
        
        applicationCoordinator = ApplicationCoordinator(window: window!)
        applicationCoordinator.start()        
    }
    
    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        guard let url = URLContexts.first?.url else {
            return
        }

        ApplicationDelegate.shared.application(
            UIApplication.shared,
            open: url,
            sourceApplication: nil,
            annotation: [UIApplication.OpenURLOptionsKey.annotation]
        )
    }

    func sceneDidDisconnect(_ scene: UIScene) {
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
    }

    func sceneWillResignActive(_ scene: UIScene) {
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        let thisTime = Date().timeIntervalSince1970
        if let lastTimeSinceBackground = UserSessionImpl.lastBackgroundDate {
            if thisTime > lastTimeSinceBackground {
                NotificationCenter.default.post(name: Notification.Name.cleanUserSession, object: nil)
            }
        }
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        let timeToSet = Date().addingTimeInterval(60 * 30).timeIntervalSince1970
        UserSessionImpl.lastBackgroundDate = timeToSet
    }
}

