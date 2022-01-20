//
//  TaskBackgroundKeeper.swift
//  AirPrint
//
//  Created by Danyl Timofeyev on 19.01.2022.
//

import Foundation

class TaskBackgroundKeeper {
    private var backgroundTaskId: UIBackgroundTaskIdentifier?
    private var taskName: String = "task-that-should-continue-runing-in-background"
    private var queue = DispatchQueue.global(qos: .background)

    func executeAfterDelay(delay: TimeInterval, completion: @escaping (() -> Void)) {
        backgroundTaskId = UIApplication.shared.beginBackgroundTask(
            withName: taskName,
            expirationHandler: { [weak self] in
                if let taskId = self?.backgroundTaskId {
                    UIApplication.shared.endBackgroundTask(taskId)
                }
            })
        let startTime = Date()
        queue.async {
            while Date().timeIntervalSince(startTime) < delay {
                Thread.sleep(forTimeInterval: 1) //0.01)
            }
            DispatchQueue.main.async { [weak self] in
                completion()
                if let taskId = self?.backgroundTaskId {
                    UIApplication.shared.endBackgroundTask(taskId)
                }
            }
        }
    }
}
