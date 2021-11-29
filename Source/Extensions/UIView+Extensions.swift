//
//  UIView+Extensions.swift
//  ReactiveMovies
//
//  Created by Danyl Timofeyev on 17.05.2021.
//

import UIKit.UIView

protocol XibDesignable: class { }
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
    func animateFadeInOut(_ duration: CGFloat, isFadeIn: Bool) {
        self.alpha = isFadeIn ? 0 : 1
        UIView.animate(withDuration: 0.3, delay: 0.0, options: [.curveEaseInOut], animations: {
            self.alpha = isFadeIn ? 1 : 0
        }, completion: nil)
    }
}
