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
    @IBOutlet weak var buttonsContainerView: UIView!
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
        configureView()
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
    
    func configureView() {
        scanDocumentButton.publisher().sink(receiveValue: { [weak self] _ in
            self?.viewModel.input.send(.scanAction)
        })
        .store(in: &bag)
        printPhotoButton.publisher().sink(receiveValue: { [weak self] _ in
            self?.viewModel.input.send(.printPhoto)
        })
        .store(in: &bag)
        printDocumentButton.publisher().sink(receiveValue: { [weak self] _ in
            self?.viewModel.input.send(.printDocument)
        })
        .store(in: &bag)
        cancelButton.publisher().sink(receiveValue: { [weak self] _ in
            self?.viewModel.input.send(.closeAction)
        })
        .store(in: &bag)
    }
    
    func applyStyling() {
        scanDocumentButton.addCornerRadius(StylingConstants.cornerRadiusDefault)
        scanDocumentButton.addBorder(1.0, .black)
        printDocumentButton.addCornerRadius(StylingConstants.cornerRadiusDefault)
        printDocumentButton.addBorder(1.0, .black)
        printPhotoButton.addCornerRadius(StylingConstants.cornerRadiusDefault)
        printPhotoButton.addBorder(1.0, .black)
        cancelButton.addCornerRadius(StylingConstants.cornerRadiusDefault)
        buttonsContainerView.addCornerRadius(StylingConstants.cornerRadiusDefault)
    }
}
