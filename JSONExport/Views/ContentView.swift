//
//  ContentView.swift
//  JSONExport
//
//  Created by Claude on 2026/2/2.
//  Copyright © 2026. All rights reserved.
//

import SwiftUI


struct ContentView: View {

    @StateObject private var viewModel = MainViewModel()

    var body: some View {
        VStack(spacing: 0) {
            HSplitView {
                self.leftPanel
                    .frame(minWidth: 300)

                self.rightPanel
                    .frame(minWidth: 400)
            }

            Divider()

            self.bottomBar
        }
        .frame(minWidth: 900, minHeight: 600)
        .focusedSceneValue(\.openJSONHandler) {
            self.viewModel.openJSONFile()
        }
        .focusedSceneValue(\.saveFilesHandler) {
            self.viewModel.saveFiles()
        }
    }

    // MARK: - Left Panel

    private var leftPanel: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Enter json data or")
                    .font(.system(size: 11))

                Button("Open Json File") {
                    self.viewModel.openJSONFile()
                }
                .font(.system(size: 11))

                Spacer()
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)

            CodeEditorView(
                text: self.$viewModel.jsonInput,
                isEditable: true
            )
        }
    }

    // MARK: - Right Panel

    private var rightPanel: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Preview your generated files below")
                    .font(.system(size: 11))

                Spacer()

                Text(self.viewModel.statusMessage.message)
                    .font(.system(size: 11))
                    .foregroundColor(self.viewModel.statusMessage.color)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)

            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(self.viewModel.generatedFiles) { fileViewModel in
                        FilePreviewItemView(
                            fileViewModel: fileViewModel,
                            onRename: { oldName, newName in
                                self.handleRename(
                                    fileViewModel: fileViewModel,
                                    oldName: oldName,
                                    newName: newName
                                )
                            }
                        )
                    }
                }
                .padding(8)
            }
            .background(Color(NSColor.controlBackgroundColor))
        }
    }

    // MARK: - Bottom Bar

    private var bottomBar: some View {
        HStack(spacing: 12) {
            Toggle("Constructors", isOn: self.$viewModel.includeConstructors)
                .toggleStyle(.checkbox)
                .font(.system(size: 11))

            Toggle("Utility methods", isOn: self.$viewModel.includeUtilities)
                .toggleStyle(.checkbox)
                .font(.system(size: 11))

            Spacer()
                .frame(width: 20)

            Text("Root class name")
                .font(.system(size: 11))

            TextField("", text: self.$viewModel.rootClassName)
                .textFieldStyle(.squareBorder)
                .frame(width: 100)
                .font(.system(size: 11))

            Text("Classes prefix")
                .font(.system(size: 11))

            TextField("", text: self.$viewModel.classPrefix)
                .textFieldStyle(.squareBorder)
                .frame(width: 80)
                .font(.system(size: 11))

            if self.viewModel.showParentClassField {
                Text("Parent class")
                    .font(.system(size: 11))

                TextField("", text: self.$viewModel.parentClassName)
                    .textFieldStyle(.squareBorder)
                    .frame(width: 80)
                    .font(.system(size: 11))
            }

            if self.viewModel.showFirstLineField {
                TextField(
                    self.viewModel.firstLineHint,
                    text: self.$viewModel.firstLineStatement
                )
                .textFieldStyle(.squareBorder)
                .frame(width: 100)
                .font(.system(size: 11))
            }

            Spacer()

            Picker("", selection: self.$viewModel.selectedLanguageName) {
                ForEach(self.viewModel.availableLanguages, id: \.self) { lang in
                    Text(lang).tag(lang)
                }
            }
            .pickerStyle(.menu)
            .frame(width: 180)
            .onChange(of: self.viewModel.selectedLanguageName) { _ in
                self.viewModel.onLanguageChanged()
            }

            Button("Save") {
                self.viewModel.saveFiles()
            }
            .disabled(!self.viewModel.canSave)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(NSColor.windowBackgroundColor))
    }

    // MARK: - Helper Methods

    private func handleRename(
        fileViewModel: FilePreviewViewModel,
        oldName: String,
        newName: String
    ) {
        let result = self.viewModel.onClassRenamed(
            file: fileViewModel.file,
            oldName: oldName,
            newName: newName
        )

        switch result {
        case .classDuplicated:
            self.showAlert("Class name was duplicated!")
        case .unsupported:
            self.showAlert("Unsupported Language!")
        case .succeed:
            break
        }
    }

    private func showAlert(_ message: String) {
        let alert = NSAlert()
        alert.messageText = message
        alert.alertStyle = .warning
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
}
