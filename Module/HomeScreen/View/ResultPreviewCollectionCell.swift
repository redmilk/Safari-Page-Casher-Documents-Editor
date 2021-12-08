//
//  ResultPreviewCollectionCell.swift
//  AirPrint
//
//  Created by Danyl Timofeyev on 25.11.2021.
//

import UIKit

final class ResultPreviewCollectionCell: UICollectionViewCell {
    
    @IBOutlet private weak var containerView: UIView!
    @IBOutlet private weak var thumbnailImageView: UIImageView!
    @IBOutlet private weak var selectionCheckmark: UIButton!
    
    var dataBox: PrintableDataBox!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        containerView.addCornerRadius(12.0)
        selectionCheckmark.addCornerRadius(15)
        selectionCheckmark.addBorder(1.0, #colorLiteral(red: 0.8374180198, green: 0.8374378085, blue: 0.8374271393, alpha: 1))
        contentView.addCornerRadius(17.0)
    }
    
    func configure(withDataBox dataBox: PrintableDataBox, isInSelectionMode: Bool) {
        self.dataBox = dataBox
        selectionCheckmark.isHidden = !isInSelectionMode
        selectionCheckmark.isSelected = dataBox.isSelected
        thumbnailImageView.image = dataBox.image
    }
}
