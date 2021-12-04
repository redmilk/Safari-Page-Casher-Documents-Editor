//
//  
//  EditScreenViewController.swift
//  AirPrint
//
//  Created by Danyl Timofeyev on 26.11.2021.
//
//

import UIKit
import Combine


// MARK: - EditScreenViewController

final class EditScreenViewController: UIViewController {
    enum State {
        case dummyState
    }
        
    private let viewModel: EditScreenViewModel
    private var bag = Set<AnyCancellable>()
    
    init(viewModel: EditScreenViewModel) {
        self.viewModel = viewModel
        super.init(nibName: String(describing: EditScreenViewController.self), bundle: nil)
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
    }
}

// MARK: - Internal

private extension EditScreenViewController {
    
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
