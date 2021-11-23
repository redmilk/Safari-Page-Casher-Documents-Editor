//
//  AppDelegate.swift
//  AirPrint
//
//  Created by Danyl Timofeyev on 18.11.2021.
//

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        ApplicationGlobalConfig().configure()
        
        return true
    }
    
}

