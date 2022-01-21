//
//  SessionCleaner.swift
//  AirPrint
//
//  Created by Danyl Timofeyev on 20.01.2022.
//

import Foundation
import BackgroundTasks
/// fire debug:
/// e -l objc -- (void)[[BGTaskScheduler sharedScheduler] _simulateLaunchForTaskWithIdentifier:@"com.surf.devip"]
class BackgroundScheduler {
    
    static let shared = BackgroundScheduler()
    
    var taskProcess: VoidClosure?
    var shouldRepeating: Bool = true

    private var taskIdentifierFromPlist: String!
    
    func register(taskIdentifier: String = "com.surf.devip") {
        taskIdentifierFromPlist = taskIdentifier
        BGTaskScheduler.shared.register(forTaskWithIdentifier: taskIdentifier, using: nil) { (task) in
            self.handleAppRefreshTask(task: task as! BGAppRefreshTask)
        }
    }
    
    func handleAppRefreshTask(task: BGAppRefreshTask) {
        task.expirationHandler = {
            task.setTaskCompleted(success: false)
        }
        /// task process
        //UserDefaults.standard.set("\(Date().timeIntervalSince1970)", forKey: "123")
        taskProcess?()
        ///
        task.setTaskCompleted(success: true)
        if shouldRepeating {
            scheduleBackgroundFetch()
        }
    }
    
    func scheduleBackgroundFetch(in seconds: Double = 60) {
        let task = BGAppRefreshTaskRequest(identifier: taskIdentifierFromPlist)
        //task.earliestBeginDate = Date(timeIntervalSinceNow: seconds)
        do {
            try BGTaskScheduler.shared.submit(task)
        } catch {
            Logger.log("Unable to submit task: \(error.localizedDescription)", type: .error)
            Logger.logError(error)
        }
    }
    
    func cancelPendingTask() {
        BGTaskScheduler.shared.cancelAllTaskRequests()
    }
}
