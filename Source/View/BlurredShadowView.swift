//
//  BlurredShadowView.swift
//  AirPrint
//
//  Created by Danyl Timofeyev on 10.12.2021.
//

import Foundation
import UIKit

final class BlurredShadowView1: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    var animationDuration: CFTimeInterval = 6
    var isAnimated: Bool = true
    
    func setup() {
        self.layer.removeAllAnimations()
        layer.shadowColor = UIColor(red: 0.106, green: 0.671, blue: 1, alpha: 0.26).cgColor
        layer.shadowOffset = CGSize(width: 0, height: 0)
        layer.shadowOpacity = 1
        layer.shadowRadius = 50
        layer.masksToBounds = false
        layer.shadowPath = UIBezierPath(rect: bounds).cgPath
        layer.shouldRasterize = true
        layer.rasterizationScale = 1
        backgroundColor = UIColor.clear
        
        guard isAnimated else { return }

        UIView.animate(withDuration: animationDuration, delay: 0, options: [.autoreverse, .repeat, .curveEaseInOut], animations: {
            self.transform = CGAffineTransform(scaleX: 2.0, y: 2.0)
        }, completion: { _ in
            UIView.animate(withDuration: 5.0, delay: 0, options: [.autoreverse, .repeat, .curveEaseInOut], animations: {
                self.center.x -= 1000
                self.transform = CGAffineTransform(scaleX: 1.6, y: 1.6)
            })
        })
    }
}

final class BlurredShadowView2: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    var animationDuration: CFTimeInterval = 6
    var isAnimated: Bool = true
    
    func setup() {
        self.layer.removeAllAnimations()
        layer.shadowColor = UIColor(red: 0.106, green: 0.671, blue: 1, alpha: 0.26).cgColor
        layer.shadowOffset = CGSize(width: 0, height: 0)
        layer.shadowOpacity = 0.9
        layer.shadowRadius = 50
        layer.masksToBounds = false
        layer.shadowPath = UIBezierPath(rect: bounds).cgPath
        layer.shouldRasterize = true
        layer.rasterizationScale = 1
        backgroundColor = UIColor.clear
        
        guard isAnimated else { return }
        UIView.animate(withDuration: animationDuration, delay: 0.0, options: [.autoreverse, .repeat, .curveEaseInOut], animations: {
            self.transform = CGAffineTransform(scaleX: 2.6, y: 1.6)
            self.center = CGPoint(x: UIScreen.main.bounds.minX - 300, y: UIScreen.main.bounds.height + 600)
            self.alpha = 0.2
        }, completion: nil)
    }
}

// MARK: - more calm for backgr

final class BlurredShadowView3: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    var animationDuration: CFTimeInterval = 6
    var isAnimated: Bool = false
    
    func setup() {
        self.layer.removeAllAnimations()
        layer.shadowColor = UIColor(red: 0.106, green: 0.671, blue: 1, alpha: 0.26).cgColor
        layer.shadowOffset = CGSize(width: 0, height: 0)
        layer.shadowOpacity = 1
        layer.shadowRadius = 50
        layer.masksToBounds = false
        layer.shadowPath = UIBezierPath(rect: bounds).cgPath
        layer.shouldRasterize = true
        layer.rasterizationScale = 1
        backgroundColor = UIColor.clear
    }
}
