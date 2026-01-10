//
//  NoodleLineNumberMarker.swift
//  NoodleKit
//
//  Created by Paul Kim on 9/30/08.
//  Copyright (c) 2008 Noodlesoft, LLC. All rights reserved.
//
// Permission is hereby granted, free of charge, to any person
// obtaining a copy of this software and associated documentation
// files (the "Software"), to deal in the Software without
// restriction, including without limitation the rights to use,
// copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the
// Software is furnished to do so, subject to the following
// conditions:
// 
// The above copyright notice and this permission notice shall be
// included in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
// OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
// NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
// HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
// WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
// FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
// OTHER DEALINGS IN THE SOFTWARE.
//

import Cocoa

/*
 Marker for NoodleLineNumberView.
 
 For more details, see the related blog post at:  http://www.noodlesoft.com/blog/2008/10/05/displaying-line-numbers-with-nstextview/
 */

class NoodleLineNumberMarker: NSRulerMarker {
    private var _lineNumber: UInt = 0
    
    init(rulerView: NSRulerView, lineNumber: CGFloat, image: NSImage, imageOrigin: NSPoint) {
        super.init(rulerView: rulerView, markerLocation: 0.0, image: image, imageOrigin: imageOrigin)
        self._lineNumber = UInt(lineNumber)
    }
    
    required init(coder: NSCoder) {
        super.init(coder: coder)
        
        if coder.allowsKeyedCoding {
            if let lineNumberValue = coder.decodeObject(forKey: "line") as? NSNumber {
                _lineNumber = lineNumberValue.uintValue
            }
        } else {
            if let lineNumberValue = coder.decodeObject() as? NSNumber {
                _lineNumber = lineNumberValue.uintValue
            }
        }
    }
    
    var lineNumber: UInt {
        get {
            return _lineNumber
        }
        set {
            _lineNumber = newValue
        }
    }
    
    override func encode(with coder: NSCoder) {
        super.encode(with: coder)
        
        let lineNumberValue = NSNumber(value: _lineNumber)
        
        if coder.allowsKeyedCoding {
            coder.encode(lineNumberValue, forKey: "line")
        } else {
            coder.encode(lineNumberValue)
        }
    }
    
    override func copy(with zone: NSZone? = nil) -> Any {
        let copy = super.copy(with: zone) as! NoodleLineNumberMarker
        copy.lineNumber = _lineNumber
        return copy
    }
}
