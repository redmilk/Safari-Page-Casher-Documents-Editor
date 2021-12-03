//
//  MenuPopup.swift
//  AirPrint
//
//  Created by Danyl Timofeyev on 02.12.2021.
//

import Foundation


final class MenuPopup: UIView {

    @IBOutlet private weak var contentView: UIView!
    @IBOutlet private weak var scanButton: UIButton!
    @IBOutlet private weak var photoButton: UIButton!
    @IBOutlet private weak var printButton: UIButton!
    @IBOutlet private weak var cancelButton: UIButton!
    @IBOutlet private weak var buttonsContainer: UIView!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        customInit()
        applyStyling()
    }
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        customInit()
        applyStyling()
    }
}

// MARK: - Private

private extension MenuPopup {
    
    func customInit() {
        let bundle = Bundle(for: Self.self)
        bundle.loadNibNamed(String(describing: Self.self), owner: self, options: nil)
        addSubview(contentView)
        contentView.frame = bounds
        contentView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
    }
    
    func applyStyling() {
        scanButton.addCornerRadius(StylingConstants.cornerRadiusDefault)
        scanButton.addBorder(1.0, .black)
        printButton.addCornerRadius(StylingConstants.cornerRadiusDefault)
        printButton.addBorder(1.0, .black)
        printButton.addCornerRadius(StylingConstants.cornerRadiusDefault)
        printButton.addBorder(1.0, .black)
        cancelButton.addCornerRadius(StylingConstants.cornerRadiusDefault)
        buttonsContainer.addCornerRadius(StylingConstants.cornerRadiusDefault)
    }
}
