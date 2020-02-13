//
//  NMLabel.swift
//  NetEaseMusic
//
//  Created by SAGESSE on 2019/7/29.
//  Copyright © 2019 SAGESSE. All rights reserved.
//

import UIKit
import CoreGraphics


public struct NMLabelDetectorTypes: OptionSet {
    
    public let rawValue: Int
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
    
    
    public static var at: NMLabelDetectorTypes = .init(rawValue: 0x0001) 
    
    public static var link: NMLabelDetectorTypes = .init(rawValue: 0x0002) // URL detection
    
    public static var topic: NMLabelDetectorTypes = .init(rawValue: 0x0004)
    
    public static var phoneNumber: NMLabelDetectorTypes = .init(rawValue: 0x0008) // Phone number detection
    
    
//    public static var address: NMLabelDetectorTypes = .init(rawValue: 0x0001) // Street address detection
//
//    public static var calendarEvent: NMLabelDetectorTypes = .init(rawValue: 0x0001) // Event detection
//    
//    public static var shipmentTrackingNumber: NMLabelDetectorTypes = .init(rawValue: 0x0001) // Shipment tracking number detection
//    
//    public static var flightNumber: NMLabelDetectorTypes = .init(rawValue: 0x0001) // Flight number detection
//    
//    public static var lookupSuggestion: NMLabelDetectorTypes = .init(rawValue: 0x0001) // Information users may want to look up
    
    
    public static var all: NMLabelDetectorTypes = .init(rawValue: 0xffff)  // Enable all types, including types that may be added later
    
}

//@IBDesignable
open class NMLabel: UILabel, NSLayoutManagerDelegate {
  
    public override init(frame: CGRect) {
        super.init(frame: frame)
        self.setup()
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.setup()
    }
    
    
    /// The text container object defining the area in which text is displayed in this label.
    open var textContainer: NSTextContainer {
        return cachedTextContainer
    }

    /// The inset of the text container's layout area within the text view's content area.
    open var textContainerInset: UIEdgeInsets = .init(top: 8, left: 0, bottom: 8, right: 0)

    
    /// The layout manager that lays out text for the receiver’s text container.
    open var layoutManager: NSLayoutManager { 
        return cachedLayoutManager
    }
    
    
    open var detectorTypes: NMLabelDetectorTypes = .all

//    open override var intrinsicContentSize: CGSize {
//        let s = super.intrinsicContentSize
//        return .init(width: s.width, height: s.height * 2)
//    }
//    

    /// The text storage object holding the text displayed in this label.
    open var textStorage: NSTextStorage { 
        return cachedTextStorage
    }
    
//    open override var font: UIFont! {
//        didSet {
//            textStorage.addAttribute(.font, value: font as Any, range: NSRange(location: 0, length: textStorage.length))
//        }
//    }
    
    open override var text: String? {
        didSet {
            textStorage.setAttributedString(super.attributedText ?? .init())
        }
    }
    
    open override var attributedText: NSAttributedString? {
        didSet {
            
//            logger.debug?.write(attributedText)

            
//            let range = NSRange(location: 0, length: textStorage.length)
            //textStorage.fixAttributes(in: NSRange(location: 0, length: textStorage.length))
//            textStorage.invalidateAttributes(in: range)
//            textStorage.fixAttributes(in: NSRange(location: 0, length: textStorage.length))
            
            cachedTextStorage.defaultFont = font
            cachedTextStorage.defaultForegroundColor = textColor
            
            textStorage.setAttributedString(super.attributedText ?? .init())
//            textStorage.addAttribute(.font, value: font as Any, range: NSMakeRange(0, textStorage.length))

//            textStorage.addAttribute(.init(rawValue: "NSOriginalFont"), value: font, range: NSMakeRange(0, textStorage.length))
            //textStorage.removeAttribute(.init(rawValue: "NSOriginalFont"), range: NSRange(location: 0, length: textStorage.length))
//            textStorage.fixAttributes(in: NSRange(location: 0, length: textStorage.length))
            logger.debug?.write(textStorage)

//            textStorage.invalidateAttributes(in: NSRange(location: 0, length: textStorage.length))

            //            textStorage.addAttribute(.foregroundColor, value: textColor as Any, range: NSMakeRange(0, textStorage.length))

        }
    }
    
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        
        if textContainer.size != bounds.size {
            textContainer.size = bounds.size
        }
    }
    
    open override func drawText(in rect: CGRect) {
        
        super.drawText(in: rect)
//        
//        UIGraphicsGetCurrentContext().map {
//            $0.setFont(CGFont(font.fontName as CFString)!)
//            $0.setFontSize(font.pointSize)
//        }
//        print(layoutManager.usedRect(for: textContainer))
        
        let range = NSRange(location: 0, length: textStorage.length)
        layoutManager.drawBackground(forGlyphRange: range, at: CGPoint(x: 0, y: 0))
        layoutManager.drawGlyphs(forGlyphRange: range, at: CGPoint(x: 0, y: 1))
    }
    
    @inline(__always) private func setup() {
        
        layoutManager.delegate = self
        textStorage.addLayoutManager(layoutManager)
        layoutManager.addTextContainer(textContainer)
        
        textContainer.lineFragmentPadding = 0
        //textContainer.maximumNumberOfLines = numberOfLines

        
//        let range = NSRange(location: 0, length: textStorage.length)
//        let attributes: [NSAttributedString.Key: Any] = [
//            .font: font as Any,
//            .foregroundColor: UIColor.red
//        ]
        
        //textStorage.setAttributes(attributes, range: range)
        //textStorage.addAttribute(.init(rawValue: "NSOriginalFont"), value: font, range: NSMakeRange(0, textStorage.length))



//        attributedText.map { 
//            textStorage.setAttributedString($0) 
//        }
        //        
//        textStorage.addAttribute(.foregroundColor, value: textColor as Any, range: NSMakeRange(0, textStorage.length))
//        textStorage.addAttribute(.font, value: font as Any, range: NSMakeRange(0, textStorage.length))


        // #...#
        // @...
        // ...://...
        // xxx.com
        
        // bunding
        
        let con = NMTextContainer()
        let text = UITextView(frame: self.bounds, textContainer: con)
        text.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(text)
        isUserInteractionEnabled = true
        
    }
//    @property (nonatomic, strong) NSTextStorage *textStorage;
//    @property (nonatomic, strong) MLLabelLayoutManager *layoutManager;
//    @property (nonatomic, strong) NSTextContainer *textContainer;
    
//    public func layoutManager(_ layoutManager: NSLayoutManager, shouldBreakLineByWordBeforeCharacterAt charIndex: Int) -> Bool {
//        return true
//    }
    
    private var cachedTextContainer: NMTextContainer = .init()
    private var cachedTextStorage: NMTextStorage = .init()
    private var cachedLayoutManager: NMTextLayoutManager = .init()
}

class NMTextContainer: NSTextContainer {
}

class NMTextStorage: NSTextStorage {
    
    ///
    /// The font used to display the text.
    ///
    /// If you are using styled text, assigning a new value to this property causes the font to be applied to the entirety of the string in the attributedText property. If you want to apply the font to only a portion of the text, create a new attributed string with the desired style information and associate it with the label. If you are not using styled text, this property applies to the entire text string in the text property.
    /// The default value for this property is the system font at a size of 17 points (using the systemFont(ofSize:) class method of UIFont). 
    ///
    var defaultFont: UIFont = .systemFont(ofSize: 17)
    
    ///
    /// The color of the text.
    ///
    /// If you are using styled text, assigning a new value to this property causes the color to be applied to the entirety of the string in the attributedText property. If you want to apply the color to only a portion of the text, create a new attributed string with the desired style information and associate it with the label. If you are not using styled text, this property applies to the entire text string in the text property.
    /// The default value for this property is a black color (set through the black class property of UIColor).
    ///
    var defaultForegroundColor: UIColor = .black
    
    
    /// The length of the receiver’s string object.
    override var length: Int {
        return storage.length
    }
    
    /// The character contents of the receiver as an NSString object.
    override var string: String {
        return storage.string
    }
    
    /// The character contents of the receiver as an NSMutableString object.
    override var mutableString: NSMutableString {
        return storage.mutableString
    }
    
    
    /// Returns the attributes for the character at a given index.
    override func attributes(at location: Int, effectiveRange range: NSRangePointer?) -> [NSAttributedString.Key: Any] {
        let attrs =  storage.attributes(at: location, effectiveRange: range)
        //logger.debug?.write(attrs, range)
        return attrs
    }
    
    /// Sets the attributes for the characters in the specified range to the specified attributes.
    override func setAttributes(_ attrs: [NSAttributedString.Key: Any]?, range: NSRange) {
        var newAttrs = attrs ?? [:]
        
        // Setup default font.
        if newAttrs[.font] == nil {
            newAttrs[.font] = defaultFont
            logger.debug?.write("font => \(range)")
        }
        
        // Setup default text color.
        if newAttrs[.foregroundColor] == nil {
            newAttrs[.foregroundColor] = defaultForegroundColor
            logger.debug?.write("textColor => \(range)")
        }

        storage.setAttributes(newAttrs, range: range)
        edited(.editedAttributes, range: range, changeInLength: 0)
    }
    
    /// Replaces the characters in the given range with the characters of the given string.
    override func replaceCharacters(in range: NSRange, with str: String) {
        storage.replaceCharacters(in: range, with: str)
        edited(.editedCharacters, range: range, changeInLength: str.count - range.length)
    }

    private var storage: NSMutableAttributedString = .init()
}

class NMTextLayoutManager: NSLayoutManager {
    
    override func showCGGlyphs(_ glyphs: UnsafePointer<CGGlyph>, positions: UnsafePointer<CGPoint>, count glyphCount: Int, font: UIFont, matrix textMatrix: CGAffineTransform, attributes: [NSAttributedString.Key: Any] = [:], in graphicsContext: CGContext) {
        
        // ...
//        if attributes[.link] != nil {
//            UIColor.red.setFill()
//        }
//        let c = textMatrix.rotated(by: .pi / 2)

        super.showCGGlyphs(glyphs, positions: positions, count: glyphCount, font: font, matrix: textMatrix, attributes: attributes, in: graphicsContext)
    }
    
    
    override func drawUnderline(forGlyphRange glyphRange: NSRange, underlineType underlineVal: NSUnderlineStyle, baselineOffset: CGFloat, lineFragmentRect lineRect: CGRect, lineFragmentGlyphRange lineGlyphRange: NSRange, containerOrigin: CGPoint) {
        
        // ...
        if textStorage?.attribute(.link, at: glyphRange.location, effectiveRange: nil) != nil {
            return
        }
        
        super.drawUnderline(forGlyphRange: glyphRange, underlineType: underlineVal, baselineOffset: baselineOffset, lineFragmentRect: lineRect, lineFragmentGlyphRange: lineGlyphRange, containerOrigin: containerOrigin)
    }
}
