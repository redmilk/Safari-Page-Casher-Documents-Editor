//
//  ResultPreviewCollectionManager.swift
//  AirPrint
//
//  Created by Danyl Timofeyev on 25.11.2021.
//

import Foundation

import Foundation
import UIKit
import Combine

final class ResultPreviewCollectionManager: NSObject, InteractionFeedbackService { /// NSObject for collection delegate
    enum Action {
        case didPressCell(IndexPath)
    }
    
    typealias DataSource = UICollectionViewDiffableDataSource<ResultPreviewSection, ResultPreviewSectionItem>
    typealias Snapshot = NSDiffableDataSourceSnapshot<ResultPreviewSection, ResultPreviewSectionItem>
    
    let output = PassthroughSubject<ResultPreviewCollectionManager.Action, Never>()
    
    private unowned let collectionView: UICollectionView
    private var dataSource: DataSource!
    private var isFirstCellWasAlreadyDisplayed = false

    init(collectionView: UICollectionView) {
        self.collectionView = collectionView
    }
    deinit {
        Logger.log(String(describing: self), type: .deinited)
    }
    
    func configure() {
        collectionView.delegate = self
        collectionView.register(cellClassName: ResultPreviewCollectionCell.self)
        collectionView.isPagingEnabled = true
        collectionView.alwaysBounceVertical = false
        collectionView.showsHorizontalScrollIndicator = false
        dataSource = buildDataSource()
        layoutCollection()
    }
    
    func update(withSections sections: [ResultPreviewSection], withIndexPath indexPath: IndexPath) {
        applySnapshot(sections: sections, withIndexPath: indexPath)
    }
}

// MARK: - Internal
private extension ResultPreviewCollectionManager {
    func applySnapshot(sections: [ResultPreviewSection], withIndexPath indexPath: IndexPath) {
        var newSnapshot = Snapshot()
        newSnapshot.appendSections(sections)
        sections.forEach { newSnapshot.appendItems($0.items, toSection: $0) }
        dataSource?.apply(newSnapshot, animatingDifferences: false)
        collectionView.isPagingEnabled = false
        scrollToItem(withIndexPath: indexPath)
        collectionView.isPagingEnabled = true
    }
    
    func scrollToItem(withIndexPath indexPath: IndexPath) {
        Logger.log(indexPath.section.description + " " + indexPath.row.description, type: .all)
        collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: false)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: { [weak self] in
            self?.isFirstCellWasAlreadyDisplayed = true
        })
    }
    
    func buildDataSource() -> DataSource {
        let dataSource = DataSource(
            collectionView: collectionView,
            cellProvider: { (collectionView, indexPath, item) -> UICollectionViewCell? in
                let cell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: String(describing: ResultPreviewCollectionCell.self),
                    for: indexPath) as? ResultPreviewCollectionCell
                cell?.configure(withModel: item)
                return cell
            })
        return dataSource
    }
    
    func layoutCollection() {
        let layout = UICollectionViewCompositionalLayout(sectionProvider: { (sectionIndex, layoutEnvironment) -> NSCollectionLayoutSection? in
            /// item
            let size = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .fractionalHeight(1))
            let item = NSCollectionLayoutItem(layoutSize: size)
            item.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 64, trailing: 0)
            /// group
            let groupSize = NSCollectionLayoutSize(widthDimension: .absolute(self.collectionView.bounds.width), heightDimension: .absolute(self.collectionView.bounds.height))
            let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitem: item, count: 1)
            /// section
            let section = NSCollectionLayoutSection(group: group)
            section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
            return section
        })
        let config = UICollectionViewCompositionalLayoutConfiguration()
        config.scrollDirection = .horizontal
        layout.configuration = config
        collectionView.collectionViewLayout = layout
    }
}

extension ResultPreviewCollectionManager: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        generateInteractionFeedback()
        output.send(.didPressCell(indexPath))
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard isFirstCellWasAlreadyDisplayed else { return }
        generateInteractionFeedback()
    }
}
