//
//  FilePreviewCell.swift
//  JSONExport
//
//  Created by Ahmed on 11/10/14.
//  Copyright (c) 2014 Ahmed Ali. All rights reserved.
//

import Cocoa


protocol FilePreviewCellDelegate: AnyObject
{
    func onClassRenamed(file: FileRepresenter)
}


class FilePreviewCell: NSTableCellView, NSTextViewDelegate {

    weak var delegate: FilePreviewCellDelegate?
    
    @IBOutlet var classNameLabel: NSTextFieldCell!
    @IBOutlet var constructors: NSButton!
    @IBOutlet var utilities: NSButton!
    @IBOutlet var textView: NSTextView!
    @IBOutlet var scrollView: NSScrollView!
    
    // rename class, add by xattacker on 20210428
    @IBOutlet weak var renameButton: NSButton!
    
    // add by xattacker on 20210428
    func setupCell(_ file: FileRepresenter, index: Int)
    {
        self.file = file
      //  self.renameButton.isHidden = index != 0
    }
    
    var file: FileRepresenter!{
        didSet{
            updateCell()
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        if textView != nil{
            textView.delegate = self
            DispatchQueue.main.async {
                self.setupNumberedTextView()
            }
        }
    }
    
    func setupNumberedTextView()
    {
        let lineNumberView = NoodleLineNumberView(scrollView: scrollView)
        scrollView.hasHorizontalRuler = false
        scrollView.hasVerticalRuler = true
        scrollView.verticalRulerView = lineNumberView
        scrollView.rulersVisible = true
        textView.font = NSFont.userFixedPitchFont(ofSize: NSFont.smallSystemFontSize)
    }
    
    @IBAction func toggleConstructors(_ sender: NSButtonCell)
    {
        if file != nil{
            file.includeConstructors = (sender.state == .on)
            textView.string = file.toString()
            
        }
    }
    
    @IBAction func toggleUtilityMethods(_ sender: NSButtonCell)
    {
        if file != nil{
            file.includeUtilities = (sender.state == .on)
            textView.string = file.toString()
        }
    }
    
    // add by xattacker on 20210428
    @IBAction func renameAction(_ sender: NSButtonCell)
    {
        let alert = NSAlert()
        alert.messageText = "Please enter new Class name"
        alert.addButton(withTitle: "OK")
        alert.addButton(withTitle: "Cancel")

        let inputTextField = NSTextField(frame: NSRect(x: 0, y: 0, width: 300, height: 24))
        inputTextField.placeholderString = alert.messageText
        alert.accessoryView = inputTextField
        let response = alert.runModal()
        if response != NSApplication.ModalResponse.alertFirstButtonReturn
        {
            return
        }
        
        let new_name = inputTextField.stringValue
        if new_name.isEmpty
        {
            let alert = NSAlert()
            alert.messageText = "Could not be empty !!"
            alert.addButton(withTitle: "OK")
            alert.runModal()
           
            return
        }
        
        self.file.className = new_name
        //self.updateCell()
        self.delegate?.onClassRenamed(file: self.file)
    }
    
    func textDidChange(_ notification: Notification) {
        file.fileContent = textView.string
    }
    
    private func updateCell()
    {
        if file != nil{
            DispatchQueue.main.async {
                var fileName = self.file.className
                fileName += "."
                if self.file is HeaderFileRepresenter{
                    fileName += self.file.lang.headerFileData.headerFileExtension
                }else{
                    fileName += self.file.lang.fileExtension
                }
                self.classNameLabel.stringValue = fileName
                if(self.textView != nil){
                    self.textView.string = self.file.toString()
                }
                
                if self.file.includeConstructors{
                    self.constructors.state = .on
                }else{
                    self.constructors.state = .off
                }
                if self.file.includeUtilities{
                    self.utilities.state = .on
                }else{
                    self.utilities.state = .off
                }
            }
        }else{
            classNameLabel.stringValue = ""
        }
    }
}
