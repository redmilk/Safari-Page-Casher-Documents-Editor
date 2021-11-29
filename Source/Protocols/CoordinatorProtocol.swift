//
//  CoordinatorProtocol.swift
//  AirPrint
//
//  Created by Danyl Timofeyev on 18.11.2021.
//

import UIKit.UINavigationController

protocol CoordinatorProtocol: AnyObject {
    var navigationController: UINavigationController? { get set }    
    func start()
    func end()
}
