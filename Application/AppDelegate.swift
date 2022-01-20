//
//  AppDelegate.swift
//  AirPrint
//
//  Created by Danyl Timofeyev on 18.11.2021.
//

import UIKit
import ApphudSDK

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        BackgroundScheduler.shared.register()

        ApplicationGlobalConfig().configure()
        Apphud.start(apiKey: "app_EaKCtoJCJkjJV73Dc7XA2L2ikP7KST")
        
        let flag = PurchesService.currentRandomFlag
        PurchesService.currentRandomFlag = !flag
        print(PurchesService.currentRandomFlag)
        
        return true
    }
}

