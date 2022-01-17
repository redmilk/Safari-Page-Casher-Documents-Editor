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
        case configure
        case replaceAllWithItems([PrintableDataBox])
        case incrementItems([PrintableDataBox])
        case removeItems([PrintableDataBox])
        case updateItems([PrintableDataBox])
        case toggleLayout
        case toggleSelectionMode
        case disableSelectionMode
        case reloadCollection
    }
    
    enum Response {
        case didPressCell(dataBox: PrintableDataBox)
        case layoutMode(isGrid: Bool)
        case selectionMode(isOn: Bool)
        case didSelectCheckmark
    }
    
    typealias DataSource = UICollectionViewDiffableDataSource<ResultPreviewSection, PrintableDataBox>
    typealias Snapshot = NSDiffableDataSourceSnapshot<ResultPreviewSection, PrintableDataBox>
    
    let input = PassthroughSubject<Action, Never>()
    let output = PassthroughSubject<Response, Never>()
    
    // TODO: - refactor to avoid storing these state fields
    private var isGridLayout: Bool = true
    private var isInSelectionMode: Bool = false
    var currentCenterCellInPagingLayout: PrintableDataBox?
    
    private unowned let collectionView: UICollectionView
    private let section = ResultPreviewSection(items: [], title: "Main Section")
    private var dataSource: DataSource!
    private var timerCancellable: AnyCancellable?
    private var bag = Set<AnyCancellable>()

    init(collectionView: UICollectionView) {
        self.collectionView = collectionView
        super.init()
        handleInput()
    }
    deinit {
        Logger.log(String(describing: self), type: .deinited)
    }
    
    private func configure() {
        collectionView.delegate = self
        collectionView.register(cellClassName: ResultPreviewCollectionCell.self)
        collectionView.showsVerticalScrollIndicator = false
        dataSource = buildDataSource()
        layoutCollectionAsGrid()
        startPostingCenterCell()
    }
    
    private func handleInput() {
        input.sink(receiveValue: { [weak self] action in
            guard let self = self else { return }
            switch action {
            case .configure:
                self.configure()
            case .replaceAllWithItems(let items):
                self.replaceAllItemsWithItems(items)
            case .incrementItems(let itemsToIncrement):
                self.incrementItems(itemsToIncrement)
            case .removeItems(let items):
                self.removeItems(items)
            case .updateItems(let items):
                self.reloadItems(items)
            case .toggleLayout:
                self.isGridLayout.toggle()
                self.isGridLayout ? self.layoutCollectionAsGrid() : self.layoutCollectionAsFullSizePages()
                self.collectionView.reloadData()
                self.output.send(.layoutMode(isGrid: self.isGridLayout))
            case .toggleSelectionMode:
                self.isInSelectionMode.toggle()
                if !self.isGridLayout { self.input.send(.toggleLayout) }
                self.collectionView.reloadData()
                self.output.send(.selectionMode(isOn: self.isInSelectionMode))
            case .disableSelectionMode:
                self.isInSelectionMode = false
                self.collectionView.reloadData()
            case .reloadCollection:
                self.collectionView.reloadData()
            }
        })
        .store(in: &bag)
    }

    private func replaceAllItemsWithItems(_ items: [PrintableDataBox]) {
        var snapshot = Snapshot()
        snapshot.appendSections([section])
        snapshot.appendItems(items)
        Logger.log("collection items count: \(items.count)")
        dataSource?.apply(snapshot, animatingDifferences: false)
    }
    
    private func incrementItems(_ items: [PrintableDataBox]) {
        var snapshot = Snapshot()
        snapshot.appendSections([section])
        snapshot.appendItems(items)
        Logger.log("collection items count: \(items.count)")
        dataSource?.apply(snapshot, animatingDifferences: false)
    }
    
    private func removeItems(_ items: [PrintableDataBox]) {
        var currentSnapshot = dataSource.snapshot()
        currentSnapshot.deleteItems(items)
        dataSource?.apply(currentSnapshot, animatingDifferences: true)
    }
    
    private func reloadSection() {
        let currentSnapshot = dataSource.snapshot()
        dataSource?.apply(currentSnapshot, animatingDifferences: false)
    }
    
    private func reloadItems(_ items: [PrintableDataBox]) {
        var currentSnapshot = dataSource.snapshot()
        currentSnapshot.reloadItems(items)
        dataSource?.apply(currentSnapshot, animatingDifferences: true)
    }
    
    private func layoutCollectionAsGrid() {
        let layout = UICollectionViewCompositionalLayout(sectionProvider: { (sectionIndex, layoutEnvironment) -> NSCollectionLayoutSection? in
            /// item
            let size = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .fractionalHeight(1))
            let item = NSCollectionLayoutItem(layoutSize: size)
            item.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
            /// group
            let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(self.collectionView.bounds.height / 2.5))
            let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitem: item, count: 2)
            group.interItemSpacing = .fixed(20)
            group.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20)
            /// section
            let section = NSCollectionLayoutSection(group: group)
            section.interGroupSpacing = 20
            section.contentInsets = NSDirectionalEdgeInsets(top: 20, leading: 0, bottom: 20, trailing: 0)
            return section
        })
        let config = UICollectionViewCompositionalLayoutConfiguration()
        config.scrollDirection = .vertical
        layout.configuration = config
        collectionView.collectionViewLayout = layout
    }
    
    private func layoutCollectionAsFullSizePages() {
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
        guard let cell = collectionView.cellForItem(at: indexPath) as? ResultPreviewCollectionCell,
              let dataBox = cell.dataBox else { return }
        if isInSelectionMode {
            cell.selectionCheckmark.isSelected.toggle()
            dataBox.isSelected.toggle()
            output.send(.didSelectCheckmark)
        } else {
            output.send(.didPressCell(dataBox: dataBox))
        }
    }
}
