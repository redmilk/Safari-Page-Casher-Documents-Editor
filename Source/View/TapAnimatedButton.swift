//
//  TapAnimatedButton.swift
//  AirPrint
//
//  Created by Danyl Timofeyev on 23.12.2021.
//

import Foundation

class NibButton: UIButton {
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    func commonInit() {
        addAndFill(loadViewFromNib(nibName: String(describing: Self.self)))
    }
}

class TapAnimatedButton: UIButton {
    var onTouchesEnded: (() -> Void)?
    var viewListForAnimatingAccordinglyWithTranslationToRight: [UIView] = []
    var viewListForAnimatingAccordinglyWithTranslationToLeft: [UIView] = []
    var translationAmount: CGFloat = 20
    
    var shouldAnimate: Bool = false
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        if state == .highlighted {
            isHighlighted = false
        }
        UIView.animate(withDuration: 0.2) {
            self.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
            self.viewListForAnimatingAccordinglyWithTranslationToRight.forEach {
                $0.transform = CGAffineTransform(scaleX: 0.9, y: 0.9).concatenating(CGAffineTransform(translationX: self.translationAmount, y: 0))
            }
            self.viewListForAnimatingAccordinglyWithTranslationToLeft.forEach {
                $0.transform = CGAffineTransform(scaleX: 0.9, y: 0.9).concatenating(CGAffineTransform(translationX: -self.translationAmount, y: 0))
            }
        }
    }
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        UIView.animate(withDuration: 0.2) {
            self.transform = .identity
            (self.viewListForAnimatingAccordinglyWithTranslationToRight + self.viewListForAnimatingAccordinglyWithTranslationToLeft).forEach {
                $0.transform = .identity
            }
        } completion: { [weak self] _ in
            self?.onTouchesEnded?()
        }
        shouldAnimate = false
    }
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with: event)
        if state == .highlighted {
            isHighlighted = false
        }
    }
    func bounceAnimation(with duration: TimeInterval = 0.7) {
        self.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
        UIView.animate(withDuration: duration, delay: 0, usingSpringWithDamping: 0.2, initialSpringVelocity: 6.0, animations: {
            self.transform = .identity
        }, completion: nil)
    }
}
