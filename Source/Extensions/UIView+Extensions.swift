//
//  UIView+Extensions.swift
//  ReactiveMovies
//
//  Created by Danyl Timofeyev on 17.05.2021.
//

import UIKit.UIView
import QuartzCore

protocol XibDesignable: AnyObject { }
extension XibDesignable where Self: UIView {
    static func instantiateFromXib() -> Self {
        let dynamicMetatype = Self.self
        let bundle = Bundle(for: dynamicMetatype)
        let nib = UINib(nibName: "\(dynamicMetatype)", bundle: bundle)
        guard let view = nib.instantiate(withOwner: nil, options: nil).first as? Self else {
            fatalError("Could not load view from nib file.")
        }
        return view
    }
}
extension UIView: XibDesignable { }

// MARK: - Constraints
extension UIView {
    func constraintToSides(inside superView: UIView) {
        translatesAutoresizingMaskIntoConstraints = false
        leadingAnchor.constraint(equalTo: superView.leadingAnchor).isActive = true
        trailingAnchor.constraint(equalTo: superView.trailingAnchor).isActive = true
        topAnchor.constraint(equalTo: superView.topAnchor).isActive = true
        bottomAnchor.constraint(equalTo: superView.bottomAnchor).isActive = true
    }
}

// MARK: - Styling
extension UIView: InteractionFeedbackService {
    func addCornerRadius(_ radius: CGFloat) {
        self.clipsToBounds = true
        self.layer.cornerRadius = radius
    }
    func addBorder(_ width: CGFloat, _ color: UIColor) {
        self.clipsToBounds = true
        self.layer.borderWidth = width
        self.layer.borderColor = color.cgColor
    }
    func animateFadeInOut(_ duration: CGFloat, isFadeIn: Bool, completion: (() -> Void)?) {
        self.alpha = isFadeIn ? 0 : 1
        UIView.animate(withDuration: 0.3, delay: 0.0, options: [.curveEaseInOut], animations: {
            self.alpha = isFadeIn ? 1 : 0
        }, completion: { _ in
            completion?()
        })
    }
    func addGradientBorder(to view: UIView, radius: CGFloat, width: CGFloat, colors: [UIColor]) {
        let gradient = CAGradientLayer()
        gradient.frame = CGRect(origin: CGPoint.zero, size: view.frame.size)
        gradient.colors = colors.map { $0.cgColor }
        let shape = CAShapeLayer()
        shape.lineWidth = width
        shape.path = UIBezierPath(roundedRect: view.bounds, cornerRadius: radius).cgPath
        shape.strokeColor = UIColor.black.cgColor
        shape.fillColor = UIColor.clear.cgColor
        gradient.mask = shape
        view.layer.addSublayer(gradient)
    }
    func dropShadow(scale: Bool = true) {
        layer.masksToBounds = false
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.5
        layer.shadowOffset = CGSize(width: -1, height: 1)
        layer.shadowRadius = 1
        
        layer.shadowPath = UIBezierPath(rect: bounds).cgPath
        layer.shouldRasterize = true
        layer.rasterizationScale = scale ? UIScreen.main.scale : 1
    }
    func dropShadow(color: UIColor, opacity: Float = 0.5, offSet: CGSize, radius: CGFloat = 1, scale: Bool = true) {
        layer.masksToBounds = false
        layer.shadowColor = color.cgColor
        layer.shadowOpacity = opacity
        layer.shadowOffset = offSet
        layer.shadowRadius = radius
        layer.shadowPath = UIBezierPath(rect: self.bounds).cgPath
        layer.shouldRasterize = true
        layer.rasterizationScale = scale ? UIScreen.main.scale : 1
    }
    
    // MARK: - Animations
    func animateShake() {
        let animation = CAKeyframeAnimation(keyPath: "transform.translation.x")
        animation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.linear)
        animation.duration = 0.6
        animation.values = [-20.0, 20.0, -20.0, 20.0, -10.0, 10.0, -5.0, 5.0, 0.0 ]
        animation.beginTime = CACurrentMediaTime() + 5
        layer.add(animation, forKey: "shake")
    }
    func animateBounceAndShadow() {
        Timer.scheduledTimer(withTimeInterval: 3, repeats: true) { [weak self] _ in
            self?.transform = CGAffineTransform.init(scaleX: 0.9, y: 0.9)
            UIView.animate(withDuration: 1.5, delay: 0.0, usingSpringWithDamping: 0.5, initialSpringVelocity: 15, options: [.curveEaseInOut, .allowUserInteraction], animations: {
                self?.transform = .identity
            }, completion: nil)
            self?.generateInteractionFeedback()
            let animation = CABasicAnimation(keyPath: "shadowOpacity")
            animation.fromValue = 1.0
            animation.toValue = 0.0
            animation.duration = 0.3
            self?.layer.add(animation, forKey: animation.keyPath)
        }
    }
    func animateFadeIn(_ duration: TimeInterval, delay: TimeInterval = 0, finalAlpha: CGFloat = 1.0) {
        self.alpha = 0
        UIView.animate(withDuration: duration, delay: delay, options: [.allowUserInteraction]) {
            self.alpha = finalAlpha
        }
    }
}

class ShimmerView: UIView {
    func startShimmering() {
        let light = UIColor.white.cgColor
        let alpha = UIColor.white.withAlphaComponent(0.0).cgColor

        let gradient = CAGradientLayer()
        gradient.colors = [alpha, light, alpha]
        gradient.frame = CGRect(x: -self.bounds.size.width, y: 0, width: 3 * self.bounds.size.width, height: self.bounds.size.height)
        gradient.startPoint = CGPoint(x: 1.0, y: 0.525)
        gradient.endPoint = CGPoint(x: 0.0, y: 0.5)
        gradient.locations = [0.1, 0.5, 0.9]
        self.layer.mask = gradient

        let shimmer = CABasicAnimation(keyPath: "locations")
        shimmer.fromValue = [0.0, 0.1, 0.2]
        shimmer.toValue = [0.8, 0.9, 1.0]
        shimmer.duration = 1.5
        shimmer.fillMode = .forwards
        shimmer.isRemovedOnCompletion = false

        let group = CAAnimationGroup()
        group.animations = [shimmer]
        group.duration = 2
        group.repeatCount = HUGE
        gradient.add(group, forKey: "shimmer")
    }
}

//let view = ShimmerView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
//PlaygroundPage.current.liveView = view
//
//view.backgroundColor = .blue
//view.startShimmering()
