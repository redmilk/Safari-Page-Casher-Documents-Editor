//
//  
//  SettingsViewController.swift
//  AirPrint
//
//  Created by Danyl Timofeyev on 26.11.2021.
//
//

import UIKit
import Combine


// MARK: - SettingsViewController

final class SettingsViewController: UIViewController {
    enum State {
        case dummyState
    }
    @IBOutlet private weak var navigationBarExtender: UIView!
    @IBOutlet private weak var manageSubscriptionsButton: UIButton!
    @IBOutlet private weak var contactUsButton: UIButton!
    @IBOutlet private weak var privacyPolicyButton: UIButton!
    @IBOutlet private weak var termsOfUseButton: UIButton!
    @IBOutlet private weak var shareButton: UIButton!
    
    private let viewModel: SettingsViewModel
    private var bag = Set<AnyCancellable>()
    
    init(viewModel: SettingsViewModel) {
        self.viewModel = viewModel
        super.init(nibName: String(describing: SettingsViewController.self), bundle: nil)
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    deinit {
        Logger.log(String(describing: self), type: .deinited)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureView()
        handleStates()
    }
}

// MARK: - Internal

private extension SettingsViewController {
    
    func configureView() {
        let textAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white]
        navigationController?.navigationBar.titleTextAttributes = textAttributes
        navigationController?.navigationBar.tintColor = .white
        title = "Settings"
        navigationBarExtender.addCornerRadius(30)
        navigationBarExtender.dropShadow(color: .black, opacity: 0.6, offSet: .zero, radius: 30, scale: true)
        
        manageSubscriptionsButton.publisher().sink(receiveValue: { [weak self] _ in
            self?.viewModel.input.send(.manageSubscriptions)
        })
        .store(in: &bag)
        contactUsButton.publisher().sink(receiveValue: { [weak self] _ in
            self?.viewModel.input.send(.manageSubscriptions)
        })
        .store(in: &bag)
    }
    
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
}
