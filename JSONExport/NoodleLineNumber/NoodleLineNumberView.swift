//
//  NoodleLineNumberView.swift
//  NoodleKit
//
//  Created by Paul Kim on 9/28/08.
//  Copyright (c) 2008-2012 Noodlesoft, LLC. All rights reserved.
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
 Displays line numbers for an NSTextView.
 
 For more details, see the related blog post at:  http://www.noodlesoft.com/blog/2008/10/05/displaying-line-numbers-with-nstextview/
 */

private let DEFAULT_THICKNESS: CGFloat = 22.0
private let RULER_MARGIN: CGFloat = 5.0

class NoodleLineNumberView: NSRulerView {
    // Array of character indices for the beginning of each line
    private var _lineIndices: NSMutableArray = NSMutableArray()
    // When text is edited, this is the start of the editing region. All line calculations after this point are invalid
    // and need to be recalculated.
    private var _invalidCharacterIndex: UInt = UInt.max
    
    // Maps line numbers to markers
    private var _linesToMarkers: NSMutableDictionary = NSMutableDictionary()
    
    @objc var font: NSFont? {
        didSet {
            setNeedsDisplay(bounds)
        }
    }
    
    @objc var textColor: NSColor? {
        didSet {
            setNeedsDisplay(bounds)
        }
    }
    
    @objc var alternateTextColor: NSColor? {
        didSet {
            setNeedsDisplay(bounds)
        }
    }
    
    @objc var backgroundColor: NSColor? {
        didSet {
            setNeedsDisplay(bounds)
        }
    }
    
    init(scrollView: NSScrollView) {
        super.init(scrollView: scrollView, orientation: .verticalRuler)
        _lineIndices = NSMutableArray()
        _linesToMarkers = NSMutableDictionary()
        clientView = scrollView.documentView
    }
    
    required init(coder: NSCoder) {
        super.init(coder: coder)
        _lineIndices = NSMutableArray()
        _linesToMarkers = NSMutableDictionary()
        
        if coder.allowsKeyedCoding {
            font = coder.decodeObject(forKey: "font") as? NSFont
            textColor = coder.decodeObject(forKey: "textColor") as? NSColor
            alternateTextColor = coder.decodeObject(forKey: "alternateTextColor") as? NSColor
            backgroundColor = coder.decodeObject(forKey: "backgroundColor") as? NSColor
        } else {
            font = coder.decodeObject() as? NSFont
            textColor = coder.decodeObject() as? NSColor
            alternateTextColor = coder.decodeObject() as? NSColor
            backgroundColor = coder.decodeObject() as? NSColor
        }
        
        clientView = scrollView?.documentView
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        _lineIndices = NSMutableArray()
        _linesToMarkers = NSMutableDictionary()
        clientView = scrollView?.documentView
    }
    
    private func defaultFont() -> NSFont {
        return NSFont.labelFont(ofSize: NSFont.systemFontSize(for: .mini))
    }
    
    private func defaultTextColor() -> NSColor {
        return NSColor(calibratedWhite: 0.42, alpha: 1.0)
    }
    
    private func defaultAlternateTextColor() -> NSColor {
        return NSColor.white
    }
    
    override var clientView: NSView? {
        didSet {
            let oldClientView = oldValue
            
            if let oldTextView = oldClientView as? NSTextView {
                NotificationCenter.default.removeObserver(
                    self,
                    name: NSTextStorage.didProcessEditingNotification,
                    object: oldTextView.textStorage
                )
            }
            
            super.clientView = clientView
            
            if let textView = clientView as? NSTextView {
                NotificationCenter.default.addObserver(
                    self,
                    selector: #selector(textStorageDidProcessEditing(_:)),
                    name: NSTextStorage.didProcessEditingNotification,
                    object: textView.textStorage
                )
                
                invalidateLineIndicesFromCharacterIndex(0)
            }
        }
    }
    
    private var lineIndices: NSMutableArray {
        if _invalidCharacterIndex < UInt.max {
            calculateLines()
        }
        return _lineIndices
    }
    
    // Forces recalculation of line indicies starting from the given index
    private func invalidateLineIndicesFromCharacterIndex(_ charIndex: UInt) {
        _invalidCharacterIndex = min(charIndex, _invalidCharacterIndex)
    }
    
    @objc override func textStorageDidProcessEditing(_ notification: Notification) {
        guard let storage = notification.object as? NSTextStorage else { return }
        
        // Invalidate the line indices. They will be recalculated and re-cached on demand.
        let range = storage.editedRange
        if range.location != NSNotFound {
            invalidateLineIndicesFromCharacterIndex(UInt(range.location))
            setNeedsDisplay(bounds)
        }
    }
    
    private func calculateLines() {
        guard let view = clientView as? NSTextView else { return }
        
        let text = view.string
        let stringLength = (text as NSString).length
        let count = _lineIndices.count
        
        var charIndex: UInt = 0
        var lineIndex = Int(lineNumberForCharacterIndex(_invalidCharacterIndex, inText: text))
        if count > 0 {
            if let charIndexValue = _lineIndices.object(at: lineIndex) as? NSNumber {
                charIndex = charIndexValue.uintValue
            }
        }
        
        repeat {
            let charIndexValue = NSNumber(value: charIndex)
            if lineIndex < count {
                _lineIndices.replaceObject(at: lineIndex, with: charIndexValue)
            } else {
                _lineIndices.add(charIndexValue)
            }
            
            let lineRange = (text as NSString).lineRange(for: NSRange(location: Int(charIndex), length: 0))
            charIndex = UInt(NSMaxRange(lineRange))
            lineIndex += 1
        } while charIndex < stringLength
        
        if lineIndex < count {
            let range = NSRange(location: lineIndex, length: count - lineIndex)
            _lineIndices.removeObjects(in: range)
        }
        _invalidCharacterIndex = UInt.max
        
        // Check if text ends with a new line.
        if let lastObject = _lineIndices.lastObject as? NSNumber {
            var lineEnd: Int = 0
            var contentEnd: Int = 0
            (text as NSString).getLineStart(nil, end: &lineEnd, contentsEnd: &contentEnd, for: NSRange(location: lastObject.intValue, length: 0))
            if contentEnd < lineEnd {
                _lineIndices.add(NSNumber(value: charIndex))
            }
        }
        
        // See if we need to adjust the width of the view
        let oldThickness = ruleThickness
        let newThickness = requiredThickness
        if abs(oldThickness - newThickness) > 1 {
            // Not a good idea to resize the view during calculations (which can happen during
            // display). Do a delayed perform.
            perform(#selector(setRuleThicknessDelayed(_:)), with: NSNumber(value: Double(newThickness)), afterDelay: 0.0)
        }
    }
    
    @objc private func setRuleThicknessDelayed(_ thickness: NSNumber) {
        ruleThickness = CGFloat(thickness.doubleValue)
    }
    
    private func lineNumberForCharacterIndex(_ charIndex: UInt, inText text: String) -> UInt {
        var left: UInt = 0
        var right: UInt
        var mid: UInt
        var lineStart: UInt
        
        let lines: NSMutableArray
        if _invalidCharacterIndex < UInt.max {
            // We do not want to risk calculating the indices again since we are probably doing it right now, thus
            // possibly causing an infinite loop.
            lines = _lineIndices
        } else {
            lines = self.lineIndices
        }
        
        // Binary search
        right = UInt(lines.count)
        
        while (right - left) > 1 {
            mid = (right + left) / 2
            if let lineStartValue = lines.object(at: Int(mid)) as? NSNumber {
                lineStart = lineStartValue.uintValue
            } else {
                break
            }
            
            if charIndex < lineStart {
                right = mid
            } else if charIndex > lineStart {
                left = mid
            } else {
                return mid
            }
        }
        return left
    }
    
    private func textAttributes() -> [NSAttributedString.Key: Any] {
        let font = self.font ?? defaultFont()
        let color = self.textColor ?? defaultTextColor()
        
        return [
            .font: font,
            .foregroundColor: color
        ]
    }
    
    private func markerTextAttributes() -> [NSAttributedString.Key: Any] {
        let font = self.font ?? defaultFont()
        let color = self.alternateTextColor ?? defaultAlternateTextColor()
        
        return [
            .font: font,
            .foregroundColor: color
        ]
    }
    
    override var requiredThickness: CGFloat {
        let lineCount = lineIndices.count
        var digits: UInt = 1
        if lineCount > 0 {
            digits = UInt(log10(Double(lineCount))) + 1
        }
        
        var sampleString = ""
        for _ in 0..<digits {
            // Use "8" since it is one of the fatter numbers. Anything but "1"
            // will probably be ok here. I could be pedantic and actually find the fattest
            // number for the current font but nah.
            sampleString += "8"
        }
        
        let stringSize = sampleString.size(withAttributes: textAttributes())
        
        // Round up the value. There is a bug on 10.4 where the display gets all wonky when scrolling if you don't
        // return an integral value here.
        return ceil(max(DEFAULT_THICKNESS, stringSize.width + RULER_MARGIN * 2))
    }
    
    override func drawHashMarksAndLabels(in rect: NSRect) {
        let bounds = self.bounds
        
        if let bgColor = backgroundColor {
            bgColor.set()
            bounds.fill()
            
            NSColor(calibratedWhite: 0.58, alpha: 1.0).set()
            let path = NSBezierPath()
            path.move(to: NSPoint(x: bounds.maxX - 0.5, y: bounds.minY))
            path.line(to: NSPoint(x: bounds.maxX - 0.5, y: bounds.maxY))
            path.stroke()
        }
        
        guard let view = clientView as? NSTextView else { return }
        
        let layoutManager = view.layoutManager!
        let container = view.textContainer!
        let text = view.string
        let nullRange = NSRange(location: NSNotFound, length: 0)
        
        let yinset = view.textContainerInset.height
        let visibleRect = scrollView!.contentView.bounds
        
        let textAttributes = self.textAttributes()
        
        let lines = self.lineIndices
        
        // Find the characters that are currently visible
        let glyphRange = layoutManager.glyphRange(forBoundingRect: visibleRect, in: container)
        var range = layoutManager.characterRange(forGlyphRange: glyphRange, actualGlyphRange: nil)
        
        // Fudge the range a tad in case there is an extra new line at end.
        // It doesn't show up in the glyphs so would not be accounted for.
        range.length += 1
        
        let count = lines.count
        
        var line = Int(lineNumberForCharacterIndex(UInt(range.location), inText: text))
        while line < count {
            guard let indexValue = lines.object(at: line) as? NSNumber else {
                line += 1
                continue
            }
            let index = indexValue.uintValue
            
            if NSLocationInRange(Int(index), range) {
                var rectCount: Int = 0
                let rects = layoutManager.rectArray(
                    forCharacterRange: NSRange(location: Int(index), length: 0),
                    withinSelectedCharacterRange: nullRange,
                    in: container,
                    rectCount: &rectCount
                )
                
                if rectCount > 0, let rects = rects {
                    // Note that the ruler view is only as tall as the visible
                    // portion. Need to compensate for the clipview's coordinates.
                    let ypos = yinset + rects[0].minY - visibleRect.minY
                    
                    let marker = _linesToMarkers.object(forKey: NSNumber(value: line)) as? NoodleLineNumberMarker
                    
                    if let marker = marker {
                        let markerImage = marker.image
                        let markerSize = markerImage.size
                        var markerRect = NSRect(x: 0.0, y: 0.0, width: markerSize.width, height: markerSize.height)
                        
                        // Marker is flush right and centered vertically within the line.
                        markerRect.origin.x = bounds.width - markerImage.size.width - 1.0
                        markerRect.origin.y = ypos + rects[0].height / 2.0 - marker.imageOrigin.y
                        
                        markerImage.draw(in: markerRect, from: NSRect(x: 0, y: 0, width: markerSize.width, height: markerSize.height), operation: .sourceOver, fraction: 1.0)
                    }
                    
                    // Line numbers are internally stored starting at 0
                    let labelText = String(format: "%jd", Int64(line + 1))
                    
                    let stringSize = labelText.size(withAttributes: textAttributes)
                    
                    let currentTextAttributes: [NSAttributedString.Key: Any]
                    if marker == nil {
                        currentTextAttributes = textAttributes
                    } else {
                        currentTextAttributes = markerTextAttributes()
                    }
                    
                    // Draw string flush right, centered vertically within the line
                    let drawRect = NSRect(
                        x: bounds.width - stringSize.width - RULER_MARGIN,
                        y: ypos + (rects[0].height - stringSize.height) / 2.0,
                        width: bounds.width - RULER_MARGIN * 2.0,
                        height: rects[0].height
                    )
                    labelText.draw(in: drawRect, withAttributes: currentTextAttributes)
                }
            }
            if index > UInt(NSMaxRange(range)) {
                break
            }
            line += 1
        }
    }
    
    func lineNumberForLocation(_ location: CGFloat) -> UInt {
        guard let view = clientView as? NSTextView,
              let scrollView = scrollView else {
            return UInt(NSNotFound)
        }
        
        let visibleRect = scrollView.contentView.bounds
        let lines = self.lineIndices
        
        let adjustedLocation = location + visibleRect.minY
        
        let nullRange = NSRange(location: NSNotFound, length: 0)
        let layoutManager = view.layoutManager!
        let container = view.textContainer!
        let count = lines.count
        
        for line in 0..<count {
            guard let indexValue = lines.object(at: line) as? NSNumber else {
                continue
            }
            let index = indexValue.uintValue
            
            var rectCount: Int = 0
            let rects = layoutManager.rectArray(
                forCharacterRange: NSRange(location: Int(index), length: 0),
                withinSelectedCharacterRange: nullRange,
                in: container,
                rectCount: &rectCount
            )
            
            if let rects = rects {
                for i in 0..<rectCount {
                    if adjustedLocation >= rects[i].minY && adjustedLocation < rects[i].maxY {
                        return UInt(line + 1)
                    }
                }
            }
        }
        return UInt(NSNotFound)
    }
    
    func markerAtLine(_ line: UInt) -> NoodleLineNumberMarker? {
        return _linesToMarkers.object(forKey: NSNumber(value: line - 1)) as? NoodleLineNumberMarker
    }
    
    func setMarkers(_ markers: [NSRulerMarker]?) {
        _linesToMarkers.removeAllObjects()
        
        // Clear all existing markers by removing them
        let existingMarkers = _linesToMarkers.allValues.compactMap { $0 as? NSRulerMarker }
        for marker in existingMarkers {
            removeMarker(marker)
        }
        
        guard let markers = markers else { return }
        
        for marker in markers {
            addMarker(marker)
        }
    }
    
    override func addMarker(_ aMarker: NSRulerMarker) {
        if let lineMarker = aMarker as? NoodleLineNumberMarker {
            _linesToMarkers.setObject(
                lineMarker,
                forKey: NSNumber(value: lineMarker.lineNumber - 1)
            )
        } else {
            super.addMarker(aMarker)
        }
    }
    
    override func removeMarker(_ aMarker: NSRulerMarker) {
        if let lineMarker = aMarker as? NoodleLineNumberMarker {
            _linesToMarkers.removeObject(forKey: NSNumber(value: lineMarker.lineNumber - 1))
        } else {
            super.removeMarker(aMarker)
        }
    }
    
    // MARK: NSCoding methods
    
    override func encode(with coder: NSCoder) {
        super.encode(with: coder)
        
        if coder.allowsKeyedCoding {
            coder.encode(font, forKey: "font")
            coder.encode(textColor, forKey: "textColor")
            coder.encode(alternateTextColor, forKey: "alternateTextColor")
            coder.encode(backgroundColor, forKey: "backgroundColor")
        } else {
            coder.encode(font)
            coder.encode(textColor)
            coder.encode(alternateTextColor)
            coder.encode(backgroundColor)
        }
    }
}
