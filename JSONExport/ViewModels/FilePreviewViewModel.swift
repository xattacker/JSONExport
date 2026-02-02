//
//  FilePreviewViewModel.swift
//  JSONExport
//
//  Created by Claude on 2026/2/2.
//  Copyright © 2026. All rights reserved.
//

import Foundation
import Combine


@MainActor
final class FilePreviewViewModel: ObservableObject, Identifiable {

    let id: UUID = UUID()

    @Published var includeConstructors: Bool {
        didSet {
            self.file.includeConstructors = self.includeConstructors
            self.regenerateFileContent()
        }
    }

    @Published var includeUtilities: Bool {
        didSet {
            self.file.includeUtilities = self.includeUtilities
            self.regenerateFileContent()
        }
    }

    @Published var fileContent: String

    @Published var className: String

    let file: FileRepresenter

    var fileName: String {
        var name = self.className
        name += "."
        if self.file is HeaderFileRepresenter {
            name += self.file.lang.headerFileData.headerFileExtension
        } else {
            name += self.file.lang.fileExtension
        }
        return name
    }

    init(file: FileRepresenter) {
        self.file = file
        self.className = file.className
        self.includeConstructors = file.includeConstructors
        self.includeUtilities = file.includeUtilities
        self.fileContent = file.toString()
    }

    func updateClassName(_ newName: String) {
        self.className = newName
        self.file.className = newName
        self.regenerateFileContent()
    }

    func updateFileContent(_ content: String) {
        self.fileContent = content
        self.file.fileContent = content
    }

    private func regenerateFileContent() {
        self.fileContent = self.file.toString()
    }
}
