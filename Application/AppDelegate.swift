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
        
        ApplicationGlobalConfig().configure()
        Apphud.start(apiKey: "app_EaKCtoJCJkjJV73Dc7XA2L2ikP7KST")
        
        return true
    }
    
    func applicationDidReceiveMemoryWarning(_ application: UIApplication) {
        
    }
}

