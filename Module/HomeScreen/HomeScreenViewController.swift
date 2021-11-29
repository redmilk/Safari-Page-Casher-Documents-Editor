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
        case shouldDisplayCloudStorage
        case shouldDisplayPhotoAlbum
        case shouldDisplayScanFlow
    }
    
    // MARK: - Filled state controls
    @IBOutlet weak var collectionView: UICollectionView!
    // MARK: - Empty state controls
    @IBOutlet weak var emptyStateContainer: UIView!
    @IBOutlet weak var giftPanelContainer: UIView!
    @IBOutlet weak var giftPanelOpenButton: UIButton!
    @IBOutlet weak var plusButtonContainer: UIView!
    @IBOutlet weak var plusButtonDescriptionContainer: UIStackView!
    @IBOutlet weak var plusButton: UIButton!
    // MARK: - Common state controls
    @IBOutlet weak var bottomButton: UIButton!
    @IBOutlet weak var navigationBarExtenderView: UIView!
    @IBOutlet weak var settingsButton: UIButton!
    @IBOutlet weak var logoView: UIView!
    
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
    private lazy var cameraScaner: CameraScanManager = CameraScanManagerImpl(parentController: self)
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
            case .shouldDisplayScanFlow:
                self?.cameraScaner.displayScanningController()
            case .shouldDisplayCloudStorage:
                break
            case .shouldDisplayPhotoAlbum:
                break
            }
        })
        .store(in: &bag)
    }
    
    private func configureView() {
        plusButton.publisher().sink(receiveValue: { [weak self] _ in
            self?.viewModel.input.send(.openMenu)
        })
        .store(in: &bag)
        
        cameraScaner.output.sink(receiveValue: { [weak self] imageList in
            print("SCANNED IMAGES COUNT")
            print(imageList.count.description)
        })
        .store(in: &bag)
    }
    
    private func applyStyling() {
        collectionView.addCornerRadius(StylingConstants.cornerRadiusDefault)
        giftPanelContainer.addCornerRadius(StylingConstants.cornerRadiusDefault)
        giftPanelOpenButton.addCornerRadius(14)
        plusButtonDescriptionContainer.addCornerRadius(8)
        plusButtonContainer.addCornerRadius(StylingConstants.cornerRadiusDefault)
        plusButton.addCornerRadius(38)
        bottomButton.addCornerRadius(StylingConstants.cornerRadiusDefault)
        navigationBarExtenderView.addCornerRadius(30)
        navigationBarExtenderView.layer.maskedCorners = [.layerMaxXMaxYCorner, .layerMinXMaxYCorner]
        settingsButton.addCornerRadius(20.0)
        logoView.addCornerRadius(25)
    }
}
