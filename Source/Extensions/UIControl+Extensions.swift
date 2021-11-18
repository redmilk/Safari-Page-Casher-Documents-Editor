//
//  UIControl+Extensions.swift
//  ReactiveMovies
//
//  Created by Danyl Timofeyev on 23.04.2021.
//

import Combine
import Foundation
import UIKit

protocol ControlWithPublisher: UIControl { }
extension UIControl: ControlWithPublisher { }
extension ControlWithPublisher {
    func publisher(for event: UIControl.Event = .primaryActionTriggered) -> ControlPublisher<Self> {
        ControlPublisher(control: self, for: event)
    }
}

struct ControlPublisher<T: UIControl>: Publisher {
    typealias Output = T
    typealias Failure = Never
    
    unowned let control: T
    let event: UIControl.Event
    
    init(control: T, for event: UIControl.Event = .primaryActionTriggered) {
        self.control = control
        self.event = event
    }
    
    func receive<S>(subscriber: S) where S: Subscriber, S.Input == Output, S.Failure == Failure {
        let innerClass = Inner(downstream: subscriber, sender: control, event: event)
        subscriber.receive(subscription: innerClass)
    }
    
    final class Inner <S: Subscriber>: NSObject, Subscription where S.Input == Output, S.Failure == Failure {
        private weak var sender: T?
        private let event: UIControl.Event
        private var downstream: S?
        
        init(downstream: S, sender: T, event: UIControl.Event) {
            self.downstream = downstream
            self.sender = sender
            self.event = event
            super.init()
        }
        
        deinit {
            finish()
        }
        
        func request(_ demand: Subscribers.Demand) {
            sender?.addTarget(self, action: #selector(doAction), for: event)
        }
        
        func cancel() {
            finish()
        }
        
        @objc private func doAction(_ sender: UIControl) {
            guard let sender = self.sender else { return }
            _ = downstream?.receive(sender)
        }
        
        private func finish() {
            self.sender?.removeTarget(self, action: #selector(doAction), for: event)
            self.sender = nil
            self.downstream = nil
        }
    }
}
