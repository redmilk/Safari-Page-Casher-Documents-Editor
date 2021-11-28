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

fileprivate let defaultCornerRadius: CGFloat = 17

final class HomeScreenViewController: UIViewController {
    enum State {
        case dummyState
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
    @IBOutlet weak var logoImageView: UIImageView!
    
    
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
        applyStyling()
    }
}

// MARK: - Internal

private extension HomeScreenViewController {
    
    /// Handle ViewModel's states
    func handleStates() {
        viewModel.output.sink(receiveValue: { [weak self] state in
            switch state {
            case .dummyState:
                break
            }
        })
        .store(in: &bag)
    }
    
    private func applyStyling() {
        collectionView.addCornerRadius(defaultCornerRadius)
        giftPanelContainer.addCornerRadius(defaultCornerRadius)
        giftPanelOpenButton.addCornerRadius(14)
        plusButtonDescriptionContainer.addCornerRadius(8)
        plusButtonContainer.addCornerRadius(defaultCornerRadius)
        plusButton.addCornerRadius(38)
        bottomButton.addCornerRadius(defaultCornerRadius)
        navigationBarExtenderView.addCornerRadius(26)
        navigationBarExtenderView.layer.maskedCorners = [.layerMaxXMaxYCorner, .layerMinXMaxYCorner]
        settingsButton.addCornerRadius(20.0)
        logoImageView.addCornerRadius(25)
    }
}
