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
    var output: PassthroughSubject<UserSessionImpl.Response, Never> { get }
    var itemsTotal: Int { get }

    /// user session items storage
    var sessionResult: [PrintableDataBox] { get }
    
    /// currently editing file's data
    var editingTempFile: TemporaryFile? { get }
    var editingFileDataBox: PrintableDataBox? { get }
}

final class UserSessionImpl: UserSession {
    enum Action {
        case addItems([PrintableDataBox])
        case deleteAll
        case deleteSelected
        case cancelSelection
        case getSelectionCount
        case populateWithCurrentSessionData
        case createTempFileForEditing(withNameAndFormat: String, forDataBox: PrintableDataBox)
        case updateEditedFilesData(newDataBox: PrintableDataBox, oldDataBox: PrintableDataBox)
    }
    
    enum Response {
        case addedItems([PrintableDataBox])
        case deletedItems([PrintableDataBox])
        case selectedItems([PrintableDataBox])
        case allCurrentData([PrintableDataBox])
        case selectionCount(Int)
        case empty
    }
    
    var input = PassthroughSubject<Action, Never>()
    var output = PassthroughSubject<Response, Never>()
    
    var sessionResult: [PrintableDataBox] { Array(sessionData.keys).sorted { $0.id < $1.id } }
    var editingTempFile: TemporaryFile? { _currentEditingFile }
    var editingFileDataBox: PrintableDataBox? { _editingFileDataBox }
    var itemsTotal: Int {
        sessionData.count
    }
    
    private var sessionData: [PrintableDataBox: PrintableDataBox] = [:] {
        didSet {
            sessionData.count == 0 ? output.send(.empty) : ()
            //Logger.log("sessionData.count: \(sessionData.count)")
        }
    }
    
    private var _currentEditingFile: TemporaryFile?
    private var _editingFileDataBox: PrintableDataBox?
    private var bag = Set<AnyCancellable>()

    init() {
        input.sink(receiveValue: { [weak self] action in
            guard let self = self else { return }
            switch action {
            case .addItems(let data):
                data.forEach { self.sessionData[$0] = $0 }
                self.output.send(.addedItems(Array(self.sessionData.keys).sorted { $0.id < $1.id }))
            case .deleteAll:
                self.sessionData.keys.forEach { $0.isSelected = true }
                self.output.send(.selectionCount(0))
            case .createTempFileForEditing(let filename, let dataBox):
                self.createTemporaryFile(withNameAndFormat: filename)
                self._editingFileDataBox = dataBox
            case .updateEditedFilesData(let newDataBox, let oldDataBox):
                self.updateEditedFilesData(newDataBox: newDataBox, oldDataBox: oldDataBox)
                self.deleteTemporaryFile()
                self.output.send(.allCurrentData(Array(self.sessionData.keys).sorted { $0.id < $1.id }))
            case .populateWithCurrentSessionData:
                self.output.send(.allCurrentData(Array(self.sessionData.keys).sorted { $0.id < $1.id }))
            case .cancelSelection:
                self.sessionData.keys.forEach { $0.isSelected = false }
                self.output.send(.selectionCount(self.getSelectedCount()))
            case .getSelectionCount:
                self.output.send(.selectionCount(self.getSelectedCount()))
            case .deleteSelected:
                let deleted = self.sessionData.keys.compactMap ({ dataBox -> PrintableDataBox? in
                    if dataBox.isSelected {
                        self.sessionData[dataBox] = nil
                        return dataBox
                    }
                    return nil
                })
                self.output.send(.deletedItems(Array(deleted)))
            }
        })
        .store(in: &bag)
    }
    
    private func getSelectedCount() -> Int {
        sessionData.keys.filter { $0.isSelected }.count
    }
        
    // MARK: - Update file after edit flow
    private func updateEditedFilesData(newDataBox: PrintableDataBox, oldDataBox: PrintableDataBox) {
        sessionData[oldDataBox] = nil
        sessionData[newDataBox] = newDataBox
    }
    /// used for writing the file into temp folder before open with QL
    /// QL requires URL path for the file to edit, remove temp folder after editing
    private func createTemporaryFile(withNameAndFormat filename: String) {
        _currentEditingFile = try! TemporaryFile(creatingTempDirectoryForFilenameWithFormat: filename)
    }
    private func deleteTemporaryFile() {
        try? editingTempFile?.deleteDirectory()
        _currentEditingFile = nil
        _editingFileDataBox = nil
    }
}
