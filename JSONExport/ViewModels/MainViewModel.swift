//
//  MainViewModel.swift
//  JSONExport
//
//  Created by Claude on 2026/2/2.
//  Copyright © 2026. All rights reserved.
//

import Foundation
import Combine
import AppKit


@MainActor
final class MainViewModel: ObservableObject {

    // MARK: - State

    @Published var jsonInput: String = ""

    @Published var rootClassName: String = "RootClass"

    @Published var classPrefix: String = ""

    @Published var parentClassName: String = ""

    @Published var firstLineStatement: String = ""

    @Published var includeConstructors: Bool = true

    @Published var includeUtilities: Bool = true

    @Published var selectedLanguageName: String = ""

    @Published var generatedFiles: [FilePreviewViewModel] = []

    @Published var statusMessage: StatusMessage = .empty

    @Published var availableLanguages: [String] = []

    @Published var showFirstLineField: Bool = false

    @Published var showParentClassField: Bool = false

    @Published var firstLineHint: String = ""

    @Published var canSave: Bool = false

    // MARK: - Dependencies

    private let languageService: LanguageServiceProtocol

    private let codeGenerationService: CodeGenerationServiceProtocol

    private let fileExportService: FileExportServiceProtocol

    private var langs: [String: LangModel] = [:]

    private var selectedLang: LangModel?

    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    init(
        languageService: LanguageServiceProtocol = LanguageService(),
        codeGenerationService: CodeGenerationServiceProtocol = CodeGenerationService(),
        fileExportService: FileExportServiceProtocol = FileExportService()
    ) {
        self.languageService = languageService
        self.codeGenerationService = codeGenerationService
        self.fileExportService = fileExportService

        self.loadLanguages()
        self.setupBindings()
    }

    // MARK: - Public Methods

    func openJSONFile() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowsMultipleSelection = false
        panel.allowedContentTypes = [.json]
        panel.prompt = "Choose JSON file"

        if panel.runModal() == .OK, let url = panel.url {
            do {
                let data = try Data(contentsOf: url)
                if let jsonString = String(data: data, encoding: .utf8) {
                    self.jsonInput = jsonString
                    let fileName = url.deletingPathExtension().lastPathComponent
                    self.rootClassName = fileName
                }
            } catch {
                self.showErrorStatus("Failed to read JSON file: \(error.localizedDescription)")
            }
        }
    }

    func saveFiles() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.canCreateDirectories = true
        panel.prompt = "Choose"

        if panel.runModal() == .OK, let url = panel.url {
            guard let lang = self.selectedLang else { return }

            let files = self.generatedFiles.map { $0.file }

            do {
                try self.fileExportService.exportFiles(files, to: url.path, language: lang)
                self.showSuccessNotification()
            } catch {
                self.showErrorStatus("Failed to save files: \(error.localizedDescription)")
            }
        }
    }

    func onLanguageChanged() {
        self.updateUIForSelectedLanguage()
        self.languageService.saveLastSelectedLanguage(self.selectedLanguageName)
        self.generateClasses()
    }

    func onClassRenamed(
        file: FileRepresenter,
        oldName: String,
        newName: String
    ) -> LangRenameResult {
        guard let lang = self.selectedLang else {
            return .unsupported
        }

        let files = self.generatedFiles.map { $0.file }
        let result = lang.handleClassRename(files, oldName: oldName, newName: newName)

        if result == .succeed {
            self.refreshGeneratedFiles()
        }

        return result
    }

    // MARK: - Private Methods

    private func loadLanguages() {
        self.langs = self.languageService.loadSupportedLanguages()
        self.availableLanguages = Array(self.langs.keys).sorted()

        if let lastSelected = self.languageService.loadLastSelectedLanguage(),
           self.langs[lastSelected] != nil {
            self.selectedLanguageName = lastSelected
        } else if let first = self.availableLanguages.first {
            self.selectedLanguageName = first
        }

        self.updateUIForSelectedLanguage()
    }

    private func setupBindings() {
        Publishers.CombineLatest4(
            self.$jsonInput,
            self.$rootClassName,
            self.$classPrefix,
            self.$parentClassName
        )
        .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
        .sink { [weak self] _ in
            self?.generateClasses()
        }
        .store(in: &self.cancellables)

        Publishers.CombineLatest3(
            self.$firstLineStatement,
            self.$includeConstructors,
            self.$includeUtilities
        )
        .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
        .sink { [weak self] _ in
            self?.generateClasses()
        }
        .store(in: &self.cancellables)
    }

    private func updateUIForSelectedLanguage() {
        guard !self.selectedLanguageName.isEmpty else { return }

        self.selectedLang = self.langs[self.selectedLanguageName]

        guard let lang = self.selectedLang else { return }

        self.showFirstLineField = lang.supportsFirstLineStatement ?? false
        self.firstLineHint = lang.firstLineHint ?? ""

        self.showParentClassField = (lang.modelDefinitionWithParent != nil) ||
                                    (lang.headerFileData?.modelDefinitionWithParent != nil)
    }

    private func generateClasses() {
        guard !self.jsonInput.isEmpty else {
            self.generatedFiles = []
            self.canSave = false
            self.statusMessage = .empty
            return
        }

        guard let lang = self.selectedLang else { return }

        var firstLine = ""
        if !self.firstLineStatement.isEmpty {
            firstLine = (lang.firstLinePrefix ?? "") +
                        self.firstLineStatement +
                        (lang.firstLineSuffix ?? "")
        }

        let options = CodeGenerationOptions(
            includeConstructors: self.includeConstructors,
            includeUtilities: self.includeUtilities,
            classPrefix: self.classPrefix,
            parentClassName: self.parentClassName,
            firstLine: firstLine
        )

        do {
            let files = try self.codeGenerationService.generateFiles(
                from: self.jsonInput,
                rootClassName: self.rootClassName,
                language: lang,
                options: options
            )

            self.generatedFiles = files.map { FilePreviewViewModel(file: $0) }
            self.canSave = true
            self.showSuccessStatus("Valid JSON structure")
        } catch CodeGenerationError.emptyInput {
            self.generatedFiles = []
            self.canSave = false
            self.statusMessage = .empty
        } catch {
            self.generatedFiles = []
            self.canSave = false
            self.showErrorStatus("It seems your JSON object is not valid!")
        }
    }

    private func refreshGeneratedFiles() {
        for viewModel in self.generatedFiles {
            viewModel.updateClassName(viewModel.file.className)
        }
    }

    private func showSuccessStatus(_ message: String) {
        self.statusMessage = StatusMessage(message: message, type: .success)
    }

    private func showErrorStatus(_ message: String) {
        self.statusMessage = StatusMessage(message: message, type: .error)
    }

    private func showSuccessNotification() {
        guard let lang = self.selectedLang else { return }

        let notification = NSUserNotification()
        notification.title = "Success!"
        notification.informativeText = "Your \(lang.langName) model files have been generated successfully."
        notification.deliveryDate = Date()

        let center = NSUserNotificationCenter.default
        center.deliver(notification)
    }
}
