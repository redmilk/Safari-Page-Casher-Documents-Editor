//
//  ResultPreviewCollectionCell.swift
//  AirPrint
//
//  Created by Danyl Timofeyev on 25.11.2021.
//

import UIKit

final class ResultPreviewCollectionCell: UICollectionViewCell {
    
    @IBOutlet private weak var containerView: UIView!
    @IBOutlet weak var thumbnailImageView: UIImageView!
    @IBOutlet weak var selectionCheckmark: UIButton!
    
    var dataBox: PrintableDataBox!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        containerView.addCornerRadius(12.0)
        contentView.addCornerRadius(17.0)
    }
        
    func configure(withDataBox dataBox: PrintableDataBox, isInSelectionMode: Bool) {
        self.dataBox = dataBox
        selectionCheckmark.isHidden = !isInSelectionMode
        selectionCheckmark.isSelected = dataBox.isSelected
        thumbnailImageView.image = dataBox.thumbnail ?? dataBox.image
    }
}
