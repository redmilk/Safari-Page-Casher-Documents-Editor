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
    
    // MARK: - Filled state controls
    @IBOutlet private weak var collectionView: UICollectionView!
    // MARK: - Empty state controls
    @IBOutlet private weak var emptyStateContainer: UIView!
    @IBOutlet private weak var giftPanelContainer: UIView!
    @IBOutlet private weak var giftPanelOpenButton: UIButton!
    @IBOutlet private weak var plusButtonContainer: UIView!
    @IBOutlet private weak var plusButtonDescriptionContainer: UIStackView!
    @IBOutlet private weak var plusButton: UIButton!
    // MARK: - Common state controls
    @IBOutlet private weak var printButton: UIButton!
    @IBOutlet private weak var navigationBarExtenderView: UIView!
    @IBOutlet private weak var settingsButton: UIButton!
    @IBOutlet private weak var logoView: UIView!
    
    private lazy var dashedLineLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        let bounds = CGRect(x: 1, y: 1, width: plusButtonContainer.frame.width - 2, height: plusButtonContainer.frame.height - 2)
        layer.path = UIBezierPath(roundedRect: bounds, byRoundingCorners: .allCorners, cornerRadii: CGSize(width: StylingConstants.cornerRadiusDefault, height: StylingConstants.cornerRadiusDefault)).cgPath
        layer.strokeColor = UIColor.black.cgColor
        layer.fillColor = nil
        layer.lineDashPattern = [8, 6]
        plusButtonContainer.layer.addSublayer(layer)
        return layer
    }()
    
    private lazy var dashedLineAnimation: CABasicAnimation = {
        let animation = CABasicAnimation(keyPath: "lineDashPhase")
        animation.fromValue = 0
        animation.toValue = dashedLineLayer.lineDashPattern?.reduce(0) { $0 - $1.intValue } ?? 0
        animation.duration = 2
        animation.repeatCount = .infinity
        animation.isRemovedOnCompletion = false
        return animation
    }()
    
    private lazy var displayManager = HomeCollectionManager(collectionView: collectionView)
    
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
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        dashedLineLayer.add(dashedLineAnimation, forKey: "line")
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
                self?.emptyStateContainer.isHidden = true
                self?.collectionView.isHidden = false
                self?.printButton.isEnabled = true
            case .empty:
                self?.collectionView.isHidden = true
                self?.emptyStateContainer.isHidden = false
                self?.printButton.isEnabled = false
            }
        })
        .store(in: &bag)
    }
    
    private func configureView() {
        plusButton.publisher().sink(receiveValue: { [weak self] _ in
            self?.viewModel.input.send(.openMenu)
        })
        .store(in: &bag)
        
        printButton.publisher().sink(receiveValue: { [weak self] _ in
            self?.viewModel.input.send(.didTapPrint)
        })
        .store(in: &bag)
        
        displayManager.output.sink(receiveValue: { [weak self] action in
            switch action {
            case .didPressCell(let cellConfig):
                self?.resolvePressedCellActionForConfig(cellConfig)
            case .deleteCell(let data):
                self?.viewModel.input.send(.deleteItem(data))
            case _: break
            }
        })
        .store(in: &bag)
    }
    
    private func resolvePressedCellActionForConfig(_ cellConfig: ResultPreviewCollectionCell.Configuration) {
        switch cellConfig {
        case .add: viewModel.input.send(.openMenu)
        case .content(let dataBox): viewModel.input.send(.openFileEditor(dataBox))
        }
    }
    
    private func applyStyling() {
        collectionView.addCornerRadius(StylingConstants.cornerRadiusDefault)
        giftPanelContainer.addCornerRadius(StylingConstants.cornerRadiusDefault)
        giftPanelOpenButton.addCornerRadius(14)
        plusButtonDescriptionContainer.addCornerRadius(8)
        plusButtonContainer.addCornerRadius(StylingConstants.cornerRadiusDefault)
        plusButton.addCornerRadius(38)
        printButton.addCornerRadius(StylingConstants.cornerRadiusDefault)
        navigationBarExtenderView.addCornerRadius(30)
        navigationBarExtenderView.layer.maskedCorners = [.layerMaxXMaxYCorner, .layerMinXMaxYCorner]
        settingsButton.addCornerRadius(20.0)
        logoView.addCornerRadius(25)
    }
}
