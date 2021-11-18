//
//  UICollectionView+Extensions.swift
//  VIPexample
//
//  Created by Danyl Timofeyev on 12.10.2021.
//

import UIKit

extension UICollectionView {
    
    func scrollTo(indexPath: IndexPath, animated: Bool = true) {
        let attributes = collectionViewLayout.layoutAttributesForItem(at: indexPath)!
        setContentOffset(attributes.frame.origin, animated: animated)
    }
    
    // MARK: - Cell
    
    func register<T>(cellClassName name: T.Type) {
        register(UINib(nibName: String(describing: name), bundle: nil),
                 forCellWithReuseIdentifier: String(describing: name))
    }
    
    func dequeueReusableCell<T: UICollectionViewCell>(cellClassTypeName name: T.Type, for indexPath: IndexPath) -> T {
        dequeueReusableCell(withReuseIdentifier: String(describing: name), for: indexPath) as! T
    }
    
    // MARK: - Header
    
    func registerHeaderNib<T: UICollectionReusableView>(_ headerType: T.Type) {
        register(UINib(nibName: String(describing: headerType), bundle: nil),
                 forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
                 withReuseIdentifier: String(describing: headerType))
    }
    
    func registerHeader<T: UICollectionReusableView>(_ headerType: T.Type) {
        register(headerType,
                 forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
                 withReuseIdentifier: String(describing: headerType))
    }
    
    func dequeueHeaderNib<T: UICollectionReusableView>(_ headerType: T.Type, indexPath: IndexPath) -> T {
        dequeueReusableSupplementaryView(
            ofKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: String(describing: headerType),
            for: indexPath) as! T
    }
    
    // MARK: - Footer
    
    func registerFooterNib<T: UICollectionReusableView>(_ footerType: T.Type) {
        register(UINib(nibName: String(describing: footerType), bundle: nil),
                 forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter,
                 withReuseIdentifier: String(describing: footerType))
    }
    
    func registerFooter<T: UICollectionReusableView>(_ footerType: T.Type) {
        register(footerType,
                 forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter,
                 withReuseIdentifier: String(describing: footerType))
    }
    
    func dequeueFooterNib<T: UICollectionReusableView>(_ footerType: T.Type, indexPath: IndexPath) -> T {
        dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionFooter,
                                         withReuseIdentifier: String(describing: T.self),
                                         for: indexPath) as! T
    }
}
