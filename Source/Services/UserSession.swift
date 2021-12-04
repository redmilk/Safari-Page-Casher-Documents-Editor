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
    /// user session items storage
    var sessionResult: [PrintableDataBox] { get }
    /// currently editing file
    var currentEditingFile: TemporaryFile? { get }
}

final class UserSessionImpl: UserSession {
    enum Action {
        case addItems([PrintableDataBox])
        case deleteItem(PrintableDataBox)

        case createTempFileForEditing(withNameAndFormat: String)
        case deleteTempFile
    }
    
    var sessionResult: [PrintableDataBox] {
        Array(sessionData.keys).sorted { $0.id < $1.id }
    }
    
    var input = PassthroughSubject<Action, Never>()
    var output = PassthroughSubject<[PrintableDataBox], Never>()
    var currentEditingFile: TemporaryFile? { _currentEditingFile }
    
    private var bag = Set<AnyCancellable>()
    private var sessionData: [PrintableDataBox: PrintableDataBox] = [:]
    private var _currentEditingFile: TemporaryFile?
    
    init() {
        input.sink(receiveValue: { [weak self] action in
            guard let self = self else { return }
            switch action {
            case .addItems(let data):
                data.forEach { self.sessionData[$0] = $0 }
                self.output.send(Array(self.sessionData.values).sorted { $0.id < $1.id })
            case .deleteItem(let dataElement):
                self.sessionData[dataElement] = nil
                self.output.send(Array(self.sessionData.values).sorted { $0.id < $1.id })
            case .createTempFileForEditing(let filename):
                self.createTemporaryFile(withNameAndFormat: filename)
            case .deleteTempFile:
                self.deleteTemporaryFile()
            }
        })
        .store(in: &bag)
    }
    
    /// used for writing the file into temp folder before open with QL
    /// QL requires URL path for the file to edit, remove temp folder after editing
    private func createTemporaryFile(withNameAndFormat filename: String) {
        _currentEditingFile = try! TemporaryFile(creatingTempDirectoryForFilenameWithFormat: filename)
    }
    private func deleteTemporaryFile() {
        try? currentEditingFile?.deleteDirectory()
        _currentEditingFile = nil
    }
}
