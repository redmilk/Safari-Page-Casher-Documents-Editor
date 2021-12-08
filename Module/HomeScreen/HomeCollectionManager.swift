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
        case didPressCell(PrintableDataBox)
        case deleteCell(PrintableDataBox)
    }
    
    typealias DataSource = UICollectionViewDiffableDataSource<ResultPreviewSection, PrintableDataBox>
    typealias Snapshot = NSDiffableDataSourceSnapshot<ResultPreviewSection, PrintableDataBox>
    
    let output = PassthroughSubject<HomeCollectionManager.Action, Never>()
    
    // TODO: - refactor to avoid storing these state fields
    var isGridLayout: Bool = true
    var isInSelectionMode: Bool = false
    var currentCenterCellInPagingLayout: PrintableDataBox?
    var selectionList: [PrintableDataBox] = []
    
    private unowned let collectionView: UICollectionView
    private var dataSource: DataSource!
    private var timerCancellable: AnyCancellable?

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
        layoutCollectionAsGrid()
        startPostingCenterCell()
    }

    func applySnapshot(items: [PrintableDataBox]) {
        var snapshot = Snapshot()
        let section = ResultPreviewSection(items: [], title: "Main Section")
        snapshot.appendSections([section])
        snapshot.appendItems(items)
        Logger.log("collection items count: \(items.count)")
        dataSource?.apply(snapshot, animatingDifferences: false)
    }
    
    func removeItems(_ items: [PrintableDataBox]) {
        var currentSnapshot = dataSource.snapshot()
        currentSnapshot.deleteItems(items)
        dataSource?.apply(currentSnapshot, animatingDifferences: true)
    }
    
    func reloadSection() {
        let currentSnapshot = dataSource.snapshot()
        dataSource?.apply(currentSnapshot, animatingDifferences: true)
    }
    
    func layoutCollectionAsGrid() {
        let layout = UICollectionViewCompositionalLayout(sectionProvider: { (sectionIndex, layoutEnvironment) -> NSCollectionLayoutSection? in
            /// item
            let size = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .fractionalHeight(1))
            let item = NSCollectionLayoutItem(layoutSize: size)
            item.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
            /// group
            let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(self.collectionView.bounds.height / 2.2))
            let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitem: item, count: 2)
            group.interItemSpacing = .fixed(20)
            group.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 20, bottom: 20, trailing: 20)
            /// section
            let section = NSCollectionLayoutSection(group: group)
            section.contentInsets = NSDirectionalEdgeInsets(top: 20, leading: 0, bottom: 20, trailing: 0)
            return section
        })
        let config = UICollectionViewCompositionalLayoutConfiguration()
        config.scrollDirection = .vertical
        layout.configuration = config
        collectionView.collectionViewLayout = layout
    }
    
    func layoutCollectionAsFullSizePages() {
        let layout = UICollectionViewCompositionalLayout(sectionProvider: { (sectionIndex, layoutEnvironment) -> NSCollectionLayoutSection? in
            /// item
            let size = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .fractionalHeight(1))
            let item = NSCollectionLayoutItem(layoutSize: size)
            /// group
            let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(self.collectionView.bounds.height * 0.8))
            let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitem: item, count: 1)
            group.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20)
            /// section
            let section = NSCollectionLayoutSection(group: group)
            section.interGroupSpacing = 20
            section.contentInsets = NSDirectionalEdgeInsets(top: 20, leading: 0, bottom: 20, trailing: 0)
            section.orthogonalScrollingBehavior = .groupPaging
            return section
        })
        let config = UICollectionViewCompositionalLayoutConfiguration()
        config.scrollDirection = .horizontal
        layout.configuration = config
        collectionView.collectionViewLayout = layout
    }
    
    private func startPostingCenterCell() {
        timerCancellable?.cancel()
        timerCancellable = Timer.publish(every: 0.5, on: .main, in: .common)
            .autoconnect()
            .compactMap { [weak self] _ in self?.getCenterScreenCollectionItem() }
            .removeDuplicates()
            .sink(receiveValue: { [weak self] dataBox in
                print(dataBox.id)
                self?.currentCenterCellInPagingLayout = dataBox
            })
    }
    
    private func getCenterScreenCollectionItem() -> PrintableDataBox? {
        let centerPoint = CGPoint(x: collectionView.bounds.midX, y: collectionView.bounds.midY)
        guard !isGridLayout,
              collectionView.numberOfItems(inSection: 0) > 0,
              let indexPath = collectionView.indexPathForItem(at: centerPoint),
              let cell = collectionView.cellForItem(at: indexPath) as? ResultPreviewCollectionCell,
              let dataBox = cell.dataBox else { return nil }
        return dataBox
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
            cellProvider: { (collectionView, indexPath, dataBox) -> UICollectionViewCell? in
                let cell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: String(describing: ResultPreviewCollectionCell.self),
                    for: indexPath) as? ResultPreviewCollectionCell
                cell?.configure(withDataBox: dataBox, isInSelectionMode: self.isInSelectionMode)
                cell?.dropShadow(color: ColorPalette.backgroundDark, opacity: 1.0, offSet: CGSize(width: -2, height: 2), radius: 5, scale: true)
                return cell
            })
        return dataSource
    }
}

extension HomeCollectionManager: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        generateInteractionFeedback()
        guard let cell = collectionView.cellForItem(at: indexPath) as? ResultPreviewCollectionCell,
              let dataBox = cell.dataBox else { return }
        output.send(.didPressCell(dataBox))
    }
}
