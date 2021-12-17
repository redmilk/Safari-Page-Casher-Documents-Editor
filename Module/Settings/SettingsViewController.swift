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

final class SettingsViewController: UIViewController, MFMailComposeViewControllerDelegate {
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
    
    func mailComposeController(_ controller: MFMailComposeViewController,
                               didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true)
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
        
        manageSubscriptionsButton.publisher()
            .sink(receiveValue: { [weak self] _ in
                self?.viewModel.input.send(.manageSubscriptions)
            })
            .store(in: &bag)
        
        contactUsButton.publisher()
            .sink(receiveValue: { [weak self] _ in
                self?.sendEmail()
            })
            .store(in: &bag)
        
        shareButton.publisher()
            .sink(receiveValue: { [weak self] _ in
                self?.share()
            })
            .store(in: &bag)
        
        privacyPolicyButton.publisher()
            .sink(receiveValue: { [weak self] _ in
                self?.viewModel.input.send(.privacyPolicy)
            })
            .store(in: &bag)
        
        termsOfUseButton.publisher()
            .sink(receiveValue: { [weak self] _ in
                self?.viewModel.input.send(.termsOfUse)
            })
            .store(in: &bag)
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
        UIGraphicsBeginImageContext(view.frame.size)
        view.layer.render(in: UIGraphicsGetCurrentContext()!)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        let textToShare = "Check out AirPrinter app"
        
        if let myWebsite = URL(string: "https://apps.apple.com/us/app/clawee/id1315539131") {
            let objectsToShare = [textToShare, myWebsite, image ?? UIImage(named: "icon-logo")!] as [Any]
            let activityVC = UIActivityViewController(activityItems: objectsToShare, applicationActivities: nil)
            /// Excluded Activities
            activityVC.excludedActivityTypes = [UIActivity.ActivityType.airDrop, UIActivity.ActivityType.addToReadingList]
            
            //activityVC.popoverPresentationController?.sourceView = sender
            self.present(activityVC, animated: true, completion: nil)
        }
    }
    
    func sendEmail() {
        let recipientEmail = "test@gmail.com"
        let subject = "Multi client email support"
        let body = "This code supports sending email via multiple different email apps on iOS! :)"
        
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
