//
//  InteractionFeedbackService.swift
//  AirPrint
//
//  Created by Danyl Timofeyev on 24.11.2021.
//
//

import Foundation
import AudioToolbox
import UIKit

protocol InteractionFeedbackService {
    func generateNotificationFeedback(type: UINotificationFeedbackGenerator.FeedbackType)
    func generateInteractionFeedback(style: UIImpactFeedbackGenerator.FeedbackStyle)
}

extension InteractionFeedbackService {
    func generateInteractionFeedback(style: UIImpactFeedbackGenerator.FeedbackStyle = .light) {
        if UIDevice.current.hasHapticFeedback {
            let generator = UIImpactFeedbackGenerator(style: style)
            generator.prepare()
            generator.impactOccurred()
        } else {
            AudioServicesPlaySystemSound(1520)
        }
    }
    
    func generateNotificationFeedback(type: UINotificationFeedbackGenerator.FeedbackType = .success) {
        if UIDevice.current.hasHapticFeedback {
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(type)
        } else {
            AudioServicesPlaySystemSound(1520)
        }
    }
}

extension UIDevice {
    var hasHapticFeedback: Bool {
        return (UIDevice.current.value(forKey: "_feedbackSupportLevel") as? Int ?? 0) > 1
    }
}
