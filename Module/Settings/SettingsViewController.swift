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
import MessageUI
import QuickLook

// MARK: - SettingsViewController

final class SettingsViewController: UIViewController, MFMailComposeViewControllerDelegate, UIGestureRecognizerDelegate {
    enum State {
        case dummyState
    }
    @IBOutlet private weak var navigationBarExtender: UIView!
    @IBOutlet private weak var manageSubscriptionsButton: UIButton!
    @IBOutlet private weak var contactUsButton: UIButton!
    @IBOutlet private weak var privacyPolicyButton: UIButton!
    @IBOutlet private weak var termsOfUseButton: UIButton!
    @IBOutlet private weak var shareButton: UIButton!
    @IBOutlet private weak var bluredEffectView: UIButton!
    
    override var prefersStatusBarHidden: Bool {
        return true
    }

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
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        title = "Settings"
    }
    func mailComposeController(_ controller: MFMailComposeViewController,
                               didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true)
    }
}

// MARK: - Internal

private extension SettingsViewController {
    
    func configureView() {
        let backButton = UIBarButtonItem(
            image: UIImage(named: "settings-navigation-back")!,
            style: .plain,
            target: navigationController,
            action: nil)
        backButton.publisher().sink(receiveValue: { [weak self] _ in
            self?.navigationController?.popViewController(animated: true)
        }).store(in: &bag)
        navigationItem.leftBarButtonItem = backButton
        navigationController?.interactivePopGestureRecognizer?.delegate = self
        
        let textAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white]
        navigationController?.navigationBar.titleTextAttributes = textAttributes
        navigationController?.navigationBar.tintColor = .white
        title = "Settings"
        navigationBarExtender.addCornerRadius(30)
        
        manageSubscriptionsButton.publisher()
            .sink(receiveValue: { [weak self] _ in
                self?.viewModel.input.send(.manageSubscriptions)
            }).store(in: &bag)
        
        contactUsButton.publisher()
            .sink(receiveValue: { [weak self] _ in
                self?.sendEmail()
            }).store(in: &bag)
        
        shareButton.publisher()
            .sink(receiveValue: { [weak self] _ in
                self?.share()
            }).store(in: &bag)
        
        privacyPolicyButton.publisher()
            .sink(receiveValue: { [weak self] _ in
                self?.viewModel.input.send(.privacyPolicy)
            }).store(in: &bag)
        
        termsOfUseButton.publisher()
            .sink(receiveValue: { [weak self] _ in
                self?.viewModel.input.send(.termsOfUse)
            }).store(in: &bag)
    }
    
    /// Handle ViewModel's states
    func handleStates() {
        viewModel.output
            .sink(receiveValue: { state in
                switch state {
                case .dummyState:
                    break
                }
            })
            .store(in: &bag)
    }
    
    func share() {
        let textToShare = "Check out AirPrinter app"
        if let myWebsite = URL(string: "https://apps.apple.com/app/id1596570780") {
            let objectsToShare = [textToShare, myWebsite, UIImage(named: "icon-logo-big")!] as [Any]
            let activityVC = UIActivityViewController(activityItems: objectsToShare, applicationActivities: nil)
            /// Excluded Activities
            activityVC.excludedActivityTypes = [UIActivity.ActivityType.airDrop, UIActivity.ActivityType.addToReadingList]
            self.present(activityVC, animated: true, completion: nil)
        }
    }
    
    func sendEmail() {
        let recipientEmail = "app@smedia.tech"
        let subject = "AirPrint"
        let iosVersion = UIDevice.current.systemVersion
        let deviceName = UIDevice.current.modelName
        let body = "Device: \(deviceName), iOS version: \(iosVersion)\n"
        
        if MFMailComposeViewController.canSendMail() {
            let mail = MFMailComposeViewController()
            mail.mailComposeDelegate = self
            mail.setToRecipients([recipientEmail])
            mail.setSubject(subject)
            mail.setMessageBody(body, isHTML: false)
            present(mail, animated: true)
        } else if let emailUrl = createEmailUrl(to: recipientEmail, subject: subject, body: body) {
            UIApplication.shared.open(emailUrl)
        }
    }
    
    func createEmailUrl(to: String, subject: String, body: String) -> URL? {
        let subjectEncoded = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
        let bodyEncoded = body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
        
        let gmailUrl = URL(string: "googlegmail://co?to=\(to)&subject=\(subjectEncoded)&body=\(bodyEncoded)")
        let outlookUrl = URL(string: "ms-outlook://compose?to=\(to)&subject=\(subjectEncoded)")
        let yahooMail = URL(string: "ymail://mail/compose?to=\(to)&subject=\(subjectEncoded)&body=\(bodyEncoded)")
        let sparkUrl = URL(string: "readdle-spark://compose?recipient=\(to)&subject=\(subjectEncoded)&body=\(bodyEncoded)")
        let defaultUrl = URL(string: "mailto:\(to)?subject=\(subjectEncoded)&body=\(bodyEncoded)")
        
        if let gmailUrl = gmailUrl, UIApplication.shared.canOpenURL(gmailUrl) {
            return gmailUrl
        } else if let outlookUrl = outlookUrl, UIApplication.shared.canOpenURL(outlookUrl) {
            return outlookUrl
        } else if let yahooMail = yahooMail, UIApplication.shared.canOpenURL(yahooMail) {
            return yahooMail
        } else if let sparkUrl = sparkUrl, UIApplication.shared.canOpenURL(sparkUrl) {
            return sparkUrl
        } else {
            return defaultUrl
        }
    }
}
