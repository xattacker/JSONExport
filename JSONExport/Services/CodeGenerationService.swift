//
//  CodeGenerationService.swift
//  JSONExport
//
//  Created by Claude on 2026/2/2.
//  Copyright © 2026. All rights reserved.
//

import Foundation


struct CodeGenerationOptions: Sendable {

    var includeConstructors: Bool = true

    var includeUtilities: Bool = true

    var classPrefix: String = ""

    var parentClassName: String = ""

    var firstLine: String = ""
}


enum CodeGenerationError: Error, Sendable {

    case emptyInput

    case invalidJSON

    case parsingFailed(Error)
}


protocol CodeGenerationServiceProtocol {

    @MainActor
    func generateFiles(
        from jsonString: String,
        rootClassName: String,
        language: LangModel,
        options: CodeGenerationOptions
    ) throws -> [FileRepresenter]
}


final class CodeGenerationService: CodeGenerationServiceProtocol {

    init() {}

    @MainActor
    func generateFiles(
        from jsonString: String,
        rootClassName: String,
        language: LangModel,
        options: CodeGenerationOptions
    ) throws -> [FileRepresenter] {
        guard !jsonString.isEmpty else {
            throw CodeGenerationError.emptyInput
        }

        let cleanedStr = stringByRemovingControlCharacters(jsonString)

        guard let data = cleanedStr.data(using: .utf8) else {
            throw CodeGenerationError.invalidJSON
        }

        let jsonData: Any
        do {
            jsonData = try JSONSerialization.jsonObject(with: data, options: [])
        } catch {
            throw CodeGenerationError.parsingFailed(error)
        }

        let json: NSDictionary
        if let dict = jsonData as? NSDictionary {
            json = dict
        } else if let array = jsonData as? NSArray {
            json = unionDictionaryFromArrayElements(array)
        } else {
            throw CodeGenerationError.invalidJSON
        }

        var files = [FileRepresenter]()
        var rootName = rootClassName.isEmpty ? "RootClass" : rootClassName

        let filesBuilder = FilesContentBuilder.shared
        filesBuilder.includeConstructors = options.includeConstructors
        filesBuilder.includeUtilities = options.includeUtilities
        filesBuilder.classPrefix = options.classPrefix
        filesBuilder.parentClassName = options.parentClassName
        filesBuilder.firstLine = options.firstLine
        filesBuilder.lang = language

        filesBuilder.addFileWithName(&rootName, jsonObject: json, files: &files)
        filesBuilder.fixReferenceMismatches(inFiles: files)

        return Array(files.reversed())
    }
}
