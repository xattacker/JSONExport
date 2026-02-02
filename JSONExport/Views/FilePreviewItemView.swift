//
//  FilePreviewItemView.swift
//  JSONExport
//
//  Created by Claude on 2026/2/2.
//  Copyright © 2026. All rights reserved.
//

import SwiftUI


struct FilePreviewItemView: View {

    @ObservedObject var fileViewModel: FilePreviewViewModel

    @State private var showRenameSheet = false

    var onRename: (String, String) -> Void

    var body: some View {
        VStack(spacing: 0) {
            self.headerView

            CodeEditorView(
                text: self.$fileViewModel.fileContent,
                isEditable: true
            )
            .frame(minHeight: 150, maxHeight: 250)
        }
        .background(Color(NSColor.textBackgroundColor))
        .border(Color(NSColor.separatorColor), width: 1)
        .sheet(isPresented: self.$showRenameSheet) {
            RenameClassSheet(
                currentName: self.fileViewModel.className,
                onRename: { newName in
                    let oldName = self.fileViewModel.className
                    self.onRename(oldName, newName)
                }
            )
        }
    }

    private var headerView: some View {
        HStack(spacing: 16) {
            Toggle("Constructors", isOn: self.$fileViewModel.includeConstructors)
                .toggleStyle(.checkbox)
                .font(.system(size: 11))

            Toggle("Utility methods", isOn: self.$fileViewModel.includeUtilities)
                .toggleStyle(.checkbox)
                .font(.system(size: 11))

            Spacer()

            Text(self.fileViewModel.fileName)
                .font(.system(size: 11, weight: .medium))

            Button("Rename") {
                self.showRenameSheet = true
            }
            .font(.system(size: 11))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(Color(NSColor.controlBackgroundColor))
    }
}
