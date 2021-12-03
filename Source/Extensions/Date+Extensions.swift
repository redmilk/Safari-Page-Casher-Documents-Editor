//
//  Date+Extensions.swift
//  AirPrint
//
//  Created by Danyl Timofeyev on 03.12.2021.
//

import Foundation

extension Date {
    var millisecondsSince1970: Int64 {
        Int64((self.timeIntervalSince1970 * 1000.0).rounded())
    }
}
