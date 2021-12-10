//
//  Onboarding.swift
//  AirPrint
//
//  Created by Danyl Timofeyev on 10.12.2021.
//

import Foundation

fileprivate let onboardingKey = "shouldShowOnboarding"

final class Onboarding {
    static var shared: Onboarding? = Onboarding()
    
    var shouldShowOnboarding: Bool {
        get { (UserDefaults.standard.value(forKey: onboardingKey) as? Bool) ?? true }
        set { UserDefaults.standard.set(newValue, forKey: onboardingKey) }
    }
    
    var onboardingFinishAction: VoidClosure!
    
    deinit {
        Logger.log(String(describing: self), type: .deinited)
    }
}
