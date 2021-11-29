//
//  ___FILEHEADER___
//

import UIKit
import Combine


// MARK: - ___VARIABLE_productName:identifier___ViewController

final class ___VARIABLE_productName:identifier___ViewController: UIViewController {
    enum State {
        case dummyState
    }
        
    private let viewModel: ___VARIABLE_productName:identifier___ViewModel
    private var bag = Set<AnyCancellable>()
    
    init(viewModel: ___VARIABLE_productName:identifier___ViewModel) {
        self.viewModel = viewModel
        super.init(nibName: String(describing: ___VARIABLE_productName:identifier___ViewController.self), bundle: nil)
        /**
         CONNECT FILE'S OWNER TO SUPERVIEW IN XIB FILE
         CONNECT FILE'S OWNER TO SUPERVIEW IN XIB FILE
         CONNECT FILE'S OWNER TO SUPERVIEW IN XIB FILE
         */
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

// MARK: - Private

private extension ___VARIABLE_productName:identifier___ViewController {
    
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
    
    func configureView() { }
    func applyStyling() { }
}
