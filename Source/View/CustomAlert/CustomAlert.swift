//
//  CustomAlert.swift
//  AirPrint
//
//  Created by Danyl Timofeyev on 26.12.2021.
//

import Foundation
import Combine

protocol AlertPresentable: AnyObject {
    func displayAlert(fromParentView view: UIView, with text: String, title: String?, action: VoidClosure?, buttonTitle: String?
    ) -> UIView
}

extension AlertPresentable {
    
    @discardableResult
    func displayAlert(
        fromParentView view: UIView, with text: String, title: String?,
        action: VoidClosure? = nil, buttonTitle: String? = ""
    ) -> UIView {
        if let alreadyPresentedAlert = view.subviews.filter({ $0.tag == 666 }).first {
            alreadyPresentedAlert.removeFromSuperview()
        }
        
        let dimmView = UIView()
        dimmView.tag = 666
        dimmView.backgroundColor = .black.withAlphaComponent(0.7)
        
        let alert = CustomAlert()
        alert.alertText.text = text
        alert.titleLabel.text = title
        if let buttonTitle = buttonTitle {
            alert.primaryButton.setTitle(buttonTitle, for: .normal)
        }
        dimmView.addSubview(alert)
        alert.translatesAutoresizingMaskIntoConstraints = false
        //alert.heightAnchor.constraint(equalToConstant: 150).isActive = true
        alert.bottomAnchor.constraint(equalTo: dimmView.bottomAnchor, constant: 0).isActive = true
        alert.leftAnchor.constraint(equalTo: dimmView.leftAnchor, constant: 0).isActive = true
        alert.rightAnchor.constraint(equalTo: dimmView.rightAnchor, constant: 0).isActive = true
        alert.configureView(dimmedContainer: dimmView)
        
        view.addAndFill(dimmView)
        view.bringSubviewToFront(dimmView)
        
        dimmView.alpha = 0
        alert.transform = CGAffineTransform.identity.translatedBy(x: 0, y: 300)
        UIView.animate(withDuration: 0.4, delay: 0, options: [.curveEaseIn], animations: {
            alert.transform = .identity
            dimmView.alpha = 1.0
        }, completion: nil)        
        return dimmView
    }
}

final class CustomAlert: UIView {
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var mainContainer: UIView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var primaryButton: UIButton!
    @IBOutlet weak var alertText: UILabel!
    
    private weak var dimmedContainer: UIView?
    private var disposable: AnyCancellable?
    private var primaryButtonAction: VoidClosure?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initialSetup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        initialSetup()
    }
    
    // MARK: - Private
    
    private func initialSetup() {
        let bundle = Bundle(for: Self.self)
        bundle.loadNibNamed(String(describing: Self.self), owner: self, options: nil)
        addSubview(contentView)
        contentView.constraintToSides(inside: self)
    }
    
    func configureView(dimmedContainer: UIView) {
        self.dimmedContainer = dimmedContainer
        contentView.layer.masksToBounds = true
        contentView.layer.cornerRadius = 30
        mainContainer.dropShadow(color: .blue, opacity: 0.8, offSet: .zero, radius: 15, scale: true)

       disposable = primaryButton.publisher().sink(receiveValue: { [weak self] _ in
           guard let primaryAction = self?.primaryButtonAction else {
               UIView.animate(withDuration: 0.4, delay: 0, options: [], animations: {
                   let translateY = CGAffineTransform(translationX: 0, y: 300)
                   self?.transform = translateY
                   self?.dimmedContainer?.alpha = 0.0
               }, completion: nil)
               return
           }
           primaryAction()
        })
    }
}
