//
//  UIBarButtonItem+Extension.swift
//  VIPexample
//
//  Created by Danyl Timofeyev on 18.10.2021.
//

import Combine
import UIKit.UIBarButtonItem

protocol BarButtonControlPublisher: UIBarButtonItem { }

extension UIBarButtonItem: BarButtonControlPublisher { }
extension BarButtonControlPublisher {
    func publisher() -> BarButtonControlWithPublisher<Self> {
        BarButtonControlWithPublisher(control: self)
    }
}

struct BarButtonControlWithPublisher<T: UIBarButtonItem>: Publisher {
    typealias Output = T
    typealias Failure = Never
    
    unowned let control: T
    
    init(control: T) {
        self.control = control
    }
    
    func receive<S>(subscriber: S) where S : Subscriber, S.Input == Output, S.Failure == Failure {
        let innerClass = Inner(downstream: subscriber, sender: control)
        subscriber.receive(subscription: innerClass)
    }
    
    final class Inner <S: Subscriber>: NSObject, Subscription where S.Input == Output, S.Failure == Failure {
        private weak var sender: T?
        private var downstream: S?
        
        init(downstream: S, sender: T) {
            self.downstream = downstream
            self.sender = sender
            super.init()
        }
        
        deinit {
            finish()
        }
        
        func request(_ demand: Subscribers.Demand) {
            sender?.action = #selector(doAction)
            sender?.target = self
        }
        
        func cancel() {
            finish()
        }
        
        @objc private func doAction(_ sender: UIControl) {
            guard let sender = self.sender else { return }
            _ = downstream?.receive(sender)
        }
        
        private func finish() {
            self.sender?.target = nil
            self.sender?.action = nil
            self.sender = nil
            self.downstream = nil
        }
    }
}
