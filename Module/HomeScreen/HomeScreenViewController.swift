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
        case empty
    }
    
    @IBOutlet private weak var mainContainer: UIView!
    /// Filled state controls
    @IBOutlet private weak var collectionView: UICollectionView!
    @IBOutlet private weak var layoutChangeButton: UIButton!
    @IBOutlet private weak var plusButtonSmall: UIButton!
    @IBOutlet private weak var deleteButton: UIButton!
    
    /// Empty state controls
    @IBOutlet private weak var emptyStateContainer: UIView!
    @IBOutlet private weak var plusButtonDescriptionContainer: UIStackView!
    @IBOutlet private weak var plusButton: UIButton!
    /// Common state controls
    @IBOutlet private weak var printButton: UIButton!
    @IBOutlet private weak var navigationBarExtenderView: UIView!
    @IBOutlet private weak var settingsButton: UIButton!
    @IBOutlet private weak var logoView: UIView!
    @IBOutlet private weak var bottomBarContainer: UIView!
    
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
    
    private lazy var displayManager = HomeCollectionManager(collectionView: collectionView)
    private var isGridLayout: Bool = true
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
        displayManager.configure()
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
                self?.displayManager.applySnapshot(items: data)
                self?.changeState(hasItems: true)
            case .empty:
                self?.changeState(hasItems: false)
            }
        })
        .store(in: &bag)
    }
    
    private func configureView() {
        Publishers.Merge(plusButton.publisher(), plusButtonSmall.publisher())
            .sink(receiveValue: { [weak self] _ in
            self?.viewModel.input.send(.openMenu)
        })
        .store(in: &bag)
        
        printButton.publisher().sink(receiveValue: { [weak self] _ in
            self?.viewModel.input.send(.didTapPrint)
        })
        .store(in: &bag)
        
        layoutChangeButton.publisher().sink(receiveValue: { [weak self] _ in
            guard let self = self else { return }
            self.isGridLayout.toggle()
            self.isGridLayout ? self.displayManager.layoutCollectionAsGrid() : self.displayManager.layoutCollectionAsFullSizePages()
            let buttonImage = UIImage(named: self.isGridLayout ? "button-layout-grid" : "button-layout-pages")!
            self.layoutChangeButton.setBackgroundImage(buttonImage, for: .normal)
            self.collectionView.reloadData()
        })
        .store(in: &bag)
                
        displayManager.output.sink(receiveValue: { [weak self] action in
            switch action {
            case .didPressCell(let dataBox):
                self?.viewModel.input.send(.openFileEditor(dataBox))
            case .deleteCell(let data):
                self?.viewModel.input.send(.deleteItem(data))
            case _: break
            }
        })
        .store(in: &bag)
        changeState(hasItems: false)
    }
    
    private func changeState(hasItems: Bool) {
        plusButtonSmall.isHidden = !hasItems
        deleteButton.isHidden = !hasItems
        layoutChangeButton.isHidden = !hasItems
        plusButtonSmall.isHidden = !hasItems
        collectionView.isHidden = !hasItems
        emptyStateContainer.isHidden = hasItems
        printButton.isEnabled = hasItems
        bottomBarContainer.backgroundColor = hasItems ? UIColor(hex: 0x1E1D51) : .clear
        ///hasItems ? dashedLineLayer.removeAllAnimations() : dashedLineLayer.add(dashedLineAnimation, forKey: "dashed-line")
    }
    
    private func applyStyling() {
        plusButtonDescriptionContainer.addCornerRadius(8)
        emptyStateContainer.addCornerRadius(StylingConstants.cornerRadiusDefault)
        printButton.addCornerRadius(StylingConstants.cornerRadiusDefault)
        navigationBarExtenderView.addCornerRadius(30)
        navigationBarExtenderView.layer.maskedCorners = [.layerMaxXMaxYCorner, .layerMinXMaxYCorner]
        bottomBarContainer.addCornerRadius(30)
    }
}
