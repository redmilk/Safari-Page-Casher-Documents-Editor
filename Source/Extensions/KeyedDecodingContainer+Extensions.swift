//
//  KeyedDecodingContainer+Extensions.swift
//  VIPexample
//
//  Created by Danyl Timofeyev on 22.10.2021.
//

import Foundation

extension KeyedDecodingContainer {
    func decode<T: Decodable>(key: Key, default: T) -> T {
        (try? decodeIfPresent(T.self, forKey: key)) ?? `default`
    }
}
