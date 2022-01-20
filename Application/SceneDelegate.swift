//
//  SceneDelegate.swift
//  AirPrint
//
//  Created by Danyl Timofeyev on 18.11.2021.
//

import UIKit

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

    func sceneDidDisconnect(_ scene: UIScene) {
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
    }

    func sceneWillResignActive(_ scene: UIScene) {
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        //BackgroundScheduler.shared.cancelPendingTask()
        //print("🥲🥲🥲")
        //print(UserDefaults.standard.value(forKey: "123") as? String)
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        BackgroundScheduler.shared.scheduleBackgroundFetch(in: 10)
    }
}

