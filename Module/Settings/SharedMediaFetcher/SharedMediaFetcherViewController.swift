//
//  
//  SharedMediaFetcherViewController.swift
//  AirPrint
//
//  Created by Danyl Timofeyev on 17.12.2021.
//
//

import UIKit
import Combine
import AVKit

// MARK: - SharedMediaFetcherViewController

final class SharedMediaFetcherViewController: UIViewController {
    enum State {
        case dummyState
    }
    
    @IBOutlet weak var imageView: UIImageView!
        
    private let viewModel: SharedMediaFetcherViewModel
    private var bag = Set<AnyCancellable>()
    
    init(viewModel: SharedMediaFetcherViewModel) {
        self.viewModel = viewModel
        super.init(nibName: String(describing: SharedMediaFetcherViewController.self), bundle: nil)
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
        loadAndDisplayMedia(image: false, video: true)

    }
    
    func loadAndDisplayMedia(image: Bool, video: Bool) {
        var defFilePath = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: kGroupPathIdentifier)
        
        if image {
            defFilePath?.appendPathComponent("myNewMedia")
        } else if video {
            defFilePath?.appendPathComponent("myNewMedia.mp4")
        }
        
        if let path = defFilePath?.absoluteString.split(separator: ":")[1].replacingOccurrences(of: "///", with: "/") {
            //Note that for checking if fileExists, we need to get the absolute path in the form /var/public/ ..... and file:///var/public/ .... will not work
            if FileManager().fileExists(atPath: path) {
                print("File exists ...at path \(path)...")
                if image {
                    imageView.image = UIImage(contentsOfFile: path)
                } else if video {
                    self.playVideo(urlString: defFilePath!.absoluteString)
                }
            }
        }
    }
    
    func playVideo(urlString: String) {
        
        guard let url = URL(string: urlString) else {
            return
        }
        print("filepath receving in the form of url string = \(urlString)")
        print("url = \(url)")
        // Create an AVPlayer, passing it the HTTP Live Streaming URL or from saved video
        var player: AVPlayer?
        player = AVPlayer(url: url)

        // Create a new AVPlayerViewController and pass it a reference to the player.
        let controller = AVPlayerViewController()
        controller.player = player

        DispatchQueue.main.async {
            self.present(controller, animated: true) {
                print("playing ......... ")
                player!.play()
            }
        }
    }
}

// MARK: - Internal

private extension SharedMediaFetcherViewController {
    
    /// Handle ViewModel's states
    func handleStates() {
        viewModel.output.sink(receiveValue: { state in
            switch state {
            case .dummyState:
                break
            }
        })
        .store(in: &bag)
    }
}
