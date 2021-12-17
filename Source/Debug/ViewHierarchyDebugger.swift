//
//  ViewHierarchyDebugger.swift
//  AirPrint
//
//  Created by Danyl Timofeyev on 28.11.2021.
//

import Foundation

enum ViewHierarchyDebugger {
    
    // TODO: - Implement for whole chain
    static func paintEverythingWithinResponderChain(_ responder: UIResponder?) {
        guard let _ = responder else { return }
    }
    
    static func paintEverythingWithinViewController(_ vc: UIViewController?) {
        paintEverythingToBlackWithinView(vc?.view)
        if let navigation = vc?.navigationController {
            navigation.navigationBar.backgroundColor = .black
            navigation.navigationBar.barTintColor = .black
            navigation.navigationBar.tintColor = .black
            if let toolbarItems = navigation.toolbarItems {
                toolbarItems.forEach {
                    paintEverythingToBlackWithinView($0.customView)
                    $0.tintColor = .black                    
                }
            }
            if let tabbar = navigation.tabBarController {
                tabbar.children.forEach { paintEverythingWithinViewController($0) }
            }
            if let toolbar = navigation.toolbar {
                toolbar.barTintColor = .black
                toolbar.backgroundColor = .black
                toolbar.tintColor = .black
                paintEverythingToBlackWithinView(toolbar.inputView)
                toolbar.subviews.forEach { paintEverythingToBlackWithinView($0) }
            }
            navigation.viewControllers.forEach { paintEverythingToBlackWithinView($0.view) }
        }
        if let tabbar = vc?.tabBarController?.tabBar, let tabbarController = vc?.tabBarController {
            tabbar.barTintColor = .black
            tabbar.backgroundColor = .black
            tabbar.tintColor = .black
            paintEverythingToBlackWithinView(tabbar)
            tabbarController.children.forEach { paintEverythingWithinViewController($0)}
        }
    }
    
    static func paintEverythingToBlackWithinView(_ view: UIView?) {
        guard let view = view else { return }
        view.subviews.forEach {
            $0.backgroundColor = .black
            $0.tintColor = .black
            if let bar = $0 as? UIToolbar {
                bar.barTintColor = .black
                bar.backgroundColor = .black
                bar.tintColor = .black
            }
            if let bar = $0 as? UINavigationBar {
                bar.barTintColor = .black
                bar.backgroundColor = .black
                bar.tintColor = .black
            }
            paintEverythingToBlackWithinView($0)
        }
    }
}
