//
//  
//  HomeScreenViewController.swift
//  AirPrint
//
//  Created by Danyl Timofeyev on 26.11.2021.
//
//

import UIKit
import Combine

final class HomeScreenViewController: UIViewController {
    enum State {        
        case newCollectionData([PrintableDataBox])
        case selectionMode
        case exitSelectionMode
        case empty
    }
    
    @IBOutlet private weak var mainContainer: UIView!
    /// Filled state controls
    @IBOutlet private weak var collectionView: UICollectionView!
    @IBOutlet private weak var layoutChangeButton: UIButton!
    @IBOutlet private weak var plusButtonSmall: UIButton!
    @IBOutlet private weak var checkmarkButton: UIButton!
    @IBOutlet private weak var deleteButton: UIButton!
    /// Empty state controls
    @IBOutlet private weak var emptyStateContainer: UIView!
    @IBOutlet private weak var plusButtonDescriptionContainer: UIStackView!
    @IBOutlet private weak var plusButton: UIButton!
    /// Common state controls
    @IBOutlet private weak var printButton: UIButton!
    @IBOutlet private weak var navigationBarExtenderView: UIView!
    @IBOutlet private weak var settingsButton: UIButton!
    @IBOutlet private weak var bottomBarContainer: UIView!
    /// Selection mode
    @IBOutlet private weak var deleteButtonsContainer: UIView!
    @IBOutlet private weak var deleteAllButton: UIButton!
    @IBOutlet private weak var deleteSelectedButton: UIButton!
    @IBOutlet private weak var closeSelectionModeButton: UIButton!
    @IBOutlet private weak var selectionModeInfoLabel: UILabel!
    @IBOutlet private weak var selectionModeTopContainer: UIView!
    /// Action clarify dialog
    @IBOutlet private weak var dialogContainer: UIView!
    @IBOutlet private weak var dialogButtonsContainer: UIView!
    @IBOutlet private weak var dialogDeleteButton: UIButton!
    @IBOutlet private weak var dialogCancelButton: UIButton!
    
    private lazy var dashedLineLayer: CAShapeLayer = {
        let bounds = emptyStateContainer.bounds
        let gradient = CAGradientLayer()
        gradient.frame = bounds
        gradient.type = .conic
        gradient.colors = [UIColor(hex: 0x04EEF2).cgColor, UIColor(hex: 0x049FFC).cgColor, UIColor(hex: 0x9848FF).cgColor, UIColor(hex: 0x04EEF2).cgColor]
        let layer = CAShapeLayer()
        layer.path = UIBezierPath(roundedRect: bounds, byRoundingCorners: .allCorners, cornerRadii: CGSize(width: StylingConstants.cornerRadiusDefault, height: StylingConstants.cornerRadiusDefault)).cgPath
        layer.strokeColor = UIColor.black.cgColor
        layer.fillColor = nil
        layer.lineWidth = 5
        layer.lineDashPattern = [4, 7]
        gradient.mask = layer
        emptyStateContainer.layer.addSublayer(gradient)
        return layer
    }()
    
    private lazy var dashedLineAnimation: CABasicAnimation = {
        let animation = CABasicAnimation(keyPath: "lineDashPhase")
        animation.fromValue = 0
        animation.toValue = dashedLineLayer.lineDashPattern?.reduce(0) { $0 - $1.intValue } ?? 0
        animation.duration = 1
        animation.repeatCount = .infinity
        animation.isRemovedOnCompletion = false
        return animation
    }()
    
    private lazy var collectionManager = HomeCollectionManager(collectionView: collectionView)
    private let viewModel: HomeScreenViewModel
    private var bag = Set<AnyCancellable>()
    
    init(viewModel: HomeScreenViewModel) {
        self.viewModel = viewModel
        super.init(nibName: String(describing: HomeScreenViewController.self), bundle: nil)
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    deinit {
        Logger.log(String(describing: self), type: .deinited)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        handleStates()
        configureView()
        applyStyling()
        collectionManager.configure()
        viewModel.configureViewModel()
    
        navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        dashedLineLayer.add(dashedLineAnimation, forKey: "dashed-line")
    }
}

// MARK: - Internal

private extension HomeScreenViewController {
    
    /// Handle ViewModel's states
    func handleStates() {
        viewModel.output.sink(receiveValue: { [weak self] state in
            switch state {
            case .newCollectionData(let data):
                self?.collectionManager.applySnapshot(items: data)
                self?.changeViewStateBasedOnItemsCount(hasItems: true)
            case .empty:
                self?.changeViewStateBasedOnItemsCount(hasItems: false)
            case .selectionMode:
                self?.changeViewStateBasedOnSelectionMode(isInSelectionMode: true)
            case .exitSelectionMode:
                self?.changeViewStateBasedOnSelectionMode(isInSelectionMode: false)
            }
        })
        .store(in: &bag)
    }
    
    func configureView() {
        Publishers.Merge(plusButton.publisher(), plusButtonSmall.publisher())
            .sink(receiveValue: { [weak self] _ in
            self?.viewModel.input.send(.openMenu)
        })
        .store(in: &bag)
        
        printButton.publisher().sink(receiveValue: { [weak self] _ in
            self?.viewModel.input.send(.didTapPrint)
        })
        .store(in: &bag)
        
        deleteButton.publisher().sink(receiveValue: { [weak self] _ in
            guard let dataBox = self?.collectionManager.currentCenterCellInPagingLayout else { return }
            self?.viewModel.deletePendingItems.removeAll()
            self?.viewModel.deletePendingItems.append(dataBox)
            self?.setHiddenClarifyDeleteDialog(false)
        })
        .store(in: &bag)
        
        dialogDeleteButton.publisher().sink(receiveValue: { [weak self] _ in
            guard let self = self else { return }
            self.setHiddenClarifyDeleteDialog(true)
            self.confirmedToDeleteItems(self.viewModel.deletePendingItems)
        })
        .store(in: &bag)
        
        dialogCancelButton.publisher().sink(receiveValue: { [weak self] _ in
            self?.setHiddenClarifyDeleteDialog(true)
            self?.viewModel.deletePendingItems.removeAll()
        })
        .store(in: &bag)
        
        layoutChangeButton.publisher().sink(receiveValue: { [weak self] _ in
            self?.toggleLayoutButton()
        })
        .store(in: &bag)
        
        checkmarkButton.publisher().sink(receiveValue: { [weak self] _ in
            guard let self = self else { return }
            self.collectionManager.isGridLayout ?
            self.viewModel.input.send(.enterSelectionMode) : self.toggleLayoutButton()
        })
        .store(in: &bag)
        
        closeSelectionModeButton.publisher().sink(receiveValue: { [weak self] _ in
            self?.viewModel.input.send(.exitSelectionMode)
        })
        .store(in: &bag)
                
        collectionManager.output.sink(receiveValue: { [weak self] action in
            switch action {
            case .didPressCell(let dataBox):
                self?.viewModel.input.send(.didPressCellWithData(dataBox))
            case .deleteCell(let dataBox):
                self?.viewModel.input.send(.deleteItems([dataBox]))
            case _: break
            }
        })
        .store(in: &bag)
        
        changeViewStateBasedOnItemsCount(hasItems: false)
        setHiddenClarifyDeleteDialog(true)
        changeViewStateBasedOnSelectionMode(isInSelectionMode: false)
    }
    
    private func confirmedToDeleteItems(_ items: [PrintableDataBox]) {
        collectionManager.removeItems(items)
        viewModel.input.send(.deleteItems(items))
    }
    
    private func changeViewStateBasedOnItemsCount(hasItems: Bool) {
        plusButtonSmall.isEnabled = hasItems
        checkmarkButton.isEnabled = hasItems
        layoutChangeButton.isHidden = !hasItems
        collectionView.isHidden = !hasItems
        emptyStateContainer.isHidden = hasItems
        printButton.isEnabled = hasItems
        deleteButton.isHidden = collectionManager.isGridLayout
        ///hasItems ? dashedLineLayer.removeAllAnimations() : dashedLineLayer.add(dashedLineAnimation, forKey: "dashed-line")
    }
    
    private func changeViewStateBasedOnSelectionMode(isInSelectionMode: Bool) {
        deleteButtonsContainer.isHidden = !isInSelectionMode
        plusButtonSmall.isHidden = isInSelectionMode
        printButton.isHidden = isInSelectionMode
        checkmarkButton.isHidden = isInSelectionMode
        collectionManager.isInSelectionMode = isInSelectionMode
        //collectionManager.reloadSection()
        deleteButtonsContainer.isHidden = !isInSelectionMode
        selectionModeTopContainer.isHidden = !isInSelectionMode
    }
    
    private func toggleLayoutButton() {
        collectionManager.isGridLayout.toggle()
        Logger.log("isGridLayout: \(collectionManager.isGridLayout)")
        collectionManager.isGridLayout ? collectionManager.layoutCollectionAsGrid() : collectionManager.layoutCollectionAsFullSizePages()
        layoutChangeButton.isSelected = collectionManager.isGridLayout
        viewModel.input.send(.reloadCollection)
        collectionManager.reloadSection()
    }

    private func setHiddenClarifyDeleteDialog(_ isHidden: Bool) {
        dialogContainer.isHidden = isHidden
    }
    
    private func applyStyling() {
        plusButtonDescriptionContainer.addCornerRadius(8)
        emptyStateContainer.addCornerRadius(StylingConstants.cornerRadiusDefault)
        printButton.addCornerRadius(StylingConstants.cornerRadiusDefault)
        navigationBarExtenderView.addCornerRadius(30)
        navigationBarExtenderView.layer.maskedCorners = [.layerMaxXMaxYCorner, .layerMinXMaxYCorner]
        bottomBarContainer.addCornerRadius(30)
        bottomBarContainer.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMinXMinYCorner]
        dialogButtonsContainer.addCornerRadius(30)
        dialogButtonsContainer.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMinXMinYCorner]
        deleteButtonsContainer.addCornerRadius(30)
        deleteButtonsContainer.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMinXMinYCorner]
    }
}
