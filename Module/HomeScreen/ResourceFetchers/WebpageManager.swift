//
//  WebpageDataManager.swift
//  AirPrint
//
//  Created by Danyl Timofeyev on 03.12.2021.
//

import Foundation
import WebKit
import Combine

final class WebpageManager: NSObject {
    var output: AnyPublisher<PrintableDataBox, Never> { _output.eraseToAnyPublisher() }
    private var webView: WKWebView!
    private let _output = PassthroughSubject<PrintableDataBox, Never>()
    private var finishCallback: VoidClosure!

    override init() {
        super.init()
    }
    
    func displayWebpage(_ parentController: UIViewController, presentationCallback: @escaping VoidClosure) {
        finishCallback = presentationCallback
        let controller = UIViewController()
        let webView = WKWebView()
        controller.view.addSubview(webView)
        webView.frame = controller.view.frame
        webView.navigationDelegate = self
        
        parentController.present(controller, animated: true, completion: { [weak self] in
            let url = URL(string: "https://www.hackingwithswift.com")!
            webView.load(URLRequest(url: url))
            webView.allowsBackForwardNavigationGestures = true
        })
    }
}

extension WebpageManager: WKNavigationDelegate {
    
}
