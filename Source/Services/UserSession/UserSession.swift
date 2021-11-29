//
//  File.swift
//  AirPrint
//
//  Created by Danyl Timofeyev on 29.11.2021.
//

import Foundation

protocol UserSession {
    var sessionData: PrintableDataBox? { get } 
}

final class UserSessionImpl: UserSession {
    var sessionData: PrintableDataBox?
}
