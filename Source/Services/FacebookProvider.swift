//
//  FacebookProvider.swift
//  AirPrint
//

import FBSDKCoreKit

final class FacebookProvider {
    
    struct Settings {
        let isAutoLogAppEventsEnabled: Bool
        let isAdvertiserIDCollectionEnabled: Bool

        init(isAutoLogAppEventsEnabled: Bool, isAdvertiserIDCollectionEnabled: Bool) {
            self.isAutoLogAppEventsEnabled = isAutoLogAppEventsEnabled
            self.isAdvertiserIDCollectionEnabled = isAdvertiserIDCollectionEnabled
        }
    }

    private var trackUserProperties: Bool

    init(application: UIApplication,
         launchOptions: [UIApplication.LaunchOptionsKey: Any]?,
         trackUserProperties: Bool,
         settings: Settings) {
        self.trackUserProperties = trackUserProperties
    
        ApplicationDelegate.shared.application(application, didFinishLaunchingWithOptions: launchOptions)
        FBSDKCoreKit.Settings.shared.isAutoLogAppEventsEnabled = settings.isAutoLogAppEventsEnabled
        FBSDKCoreKit.Settings.shared.isAdvertiserIDCollectionEnabled = settings.isAdvertiserIDCollectionEnabled
    }
}

extension FacebookProvider.Settings {
    static let auto = Self(isAutoLogAppEventsEnabled: false, isAdvertiserIDCollectionEnabled: true)
}
