//
//  StatusMessage.swift
//  JSONExport
//
//  Created by Claude on 2026/2/2.
//  Copyright © 2026. All rights reserved.
//

import SwiftUI


enum StatusMessageType {

    case success

    case error

    case none
}


struct StatusMessage: Equatable {

    let message: String

    let type: StatusMessageType

    static let empty = StatusMessage(message: "", type: .none)

    var color: Color {
        switch self.type {
        case .success:
            return .green
        case .error:
            return .red
        case .none:
            return .primary
        }
    }
}
