//
//  UIViewController+Extensions.swift
//  AirPrint
//
//  Created by Danyl Timofeyev on 22.11.2021.
//

import UIKit.UIViewController

extension UIViewController {
    var sceneDelegate: SceneDelegate? {
        for scene in UIApplication.shared.connectedScenes {
            if scene == SceneDelegate.currentScene,
               let delegate = scene.delegate as? SceneDelegate {
                return delegate
            }
        }
        return nil
    }
}
