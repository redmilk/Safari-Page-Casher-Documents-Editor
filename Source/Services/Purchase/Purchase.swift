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
    case weekly
    case annual
    var productId: String {
        switch self {
        case .monthly:
            return "surf.devip.print.monthly"
        case .weekly:
            return "surf.devip.print.weekly"
        case .annual:
            return "surf.devip.print.annual"
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
        }
    }
    func profit(model: ApphudProduct?) -> String {
        switch self {
        case .monthly:
            return model?.skProduct?.price.stringValue ?? ""
        case .weekly:
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
        }
    }
}
