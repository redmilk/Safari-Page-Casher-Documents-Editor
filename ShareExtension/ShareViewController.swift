//
//  ShareViewController.swift
//  ShareExtension
//
//  Created by Danyl Timofeyev on 17.12.2021.
//

import UIKit
import Social
import MobileCoreServices

final class ShareViewController: SLComposeServiceViewController {

    override func isContentValid() -> Bool { true }
    private var pdfProcessing: Bool = false
    override func didSelectPost() {
        if let content = extensionContext!.inputItems.first as? NSExtensionItem {
            let contentTypes = [kUTTypeImage, kUTTypePDF, kUTTypeURL, kUTTypeText]
            if let contents = content.attachments {
                for attachment in contents {
                    for contentType in contentTypes {
                        if attachment.hasItemConformingToTypeIdentifier(contentType as String) {
                            attachment.loadItem(forTypeIdentifier: contentType as String, options: nil) { (data, error) in
                                defer { self.extensionContext!.completeRequest(returningItems: nil, completionHandler: nil) }
                                guard error == nil else { return print(error.debugDescription) }
                                guard let dataURL = data as? NSURL,
                                let mediaData = NSData(contentsOf: dataURL as URL),
                                let sharedPath = FileManager.default.containerURL(
                                forSecurityApplicationGroupIdentifier: "group.airprint_path_of_media") else { return }
                                var url: URL?
                                switch contentType {
                                case kUTTypeImage:
                                    url = URL(string: "\(sharedPath)shared-image")!
                                    break
                                case kUTTypePDF:
                                    url = URL(string: "\(sharedPath)shared-pdf.pdf")!
                                    self.pdfProcessing = true
                                    break
                                case kUTTypeURL:
                                    if !self.pdfProcessing {
                                        UserDefaults(suiteName: "group.airprint_path_of_media")?.set(data as? URL, forKey: "shared-url")
                                    } else {
                                        self.pdfProcessing = false
                                    }
                                    return
                                case kUTTypeText:
                                    UserDefaults(suiteName: "group.airprint_path_of_media")?.set(data as? String, forKey: "shared-text")
                                    return
                                case _:
                                    break
                                }
                                
                                do {
                                    guard let url = url else { return }
                                    try mediaData.write(to: url, options: .atomic)
                                    print("✅ saved: \(String(describing: url))")
                                } catch {
                                    print((error as NSError).localizedDescription)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
