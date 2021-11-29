//
//  UIButton+Extensions.swift
//  AirPrint
//
//  Created by Danyl Timofeyev on 29.11.2021.
//

import Foundation

extension UIButton {
    func centerButtonAndImageWithSpacing(_ spacing: CGFloat) {
        let insetAmount = spacing / 2.0
        self.imageEdgeInsets = UIEdgeInsets(top: 0, left: -insetAmount, bottom: 0, right: insetAmount)
        self.titleEdgeInsets = UIEdgeInsets(top: 0, left: insetAmount, bottom: 0, right: -insetAmount)
        self.contentEdgeInsets = UIEdgeInsets(top: 0, left: insetAmount, bottom: 0, right: insetAmount)
    }
}
