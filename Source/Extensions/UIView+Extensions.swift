//
//  UIView+Extensions.swift
//  ReactiveMovies
//
//  Created by Danyl Timofeyev on 17.05.2021.
//

import UIKit.UIView

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
extension UIView {
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
}
