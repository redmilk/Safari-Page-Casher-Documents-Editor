//
//  
//  HomeScreenMenuViewController.swift
//  AirPrint
//
//  Created by Danyl Timofeyev on 29.11.2021.
//
//

import UIKit
import Combine


// MARK: - HomeScreenMenuViewController

final class HomeScreenMenuViewController: UIViewController {
    enum State {
        case dummyState
    }
    @IBOutlet weak var scanDocumentButton: UIButton!
    @IBOutlet weak var printPhotoButton: UIButton!
    @IBOutlet weak var printDocumentButton: UIButton!
    @IBOutlet weak var cancelButton: UIButton!
    
    private let viewModel: HomeScreenMenuViewModel
    private var bag = Set<AnyCancellable>()
    
    init(viewModel: HomeScreenMenuViewModel) {
        self.viewModel = viewModel
        super.init(nibName: String(describing: HomeScreenMenuViewController.self), bundle: nil)
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

private extension HomeScreenMenuViewController {
    
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
    
    func applyStyling() {
        scanDocumentButton.addCornerRadius(StylingConstants.cornerRadiusDefault)
        printDocumentButton.addCornerRadius(StylingConstants.cornerRadiusDefault)
        printPhotoButton.addCornerRadius(StylingConstants.cornerRadiusDefault)
        cancelButton.addCornerRadius(StylingConstants.cornerRadiusDefault)
    }
}
