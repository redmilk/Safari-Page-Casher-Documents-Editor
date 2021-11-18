//
//  MarketBoardDisplayManager.swift
//  VIPexample
//
//  Created by Danyl Timofeyev on 12.10.2021.
//

import Combine
import UIKit
import CoreFoundation

// Example for module with table or collection

/*
final class MarketBoardDisplayManager {
    
    typealias DataSource = UICollectionViewDiffableDataSource<MarketBoardSectionModel, SymbolTickerElement>
    typealias Snapshot = NSDiffableDataSourceSnapshot<MarketBoardSectionModel, SymbolTickerElement>
    
    private unowned let collectionView: UICollectionView
    private var dataSource: DataSource!

    init(collectionView: UICollectionView) {
        self.collectionView = collectionView
    }
    deinit {
        Logger.log(String(describing: self), type: .deinited)
    }
    
    func configure() {
        collectionView.register(cellClassName: MarketBoardMainCell.self)
        collectionView.registerHeaderNib(MarketBoardMainHeader.self)
        dataSource = buildDataSource()
        layoutCollection()
    }
    
    func update(withSections sections: [MarketBoardSectionModel]) {
        applySnapshot(sections: sections)
    }
}

// MARK: - Internal

private extension MarketBoardDisplayManager {
    func applySnapshot(sections: [MarketBoardSectionModel]) {
        var newSnapshot = Snapshot()
        newSnapshot.appendSections(sections)
        sections.forEach { newSnapshot.appendItems($0.items, toSection: $0) }
        let runLoopMode = CFRunLoopMode.defaultMode.rawValue
        CFRunLoopPerformBlock(CFRunLoopGetMain(), runLoopMode) { [unowned(unsafe) dataSource] in
            dataSource?.apply(newSnapshot, animatingDifferences: false)
        }
        CFRunLoopWakeUp(CFRunLoopGetMain())
    }
    
    func buildDataSource() -> DataSource {
        let dataSource = DataSource(
            collectionView: collectionView,
            cellProvider: { (collectionView, indexPath, item) -> UICollectionViewCell? in
                let cell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: String(describing: MarketBoardMainCell.self),
                    for: indexPath) as? MarketBoardMainCell
                cell?.configure(withModel: item)
                cell?.backgroundColor = indexPath.row % 2 == 0 ? .black : #colorLiteral(red: 0.1298420429, green: 0.1298461258, blue: 0.1298439503, alpha: 1)
                return cell
            })
        dataSource.supplementaryViewProvider = { [weak dataSource] collectionView, kind, indexPath in
            guard kind == UICollectionView.elementKindSectionHeader, let dataSource = dataSource else { return nil }
            let section = dataSource.snapshot().sectionIdentifiers[indexPath.section]
            let view = collectionView.dequeueReusableSupplementaryView(
                ofKind: kind,
                withReuseIdentifier: String(describing: MarketBoardMainHeader.self),
                for: indexPath) as? MarketBoardMainHeader
            view?.configure(withTitle: section.title)
            return view
        }
        return dataSource
    }
    
    func layoutCollection() {
        let layout = UICollectionViewCompositionalLayout(sectionProvider: { (sectionIndex, layoutEnvironment) -> NSCollectionLayoutSection? in
            let size = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1),
                heightDimension: .absolute(35)
            )
            let item = NSCollectionLayoutItem(layoutSize: size)
            item.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
            let group = NSCollectionLayoutGroup.horizontal(layoutSize: size, subitem: item, count: 1)
            let section = NSCollectionLayoutSection(group: group)
            section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
            section.interGroupSpacing = 0
            /// section header
            let headerFooterSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(80))
            let sectionHeader = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: headerFooterSize, elementKind: UICollectionView.elementKindSectionHeader, alignment: .top)
            section.boundarySupplementaryItems = [sectionHeader]
            return section
        })
        collectionView.collectionViewLayout = layout
    }
}
 
 */
