//
//  Purchase.swift
//  AirPrint
//
//  Created by Danyl Timofeyev on 20.12.2021.
//

import Foundation
import ApphudSDK
import StoreKit

enum Purchase {
    case monthly
    case weeklyTrial
    case weekly
    case annual
    var productId: String {
        switch self {
        case .monthly:
            return "surf.devip.news.monthly"
        case .weekly:
            return "surf.devip.news.weekly"
        case .annual:
            return "surf.devip.news.annual"
        case .weeklyTrial:
            return "surf.devip.news.weekly"
        }
    }

    var title: String {
        switch self {
        case .monthly:
            return "Monthly plan"
        case .weekly:
            return "Weekly plan"
        case .annual:
            return "Annual plan"
        case .weeklyTrial:
            return "Weekly plan"
        }
    }
    var profitShort: String? {
        switch self {
        case .monthly:
            return "save 50%"
        case .weekly:
            return "3-day free"
        case .annual:
            return "save 50%"
        case .weeklyTrial:
            return ""
        }
    }
    func profit(model: ApphudProduct?) -> String {
        switch self {
        case .monthly:
            return model?.skProduct?.price.stringValue ?? ""
        case .weekly, .weeklyTrial:
            return "Auto-renews at \(model?.skProduct?.price.stringValue ?? "") / week"
        case .annual:
            return model?.skProduct?.price.stringValue ?? ""
        }
    }
    var profitDescr: String? {
        switch self {
        case .monthly:
            return "For our friends 50% discount"
        case .weekly:
            return "After a 3-day free trial. Manage anytime."
        case .annual:
            return "For our friends 50% discount"
        case .weeklyTrial:
            return nil
        }
    }
    var promoId: String? {
//        switch self {
//        case .weeklyOffer:
//            return "surf.devip.news.weekly.offer"
//        default:
            return nil
//        }
    }
    //    var profit: String {
    //        switch self {
    //        case .monthly:
    //            return "save 50%"
    //        case .weekly:
    //            return "Auto-renews at %@ / week"
    //        case .annual:
    //            return "save 50%"
    //        }
    //    }
}
