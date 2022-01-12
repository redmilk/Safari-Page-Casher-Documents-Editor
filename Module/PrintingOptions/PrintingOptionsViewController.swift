//
//  
//  PrintingOptionsViewController.swift
//  AirPrint
//
//  Created by Danyl Timofeyev on 26.11.2021.
//
//

import UIKit
import Combine


// MARK: - PrintingOptionsViewController

final class PrintingOptionsViewController: UIViewController, ActivityIndicatorPresentable {
    enum State {
        case loadingState(_ isLoading: Bool)
    }
        
    private let viewModel: PrintingOptionsViewModel
    private var bag = Set<AnyCancellable>()
    
    init(viewModel: PrintingOptionsViewModel) {
        self.viewModel = viewModel
        super.init(nibName: String(describing: PrintingOptionsViewController.self), bundle: nil)
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
        /// entry point
        viewModel.input.send(.showDefaultPrintingDialog)
        overrideUserInterfaceStyle = .dark
    }
}

// MARK: - Internal

private extension PrintingOptionsViewController {
    
    /// Handle ViewModel's states
    func handleStates() {
        viewModel.output.sink(receiveValue: { state in
            switch state {
            case .loadingState(let isLoading):
                isLoading ?
                self.startActivityAnimation() :
                self.stopActivityAnimation()
            }
        })
        .store(in: &bag)
    }
}
