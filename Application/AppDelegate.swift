//
//  AppDelegate.swift
//  AirPrint
//
//  Created by Danyl Timofeyev on 18.11.2021.
//

import UIKit
import ApphudSDK
import FBSDKCoreKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var analytics: AnalyticsService!
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        

        ApplicationGlobalConfig().configure()
        Apphud.start(apiKey: "app_EaKCtoJCJkjJV73Dc7XA2L2ikP7KST")
        
        //FBSDKCoreKit.Settings.isAutoLogAppEventsEnabled = false
        Settings.shared.isAdvertiserIDCollectionEnabled = true
        FBSDKCoreKit.AppEvents.shared.activateApp()
        
        analytics = AnalyticsService(application, launchOptions)

        let flag = PurchesService.currentRandomFlag
        PurchesService.currentRandomFlag = !flag
        print(PurchesService.currentRandomFlag)
        
        
        return true
    }
}

