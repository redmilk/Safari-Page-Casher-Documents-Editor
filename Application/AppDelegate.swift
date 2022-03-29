//
//  AppDelegate.swift
//  AirPrint
//
//  Created by Danyl Timofeyev on 18.11.2021.
//

import UIKit
import ApphudSDK
import FacebookCore

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var analytics: AnalyticsService!

    
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        ApplicationDelegate.shared.application(application, didFinishLaunchingWithOptions: launchOptions)
        
        ApplicationGlobalConfig().configure()
        Apphud.start(apiKey: "app_EaKCtoJCJkjJV73Dc7XA2L2ikP7KST")

        //FBSDKCoreKit.Settings.isAutoLogAppEventsEnabled = false
        Settings.shared.isAdvertiserIDCollectionEnabled = true
        //FBSDKCoreKit.AppEvents.shared.activateApp()
        //FBSDKCoreKit.

        analytics = AnalyticsService(application, launchOptions)

        let flag = PurchesService.currentRandomFlag
        PurchesService.currentRandomFlag = !flag
        
        return true
    }
          
    func application(
        _ app: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey: Any] = [:]
    ) -> Bool {
        ApplicationDelegate.shared.application(app, open: url,
            sourceApplication: options[UIApplication.OpenURLOptionsKey.sourceApplication] as? String,
            annotation: options[UIApplication.OpenURLOptionsKey.annotation])
    }
}

