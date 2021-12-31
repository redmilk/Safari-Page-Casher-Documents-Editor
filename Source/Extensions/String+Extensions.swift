//
//  String+Extensions.swift
//  AirPrint
//
//  Created by Danyl Timofeyev on 28.12.2021.
//

import Foundation

extension String {

    var withoutTrailingZeros: String {
        return self.replacingOccurrences(of: ",00", with: "")
    }
    
    static func makeStrikeThroughText(_ text: String, size: CGFloat = 12) -> NSMutableAttributedString {
        let attributeString: NSMutableAttributedString = NSMutableAttributedString(string: text)
        attributeString.addAttribute(NSAttributedString.Key.strikethroughStyle, value: 2, range: NSRange(location: 0, length: attributeString.length))
        attributeString.addAttribute(NSAttributedString.Key.font, value: UIFont(name: "Poppins", size: size)!, range: NSRange(location: 0, length: attributeString.length))
        //NSAttributedString.Key.font: UIFont(name: "Chalkduster", size: 18.0)!
        return attributeString
    }
    
    static func makeAttriabutedStringNoFormatting(_ text: String, size: CGFloat = 12) -> NSMutableAttributedString {
        let attributeString: NSMutableAttributedString = NSMutableAttributedString(string: text)
        attributeString.addAttribute(NSAttributedString.Key.font, value: UIFont(name: "Poppins", size: size)!, range: NSRange(location: 0, length: attributeString.length))
        return attributeString
    }
}


