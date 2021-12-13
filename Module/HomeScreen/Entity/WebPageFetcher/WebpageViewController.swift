//
//  
//  WebpageViewController.swift
//  AirPrint
//
//  Created by Danyl Timofeyev on 04.12.2021.
//
//

import UIKit
import Combine
import WebKit
import PDFKit.PDFDocument

// MARK: - WebpageViewController

final class WebpageViewController: UIViewController, PdfServiceProvidable {
    @IBOutlet private weak var searchBar: UISearchBar!
    @IBOutlet private weak var webView: WKWebView!
    @IBOutlet private weak var printButton: UIButton!
    @IBOutlet private weak var closeButton: UIButton!

    var output: AnyPublisher<[PrintableDataBox], Never> { _output.eraseToAnyPublisher() }

    private let _output = PassthroughSubject<[PrintableDataBox], Never>()
    private var bag = Set<AnyCancellable>()
    private var initialUrlString: String
    private var finishCallback: VoidClosure
    
    /// convert webpage content to pdf helpers
    private let group = DispatchGroup()
    private var webContentSize: CGSize?
    private var dataBoxList: [PrintableDataBox] = []
    
    init(initialUrlString: String, finishCallback: @escaping VoidClosure) {
        self.initialUrlString = initialUrlString
        self.finishCallback = finishCallback
        super.init(nibName: String(describing: WebpageViewController.self), bundle: nil)
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
    }
}

// MARK: - Private

private extension WebpageViewController {
    
    private func configureView() {
        webView.navigationDelegate = self
        webView.uiDelegate = self
        searchBar.delegate = self
        searchBar.autocapitalizationType = .none
        webView.load(URLRequest(url: URL(string: "https://google.com")!))
        
        closeButton.publisher().sink(receiveValue: { [weak self] _ in
            self?.dismiss(animated: true, completion: self?.finishCallback)
        })
        .store(in: &bag)
        printButton.publisher().receive(on: DispatchQueue.main).sink(receiveValue: { [weak self] _ in
            guard let self = self else { return }
            self.makePdfWithWebPageContent()
            self.group.notify(queue: DispatchQueue.main, execute: {
                self._output.send(self.dataBoxList)
                self.dismiss(animated: true, completion: self.finishCallback)
            })
        })
        .store(in: &bag)
    }
    
    /// for cutting page content into separate pdf documents based on web page's content height
    private func makePdfWithWebPageContent() {
        guard let webpageContentSize = self.webContentSize else { return }
        func defineNextPdfPageRectWithContentSize(_ contentSize: CGSize) -> [CGRect] {
            let pageHeight = UIScreen.main.bounds.height
            let pageWidth = UIScreen.main.bounds.width
            let pagesCount = Int((contentSize.height / pageHeight).rounded(.up))
            var result: [CGRect] = []
            for i in 0...pagesCount {
                group.enter()
                result.append(CGRect(x: 0, y: CGFloat(i) * pageHeight, width: pageWidth, height: pageHeight))
            }
            return result
        }
        func makePdfFromWebContent(_ pdfRect: CGRect, completion: @escaping (PrintableDataBox?) -> Void) {
            let config = WKPDFConfiguration()
            config.rect = pdfRect
            self.webView.createPDF(configuration: config) { [weak self] result in
                switch result {
                case .success(let data):
                    guard let pdf = PDFDocument(data: data), let self = self else { return }
                    let dataBox = PrintableDataBox(id: Date().millisecondsSince1970.description, image: self.pdfService.makeImageFromPDFDocument(pdf, withImageSize: pdfRect.size, ofPageIndex: 0), document: pdf)
                completion(dataBox)
                case .failure(let error):
                    Logger.logError(error, descriptions: (error as NSError).localizedDescription)
                    completion(nil)
                }
                self?.group.leave()
            }
        }
        let pageRectList = defineNextPdfPageRectWithContentSize(webpageContentSize)
        pageRectList.forEach {
            makePdfFromWebContent($0, completion: { [weak self] dataBox in
                guard let dataBox = dataBox else { return }
                self?.dataBoxList.append(dataBox)
            })
        }
    }
}

// MARK: - Delegates: WKNavigationDelegate, WKUIDelegate, UISearchBarDelegate

extension WebpageViewController: WKNavigationDelegate, WKUIDelegate, UISearchBarDelegate {
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        guard let searchText = searchBar.text, let url = URL(string: "https://" + searchText) else { return }
        searchBar.resignFirstResponder()
        let req = URLRequest(url: url)
        self.webView.load(req)
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction,
                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if let currentNavigationUrl = navigationAction.request.url?.absoluteString,
           !currentNavigationUrl.contains("blank") {
            searchBar.text = currentNavigationUrl.replacingOccurrences(of: "https://", with: "")
        }
        decisionHandler(.allow)
    }
    
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration,
                 for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        let configuration = WKWebViewConfiguration()
        let config = WKWebViewConfiguration()
        config.dataDetectorTypes = [.all]
        return WKWebView(frame: webView.frame, configuration: configuration)
    }
    
    func webView(_ webView: WKWebView, didReceive challenge: URLAuthenticationChallenge,
                 completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        guard let serverTrust = challenge.protectionSpace.serverTrust else {
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }
        let exceptions = SecTrustCopyExceptions(serverTrust)
        SecTrustSetExceptions(serverTrust, exceptions)
        completionHandler(.useCredential, URLCredential(trust: serverTrust));
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        Logger.log("webView.scrollView.contentSize: \(webView.scrollView.contentSize)")
        webContentSize = webView.scrollView.contentSize
    }
}
