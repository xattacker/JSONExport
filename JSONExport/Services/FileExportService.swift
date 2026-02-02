//
//  FileExportService.swift
//  JSONExport
//
//  Created by Claude on 2026/2/2.
//  Copyright © 2026. All rights reserved.
//

import Foundation


enum FileExportError: Error, Sendable {

    case writeError(Error)

    case noFilesToExport
}


protocol FileExportServiceProtocol {

    func exportFiles(
        _ files: [FileRepresenter],
        to directoryPath: String,
        language: LangModel
    ) throws
}


final class FileExportService: FileExportServiceProtocol {

    init() {}

    func exportFiles(
        _ files: [FileRepresenter],
        to directoryPath: String,
        language: LangModel
    ) throws {
        guard !files.isEmpty else {
            throw FileExportError.noFilesToExport
        }

        for file in files {
            var fileContent = file.fileContent
            if fileContent.isEmpty {
                fileContent = file.toString()
            }

            var fileExtension = language.fileExtension
            if file is HeaderFileRepresenter {
                fileExtension = language.headerFileData.headerFileExtension
            }

            let filePath = "\(directoryPath)/\(file.className).\(fileExtension)"

            do {
                try fileContent.write(toFile: filePath, atomically: false, encoding: .utf8)
            } catch {
                throw FileExportError.writeError(error)
            }
        }
    }
}
