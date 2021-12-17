//
//  ServicesContainer.swift
//  AirPrint
//
//  Created by Danyl Timofeyev on 27.11.2021.
//

import Foundation

fileprivate let services = ServicesContainer()

final class ServicesContainer {
    lazy var pdfService: PDFService = PDFServiceImpl()
    lazy var userSession: UserSession = UserSessionImpl()
    lazy var sharedResults: SharedActivityResults = SharedActivityResults()
}

// MARK: - add specific service dependency to object

/// Shared Activity Results
protocol SharedActivityResultsProvidable { }
extension SharedActivityResultsProvidable {
    var sharedResults: SharedActivityResults { services.sharedResults }
}

/// PDF Service
protocol PdfServiceProvidable { }
extension PdfServiceProvidable {
    var pdfService: PDFService { services.pdfService }
}

/// User Session Service
protocol UserSessionServiceProvidable { }
extension UserSessionServiceProvidable {
    var userSession: UserSession { services.userSession }
}

// MARK: - if you want to include all services to object

/// All services
protocol AllServicesProvidable { }
extension AllServicesProvidable {
    var allServices: ServicesContainer { services }
}
