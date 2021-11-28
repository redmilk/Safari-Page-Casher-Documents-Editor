//
//  ApplicationGlobalConfig.swift
//  AirPrint
//
//  Created by Danyl Timofeyev on 23.11.2021.
//

import UIKit

struct ApplicationGlobalConfig {
    func configure() {
        UINavigationBar.appearance().setBackgroundImage(UIImage(), for: .default)
        UINavigationBar.appearance().shadowImage = UIImage()
        UINavigationBar.appearance().isTranslucent = true

//        UIToolbar.appearance().barTintColor = .black
//        UITabBar.appearance().barTintColor = .black
//        UISearchBar.appearance().barTintColor = .black
//        UINavigationBar.appearance(whenContainedInInstancesOf: [UIDocumentBrowserViewController.self]).barTintColor = .black
    }
}
