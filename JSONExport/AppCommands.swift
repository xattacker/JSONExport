//
//  AppCommands.swift
//  JSONExport
//
//  Created by xattacker on 2026/2/2.
//  Copyright © 2026 Ahmed Ali. All rights reserved.
//

import SwiftUI


extension FocusedValues {
    // Custom entry for an optional binding to a String (e.g., document text)
    @Entry var openJSONHandler: (() -> Void)?
    @Entry var saveFilesHandler: (() -> Void)?
}

struct AppCommands: Commands {
    @FocusedValue(\.openJSONHandler) private var openJSON: (() -> Void)?
    @FocusedValue(\.saveFilesHandler) private var saveFiles: (() -> Void)?

    var body: some Commands {
        CommandGroup(replacing: .newItem) {
            Button("Open JSON File...") {
                openJSON?()
            }
            .keyboardShortcut("o", modifiers: .command)
        }

        CommandGroup(after: .newItem) {
            Divider()

            Button("Save Files...") {
                saveFiles?()
            }
            .keyboardShortcut("s", modifiers: .command)
        }
    }
}
