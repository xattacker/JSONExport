//
//  NSObject.swift
//  JSONExport
//
//  Created by xattacker on 2021/4/29.
//  Copyright © 2021 Ahmed Ali. All rights reserved.
//

import Cocoa


extension NSObject
{
    func showAlert(_ message: String)
    {
        let alert = NSAlert()
        alert.messageText = message
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
}
