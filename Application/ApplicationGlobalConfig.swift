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
    }
}
