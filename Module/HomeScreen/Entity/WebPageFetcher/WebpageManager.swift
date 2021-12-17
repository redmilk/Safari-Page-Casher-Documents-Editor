//
//  WebpageDataManager.swift
//  AirPrint
//
//  Created by Danyl Timofeyev on 03.12.2021.
//

import Foundation
import WebKit
import Combine

final class WebpageManager {
    var output: AnyPublisher<[PrintableDataBox], Never> { _output.eraseToAnyPublisher() }
    
    private let _output = PassthroughSubject<[PrintableDataBox], Never>()
    private var subscription: AnyCancellable?
    private var finishCallback: VoidClosure!
    var initialUrlString: String

    init(initialUrlString: String) {
        self.initialUrlString = initialUrlString
    }
    
    func displayWebpage(_ parentController: UIViewController, presentationCallback: @escaping VoidClosure) {
        finishCallback = presentationCallback
        let controller = WebpageViewController(
            initialUrlString: initialUrlString,
            finishCallback: presentationCallback)
        controller.overrideUserInterfaceStyle = .dark
        subscription = controller.output.sink { [weak self] dataBoxList in
            self?._output.send(dataBoxList)
        }
        controller.modalPresentationStyle = .fullScreen
        parentController.present(controller, animated: true, completion: nil)
    }
}
