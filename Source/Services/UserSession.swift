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
    
    /// selection mode helper
    var selectedItems: [PrintableDataBox: PrintableDataBox] { get }
    
    /// currently editing file's data
    var editingTempFile: TemporaryFile? { get }
    var editingFileDataBox: PrintableDataBox? { get }
}

final class UserSessionImpl: UserSession {
    enum Action {
        case addItems([PrintableDataBox])
        case deleteItems([PrintableDataBox])
        case populateWithCurrentSessionData
        
        /// selection mode
        case selectItemsToDelete([PrintableDataBox])
        case cancelSelection

        case createTempFileForEditing(withNameAndFormat: String, forDataBox: PrintableDataBox)
        case updateEditedFilesData(newDataBox: PrintableDataBox, oldDataBox: PrintableDataBox)
    }
    
    var input = PassthroughSubject<Action, Never>()
    var output = PassthroughSubject<[PrintableDataBox], Never>()
    
    var sessionResult: [PrintableDataBox] { Array(sessionData.keys).sorted { $0.id < $1.id } }
    var selectedItems: [PrintableDataBox: PrintableDataBox] { _selectedItems }
        
    var editingTempFile: TemporaryFile? { _currentEditingFile }
    var editingFileDataBox: PrintableDataBox? { _editingFileDataBox }
    
    private var bag = Set<AnyCancellable>()
    private var sessionData: [PrintableDataBox: PrintableDataBox] = [:]
    
    private var _selectedItems: [PrintableDataBox: PrintableDataBox] = [:]
    private var _currentEditingFile: TemporaryFile?
    private var _editingFileDataBox: PrintableDataBox?
    
    init() {
        input.sink(receiveValue: { [weak self] action in
            guard let self = self else { return }
            switch action {
            case .addItems(let data):
                data.forEach { self.sessionData[$0] = $0 }
                self.output.send(Array(self.sessionData.keys).sorted { $0.id < $1.id })
            case .deleteItems(let dataBoxList):
                dataBoxList.forEach { self.sessionData[$0] = nil }
            case .createTempFileForEditing(let filename, let dataBox):
                self.createTemporaryFile(withNameAndFormat: filename)
                self._editingFileDataBox = dataBox
            case .updateEditedFilesData(let newDataBox, let oldDataBox):
                self.updateEditedFilesData(newDataBox: newDataBox, oldDataBox: oldDataBox)
                self.deleteTemporaryFile()
                self.output.send(Array(self.sessionData.keys).sorted { $0.id < $1.id })
            case .populateWithCurrentSessionData:
                self.output.send(Array(self.sessionData.keys).sorted { $0.id < $1.id })
            case .selectItemsToDelete(let selectionList):
                selectionList.forEach { self._selectedItems[$0] = $0 }
            case .cancelSelection:
                self._selectedItems.removeAll()
            }
        })
        .store(in: &bag)
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
