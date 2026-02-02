//
//  RenameClassSheet.swift
//  JSONExport
//
//  Created by Claude on 2026/2/2.
//  Copyright © 2026. All rights reserved.
//

import SwiftUI


struct RenameClassSheet: View {

    @Environment(\.dismiss) private var dismiss

    @State private var newClassName: String

    @State private var errorMessage: String?

    let currentName: String

    let onRename: (String) -> Void

    init(
        currentName: String,
        onRename: @escaping (String) -> Void
    ) {
        self.currentName = currentName
        self.onRename = onRename
        _newClassName = State(initialValue: currentName)
    }

    var body: some View {
        VStack(spacing: 20) {
            Text("Rename Class")
                .font(.headline)

            TextField("Class Name", text: self.$newClassName)
                .textFieldStyle(.roundedBorder)
                .frame(width: 300)

            if let error = self.errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .font(.caption)
            }

            HStack(spacing: 16) {
                Button("Cancel") {
                    self.dismiss()
                }
                .keyboardShortcut(.cancelAction)

                Button("OK") {
                    self.validateAndRename()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(self.newClassName.isEmpty)
            }
        }
        .padding(24)
    }

    private func validateAndRename() {
        let name = self.newClassName.trimmingCharacters(in: .whitespaces)

        guard !name.isEmpty else {
            self.errorMessage = "Class name cannot be empty!"
            return
        }

        guard name.isValidClassName else {
            self.errorMessage = "Class name format invalid!\nIt should begin with uppercase letter and accept letters, digits and _"
            return
        }

        self.onRename(name)
        self.dismiss()
    }
}
