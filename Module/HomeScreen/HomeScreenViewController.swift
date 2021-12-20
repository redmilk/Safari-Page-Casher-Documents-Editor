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

final class HomeScreenViewController: UIViewController, PurchesServiceProvidable {
    enum State {
        case allCurrentData([PrintableDataBox])
        case addedItems([PrintableDataBox])
        case deletedItems([PrintableDataBox])
        case selectedItems([PrintableDataBox])
        
        case selectionCount(Int)
        case selectionMode
        case exitSelectionMode
        case empty
    }
    
    @IBOutlet weak var centerImageView: UIImageView!
    /// Gift menu
    @IBOutlet private weak var mainContainer: UIView!
    @IBOutlet private weak var subscriptionContainer: UIView!
    @IBOutlet private weak var subscriptionMenuContainer: UIView!
    @IBOutlet private weak var subscriptionContinueButton: UIButton!
    @IBOutlet private weak var subscriptionMenuOpenButton: UIButton!
    @IBOutlet private weak var subscriptionDiscountLabel: UILabel!
    @IBOutlet private weak var subscriptionCloseButton: UIButton!
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
    @IBOutlet private weak var giftContentView: UIView!
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
        collectionManager.input.send(.configure)
        viewModel.configureViewModel()
        
        purchases.isActiveSubscription
            .sink(receiveValue: { isActive in
                if let isActive = isActive {
                    print("hasActive subscr")
                    
                } else {
                    print("isActive == nil")
                    
                }
            })
            .store(in: &bag)
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        dashedLineLayer.add(dashedLineAnimation, forKey: "dashed-line")
        viewModel.input.send(.viewDidAppear)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
        viewModel.input.send(.viewDisapear)
    }
}

// MARK: - Internal

private extension HomeScreenViewController {
    
    /// Handle ViewModel's states
    func handleStates() {
        viewModel.output.sink(receiveValue: { [weak self] state in
            switch state {
            case .allCurrentData(let allData):
                self?.collectionManager.input.send(.replaceAllWithItems(allData))
                self?.changeViewStateBasedOnItemsCount(hasItems: true)
            case .addedItems(let addNewItems):
                self?.collectionManager.input.send(.incrementItems(addNewItems))
                self?.changeViewStateBasedOnItemsCount(hasItems: true)
            case .deletedItems(let deletedItems):
                self?.collectionManager.input.send(.removeItems(deletedItems))
            case .selectedItems(let selectedItems):
                self?.selectionModeInfoLabel.text = "Selected items: \(selectedItems.count)"
                self?.collectionManager.input.send(.updateItems(selectedItems))
            case .empty:
                self?.changeViewStateBasedOnItemsCount(hasItems: false)
                self?.deleteButton.isHidden = true
            case .selectionMode:
                self?.collectionManager.input.send(.toggleSelectionMode)
            case .exitSelectionMode:
                self?.collectionManager.input.send(.toggleSelectionMode)
            case .selectionCount(let selectionCount):
                self?.selectionModeInfoLabel.text = "Selected items: \(selectionCount)"
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
        
        settingsButton.publisher().print("SETTINGS").sink(receiveValue: { [weak self] _ in
            self?.viewModel.input.send(.didTapSettings)
        })
            .store(in: &bag)
        
        deleteSelectedButton.publisher().sink(receiveValue: { [weak self] _ in
            self?.setHiddenClarifyDeleteDialog(false)
        })
            .store(in: &bag)
        
        deleteButton.publisher().sink(receiveValue: { [weak self] _ in
            guard let dataBox = self?.collectionManager.currentCenterCellInPagingLayout else { return }
            dataBox.isSelected = true
            self?.setHiddenClarifyDeleteDialog(false)
        })
            .store(in: &bag)
        
        deleteAllButton.publisher().sink(receiveValue: { [weak self] _ in
            self?.viewModel.input.send(.deleteAll)
            self?.setHiddenClarifyDeleteDialog(false)
        })
            .store(in: &bag)
        
        dialogDeleteButton.publisher().sink(receiveValue: { [weak self] _ in
            guard let self = self else { return }
            self.setHiddenClarifyDeleteDialog(true)
            self.viewModel.input.send(.itemsDeleteConfirmed)
            self.changeViewStateBasedOnSelectionMode(isInSelectionMode: false)
            self.collectionManager.input.send(.disableSelectionMode)
        })
            .store(in: &bag)
        
        dialogCancelButton.publisher().sink(receiveValue: { [weak self] _ in
            self?.setHiddenClarifyDeleteDialog(true)
            self?.viewModel.input.send(.itemsDeleteRejected)
            self?.changeViewStateBasedOnSelectionMode(isInSelectionMode: false)
        })
            .store(in: &bag)
        
        layoutChangeButton.publisher().sink(receiveValue: { [weak self] _ in
            self?.collectionManager.input.send(.toggleLayout)
        })
            .store(in: &bag)
        
        subscriptionMenuOpenButton.publisher()
            .sink(receiveValue: { [weak self] _ in
                self?.subscriptionContainer.isHidden.toggle()
                self?.addParticles()
            })
            .store(in: &bag)
        
        subscriptionContinueButton.publisher().sink(receiveValue: { [weak self] _ in
            /// proceed subscription
            self?.subscriptionContainer.isHidden.toggle()
            self?.subscriptionContainer.viewWithTag(1)!.removeFromSuperview()
        })
            .store(in: &bag)
        
        subscriptionCloseButton.publisher()
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] _ in
                self?.subscriptionContainer.isHidden.toggle()
                self?.subscriptionContainer.viewWithTag(1)!.removeFromSuperview()
            })
            .store(in: &bag)
        
        checkmarkButton.publisher().sink(receiveValue: { [weak self] _ in
            self?.collectionManager.input.send(.toggleSelectionMode)
        })
            .store(in: &bag)
        
        closeSelectionModeButton.publisher().sink(receiveValue: { [weak self] _ in
            self?.setHiddenClarifyDeleteDialog(true)
            self?.collectionManager.input.send(.toggleSelectionMode)
            self?.viewModel.input.send(.itemsDeleteRejected)
            self?.changeViewStateBasedOnSelectionMode(isInSelectionMode: false)
        })
            .store(in: &bag)
        
        collectionManager.output.sink(receiveValue: { [weak self] action in
            switch action {
            case .didPressCell(let dataBox):
                self?.viewModel.input.send(.getSelectionCount)
                self?.viewModel.input.send(.didPressCell(dataBox: dataBox))
            case .layoutMode(let isGrid):
                guard let self = self else { return }
                self.deleteButton.isHidden = isGrid
                self.layoutChangeButton.isSelected = isGrid
            case .selectionMode(let isOn):
                self?.changeViewStateBasedOnSelectionMode(isInSelectionMode: isOn)
            case .didSelectCheckmark:
                self?.viewModel.input.send(.getSelectionCount)
            }
        })
            .store(in: &bag)
        
        changeViewStateBasedOnItemsCount(hasItems: false)
        setHiddenClarifyDeleteDialog(true)
        changeViewStateBasedOnSelectionMode(isInSelectionMode: false)
        deleteButton.isHidden = true
        layoutChangeButton.isSelected = true
        subscriptionContainer.isHidden.toggle()
    }
    
    private func makeStrikeThroughText(_ text: String) -> NSMutableAttributedString {
        let attributeString: NSMutableAttributedString = NSMutableAttributedString(string: text)
        attributeString.addAttribute(NSAttributedString.Key.strikethroughStyle, value: 2, range: NSRange(location: 0, length: attributeString.length))
        return attributeString
    }
    
    private func changeViewStateBasedOnItemsCount(hasItems: Bool) {
        plusButtonSmall.isEnabled = hasItems
        checkmarkButton.isEnabled = hasItems
        layoutChangeButton.isHidden = !hasItems
        collectionView.isHidden = !hasItems
        emptyStateContainer.isHidden = hasItems
        printButton.isEnabled = hasItems
        giftContentView.isHidden = hasItems
        ///hasItems ? dashedLineLayer.removeAllAnimations() : dashedLineLayer.add(dashedLineAnimation, forKey: "dashed-line")
    }
    
    private func changeViewStateBasedOnSelectionMode(isInSelectionMode: Bool) {
        deleteButtonsContainer.isHidden = !isInSelectionMode
        plusButtonSmall.isHidden = isInSelectionMode
        printButton.isHidden = isInSelectionMode
        checkmarkButton.isHidden = isInSelectionMode
        selectionModeTopContainer.isHidden = !isInSelectionMode
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
        giftContentView.addCornerRadius(28)
        subscriptionMenuContainer.addCornerRadius(30)
        subscriptionMenuContainer.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMinXMinYCorner]
        subscriptionDiscountLabel.attributedText = makeStrikeThroughText("89.99")
        subscriptionMenuContainer.dropShadow(color: .black, opacity: 0.6, offSet: .zero, radius: 30, scale: true)
        dialogButtonsContainer.dropShadow(color: .black, opacity: 0.6, offSet: .zero, radius: 30, scale: true)
    }
    
    private func addParticles() {
        let emitter = ParticleEmitterView()
        emitter.tag = 1
        emitter.alpha = 0.6
        emitter.isUserInteractionEnabled = false
        emitter.translatesAutoresizingMaskIntoConstraints = false
        subscriptionMenuContainer.insertSubview(emitter, at: 0)
        emitter.topAnchor.constraint(equalTo: subscriptionMenuContainer.topAnchor).isActive = true
        emitter.bottomAnchor.constraint(equalTo: subscriptionMenuContainer.bottomAnchor).isActive = true
        emitter.leadingAnchor.constraint(equalTo: subscriptionMenuContainer.leadingAnchor).isActive = true
        emitter.trailingAnchor.constraint(equalTo: subscriptionMenuContainer.trailingAnchor).isActive = true
    }
}

