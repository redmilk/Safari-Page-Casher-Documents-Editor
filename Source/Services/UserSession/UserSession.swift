//
//  File.swift
//  AirPrint
//
//  Created by Danyl Timofeyev on 29.11.2021.
//

import Foundation
import Combine

protocol UserSession {
    var input: PassthroughSubject<UserSessionImpl.Action, Never> { get }
    var output: PassthroughSubject<[PrintableDataBox], Never> { get }
}

final class UserSessionImpl: UserSession {
    enum Action {
        case addItems([PrintableDataBox])
        case deleteItem(PrintableDataBox)
    }
    
    var input = PassthroughSubject<Action, Never>()
    var output = PassthroughSubject<[PrintableDataBox], Never>()
    
    private var bag = Set<AnyCancellable>()
    private var sessionData: [PrintableDataBox: PrintableDataBox] = [:]
    
    init() {
        input.sink(receiveValue: { [weak self] action in
            guard let self = self else { return }
            switch action {
            case .addItems(let data):
                data.forEach { self.sessionData[$0] = $0 }
                self.output.send(Array(self.sessionData.values).sorted { $0.id < $1.id })
                Logger.log(self.sessionData.values.count.description)
            case .deleteItem(let dataElement):
                self.sessionData[dataElement] = nil
                self.output.send(Array(self.sessionData.values).sorted { $0.id < $1.id })
                Logger.log(self.sessionData.values.count.description)
            }
        })
        .store(in: &bag)
    }
}
