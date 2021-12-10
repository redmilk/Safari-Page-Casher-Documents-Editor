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
    
    private func setup() {
        layer.shadowColor = UIColor(red: 0.106, green: 0.671, blue: 1, alpha: 0.26).cgColor
        layer.shadowOffset = CGSize(width: 0, height: 0)
        layer.shadowOpacity = 0.7
        layer.shadowRadius = 50
        layer.masksToBounds = false
        layer.shadowPath = UIBezierPath(rect: bounds).cgPath
        layer.shouldRasterize = true
        layer.rasterizationScale = 1
        backgroundColor = UIColor.clear
        
        UIView.animate(withDuration: 7.0, delay: 0, options: [.autoreverse, .repeat, .curveEaseInOut], animations: {
            self.transform = CGAffineTransform(scaleX: 2.6, y: 1.6)
            self.center = CGPoint(x: UIScreen.main.bounds.maxX, y: 1000)
        }, completion: nil)
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
    
    private func setup() {
        layer.shadowColor = UIColor(red: 0.106, green: 0.671, blue: 1, alpha: 0.26).cgColor
        layer.shadowOffset = CGSize(width: 0, height: 0)
        layer.shadowOpacity = 0.7
        layer.shadowRadius = 50
        layer.masksToBounds = false
        layer.shadowPath = UIBezierPath(rect: bounds).cgPath
        layer.shouldRasterize = true
        layer.rasterizationScale = 1
        backgroundColor = UIColor.clear
        
        UIView.animate(withDuration: 3.0, delay: 1.0, options: [.autoreverse, .repeat, .curveEaseInOut], animations: {
            self.transform = CGAffineTransform(scaleX: 2.6, y: 1.6)
            self.center = CGPoint(x: UIScreen.main.bounds.minX, y: UIScreen.main.bounds.height)
        }, completion: nil)
    }
}
