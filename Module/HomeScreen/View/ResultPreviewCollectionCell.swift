//
//  ResultPreviewCollectionCell.swift
//  AirPrint
//
//  Created by Danyl Timofeyev on 25.11.2021.
//

import UIKit

final class ResultPreviewCollectionCell: UICollectionViewCell {

    enum Configuration {
        case add
        case content(PrintableDataBox)
    }
    
    @IBOutlet private weak var containerView: UIView!
    @IBOutlet private weak var thumbnailImageView: UIImageView!
    @IBOutlet private weak var plusIconImageView: UIImageView!
    @IBOutlet private weak var deleButton: UIButton!
    
    var deleteButtonDidPress: ((PrintableDataBox) -> Void)?
    var configuration: Configuration!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        containerView.addCornerRadius(12.0)
        deleButton.addCornerRadius(15)
        deleButton.addBorder(1.0, #colorLiteral(red: 0.8374180198, green: 0.8374378085, blue: 0.8374271393, alpha: 1))
        contentView.addCornerRadius(17.0)
    }
    
    func configure(withState state: Configuration) {
        self.configuration = state
        switch state {
        case .add:
            thumbnailImageView.isHidden = true
            deleButton.isHidden = true
            plusIconImageView.isHidden = false
        case .content(let data):
            plusIconImageView.isHidden = true
            thumbnailImageView.isHidden = false
            deleButton.isHidden = false
            thumbnailImageView.image = data.image
        }
    }

    @IBAction private func handleDeletePressed(_ sender: UIButton) {
        guard case .content(let data) = configuration else { return }
        deleteButtonDidPress?(data)
    }
}
