//
//  ServicesContainer.swift
//  AirPrint
//
//  Created by Danyl Timofeyev on 25.01.2022
//

import FBSDKCoreKit
import UIKit
import ApphudSDK
import Firebase


final class AnalyticsService: NSObject {
    
    init(_ application: UIApplication, _ launchOptions: [UIApplication.LaunchOptionsKey: Any]?) {
        super.init()
        initFrameworks(application, launchOptions)
    }
    
    private func initFrameworks(_ application: UIApplication, _ launchOptions: [UIApplication.LaunchOptionsKey: Any]?) {
        ApplicationDelegate.shared.application(application, didFinishLaunchingWithOptions: launchOptions)
        FirebaseApp.configure()
    }
    
    private func trackCommonEvent(_ event: String, params: [String : Any]? = nil) {
        params == nil ? AppEvents.logEvent(AppEvents.Name(event)) : AppEvents.logEvent(AppEvents.Name(event), parameters: params!)
        Analytics.logEvent(event, parameters: params)
    }
}

protocol AnalyticsEventsProtocol {
    func eventSetUserId() //
    func eventVisitApp() //
    func eventVisitScreen(screen: String)
    func eventMenuOptionPressed(option: String) //
    func eventShowSubscriptionPage(option: String)
    func eventPurchaseDidPressed(plan: String) //
    func eventFileEditDidFinished() //
    func eventPrintItemsTotal(count: Int) //
}

//MARK: - AnalyticsEventsProtocol
extension AnalyticsService: AnalyticsEventsProtocol {
    
    func eventVisitScreen(screen: String) {
        let action = "visit_screen"
        var params = [String : Any]()
        params["screen"] = screen
        trackCommonEvent(action, params: params)
    }
    
    func eventMenuOptionPressed(option: String) {
        let action = "menu_option_selected"
        var params = [String : Any]()
        params["menu_option"] = option
        trackCommonEvent(action, params: params)
    }
    
    func eventPrintItemsTotal(count: Int) {
        let action = "print_items_total"
        var params = [String : Any]()
        params["items_count"] = count
        trackCommonEvent(action, params: params)
    }
    
    func eventShowSubscriptionPage(option: String) {
        let action = "subscriptions_did_show"
        var params = [String : Any]()
        params["subscription"] = option
        trackCommonEvent(action, params: params)
    }
    
    func eventPurchaseDidPressed(plan: String) {
        let action = "subscription_purchase_pressed"
        var params = [String : Any]()
        params["plan"] = plan
        trackCommonEvent(action, params: params)
    }
    
    func eventFileEditDidFinished() {
        let action = "file_edit_finished"
        trackCommonEvent(action)
    }
    
    func eventSetUserId() {
        let id = Apphud.userID()
        Analytics.setUserID(id)
    }
    
    func eventVisitApp() {
        let action: String = "visit_to_app"
        trackCommonEvent(action)
    }
    
    //
    //    func ecommercePurchase(currency: String, value: String, orderId: String, coupon: String, supplierId: String, supplierName: String) {
    //        let action: String = "ecommerce_purchase"
    //        var params = [String : Any]()
    //        params[AnalyticsParameterCoupon] = coupon
    //        params[AnalyticsParameterTransactionID] = orderId
    //        params[AnalyticsParameterCurrency] = currency
    //        params[AnalyticsParameterValue] = Double(value)!
    //        params[AnalyticsParameterItemCategory] = supplierId + "|" + supplierName
    //        trackCommonEvent(action, params: params)
    //    }
}
