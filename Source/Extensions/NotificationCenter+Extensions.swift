//
//  NotificationCenter+Extensions.swift
//  AirPrint
//
//  Created by Danyl Timofeyev on 22.01.2022.
//

import Foundation

extension Notification.Name {
    static let pdfImportProcessDidStart = Notification.Name("pdf-import-process-start")
    static let pdfImportProcessDidStop = Notification.Name("pdf-import-process-stop")
    static let printingJobDone = Notification.Name("printing-job-done")
    static let cleanUserSession = Notification.Name("clean-user-session")
}
