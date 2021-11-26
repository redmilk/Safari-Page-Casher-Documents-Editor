//
//  ResultPreviewCollectionCell.swift
//  AirPrint
//
//  Created by Danyl Timofeyev on 25.11.2021.
//

import UIKit

final class ResultPreviewCollectionCell: UICollectionViewCell {
    
    @IBOutlet private weak var thumbnailImageView: UIImageView!

    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    func configure(withModel model: ResultPreviewSectionItem) {
        thumbnailImageView.image = model.thumbnail
    }

}
