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

final class HomeCollectionManager: NSObject, InteractionFeedbackService { /// NSObject for collection delegate
    enum Action {
        case didPressCell(ResultPreviewCollectionCell.Configuration)
        case deleteCell(PrintableDataBox)
    }
    
    typealias DataSource = UICollectionViewDiffableDataSource<ResultPreviewSection, PrintableDataBox>
    typealias Snapshot = NSDiffableDataSourceSnapshot<ResultPreviewSection, PrintableDataBox>
    
    let output = PassthroughSubject<HomeCollectionManager.Action, Never>()
    
    private unowned let collectionView: UICollectionView
    private var dataSource: DataSource!

    init(collectionView: UICollectionView) {
        self.collectionView = collectionView
    }
    deinit {
        Logger.log(String(describing: self), type: .deinited)
    }
    
    func configure() {
        collectionView.delegate = self
        collectionView.register(cellClassName: ResultPreviewCollectionCell.self)
        collectionView.showsVerticalScrollIndicator = false
        dataSource = buildDataSource()
        layoutCollection()
    }

    func applySnapshot(items: [PrintableDataBox]) {
        var snapshot = Snapshot()
        let section = ResultPreviewSection(items: [], title: "Main Section")
        let item = PrintableDataBox(id: "1", image: nil, document: nil, isAddButton: true)
        snapshot.appendSections([section])
        snapshot.appendItems([item])
        snapshot.appendItems(items)
        Logger.log("collection items count: \(items.count - 1)")
        dataSource?.apply(snapshot, animatingDifferences: false)
    }
    
}

// MARK: - Internal
private extension HomeCollectionManager {
    
    func scrollToItem(withIndexPath indexPath: IndexPath) {
        Logger.log(indexPath.section.description + " " + indexPath.row.description, type: .all)
        collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: false)
    }
    
    func buildDataSource() -> DataSource {
        let dataSource = DataSource(
            collectionView: collectionView,
            cellProvider: { (collectionView, indexPath, item) -> UICollectionViewCell? in
                let cell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: String(describing: ResultPreviewCollectionCell.self),
                    for: indexPath) as? ResultPreviewCollectionCell
                let cellState = item.isAddButton ? ResultPreviewCollectionCell.Configuration.add : ResultPreviewCollectionCell.Configuration.content(item)
                cell?.configure(withState: cellState)
                cell?.deleteButtonDidPress = { [weak self] item in
                    self?.output.send(.deleteCell(item))
                }
                return cell
            })
        return dataSource
    }
    
    func layoutCollection() {
        let layout = UICollectionViewCompositionalLayout(sectionProvider: { (sectionIndex, layoutEnvironment) -> NSCollectionLayoutSection? in
            /// item
            let size = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .fractionalHeight(1))
            let item = NSCollectionLayoutItem(layoutSize: size)
            item.contentInsets = NSDirectionalEdgeInsets(top: 2, leading: 0, bottom: 2, trailing: 0)
            /// group
            let groupSize = NSCollectionLayoutSize(widthDimension: .absolute(self.collectionView.bounds.width), heightDimension: .absolute(self.collectionView.bounds.height / 3))
            let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitem: item, count: 3)
            group.interItemSpacing = .fixed(4)
            /// section
            let section = NSCollectionLayoutSection(group: group)
            section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
            return section
        })
        let config = UICollectionViewCompositionalLayoutConfiguration()
        config.scrollDirection = .vertical
        layout.configuration = config
        collectionView.collectionViewLayout = layout
    }
}

extension HomeCollectionManager: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        generateInteractionFeedback()
        guard let cell = collectionView.cellForItem(at: indexPath) as? ResultPreviewCollectionCell,
              let cellConfig = cell.configuration else { return }
        output.send(.didPressCell(cellConfig))
    }
}
