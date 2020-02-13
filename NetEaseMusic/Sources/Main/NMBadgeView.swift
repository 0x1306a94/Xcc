//
//  NMBadgeView.swift
//  NetEaseMusic
//
//  Created by SAGESSE on 2019/7/20.
//  Copyright © 2019 SAGESSE. All rights reserved.
//

import UIKit

@IBDesignable
open class NMBadgeView: UILabel {

    /// Initializes and returns a newly allocated view object with the specified frame rectangle.
    public override init(frame: CGRect) {
        super.init(frame: frame)

    }

    /// Returns an object initialized from data in a given unarchiver.
    public required init?(coder: NSCoder) {
        super.init(coder: coder)

        super.text.map {
            self.text = $0
        }
    }

    open override var text: String? {
        willSet {
            updateBadgeValue(newValue) {
                (newValue as NSString?)?.substring(with: $0)
            }
        }
    }
    open override var attributedText: NSAttributedString? {
        willSet {
            updateBadgeValue(newValue?.string) {
                newValue?.attributedSubstring(from: $0)
            }
        }
    }

    open override var font: UIFont! {
        didSet {
            updateBadgeLayout()
        }
    }
    open override var textColor: UIColor! {
        didSet {
            setNeedsDisplay()
        }
    }

    open override func invalidateIntrinsicContentSize() {
        super.invalidateIntrinsicContentSize()
        cachedContentSize = nil
    }

    open override var intrinsicContentSize: CGSize {
        // Hit cache!
        if let contentSize = cachedContentSize {
            return contentSize
        }
        var contentSize = cachedImageSize ?? .zero

        // Append title size.
        cachedTextSize.map {
            contentSize.width += titleInsets.left + $0.width + titleInsets.right
            contentSize.height = max(titleInsets.top + $0.height + titleInsets.bottom, contentSize.height)
        }

        // Append content insets.
        if subtype != .full {
            contentSize.width += contentInset.left + contentInset.right
            contentSize.height += contentInset.top + contentInset.bottom
        }

        cachedContentSize = contentSize
        return contentSize
    }

    /// Redraw all contents.
    open override func draw(_ rect: CGRect) {
        var offset = contentInset.left

        // Draw a rounded background.
        fillColor.map {
            $0.setFill()
            UIBezierPath(roundedRect: bounds, cornerRadius: bounds.height / 2).fill()
        }

        // Draw a background image/icon.
        image.map {
            // If this is the background image shown directly.
            guard let size = cachedImageSize, let context = UIGraphicsGetCurrentContext(), subtype != .full else {
                $0.draw(at: .init(x: 0, y: (bounds.height - $0.size.height) / 2))
                return
            }

            // If it is a normal image directly display.
            let point = CGPoint(x: offset, y: (bounds.height - size.height) / 2)
            guard $0.renderingMode != .alwaysOriginal, let cgImage = $0.cgImage else {
                $0.draw(at: point)
                offset += size.width
                return
            }

            // Draw `tintColor` image.
            textColor.setFill()
            context.saveGState()
            context.scaleBy(x: 1, y: -1)
            context.translateBy(x: 0, y: -bounds.height)
            context.clip(to: .init(origin: point, size: size), mask: cgImage)
            context.fill(.init(origin: point, size: size))
            context.restoreGState()
            offset += size.width
        }

        // It may need to be offset.
        offset += titleInsets.left

        // Draw a normal string.
        if let text = string as? NSString, let size = cachedTextSize {
            let point = CGPoint(x: offset, y: (bounds.height - size.height) / 2)
            text.draw(at: point, withAttributes: [.font: font as Any, .foregroundColor: textColor as Any])
            offset += size.width
        }

        // Draws a style string directly.
        if let text = string as? NSAttributedString, let size = cachedTextSize {
            let point = CGPoint(x: offset, y: (bounds.height - size.height) / 2)
            text.draw(at: point)
            offset += size.width
        }
    }

    fileprivate func updateBadgeValue(_ newValue: String?, substring: (NSRange) -> Any?) {

        // Restore to default.
        image = nil
        string = nil
        subtype = .none
        fillColor = nil
        titleInsets = .zero

        switch newValue {
        case "黑胶VIP":

            image = loadImage("cm5_icn_black_vip_54h")
            subtype = .full

        case "黑胶VIP/年":

            image = loadImage("cm5_icn_black_vip_annual_54h")
            subtype = .full

        case "音乐包":

            image = loadImage("cm5_icn_music_package_54h")
            subtype = .full

        case let newValue as NSString where newValue.hasPrefix("Lv."):

            // Is level type.
            image = loadImage("cm6_set_icn_lv")
            string = substring(NSRange(location: 3, length: newValue.length - 3))
            subtype = .level
            fillColor = #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.4)
            titleInsets = .init(top: 0, left: 2, bottom: 0, right: 2)

        case let newValue as NSString where newValue.hasPrefix("男:"):

            // Is gender type of boy.
            image = loadImage("cm2_icn_boy")
            string = substring(NSRange(location: 2, length: newValue.length - 2))
            subtype = .gender
            fillColor = #colorLiteral(red: 0.35, green: 0.71, blue: 0.91, alpha: 0.5)
            titleInsets = .init(top: 0, left: 4, bottom: 0, right: 4)

        case let newValue as NSString where newValue.hasPrefix("女:"):

            // Is gender type of girl.
            image = loadImage("cm2_icn_girl")
            string = substring(NSRange(location: 2, length: newValue.length - 2))
            subtype = .gender
            fillColor = #colorLiteral(red: 1, green: 0.53, blue: 0.71, alpha: 0.5)
            titleInsets = .init(top: 0, left: 4, bottom: 0, right: 4)

        case let newValue as NSString:

            // Is normal string.
            string = substring(NSRange(location: 0, length: newValue.length))
            subtype = .none
            fillColor = #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.4)

        default:
            break
        }

        if (string as? NSString)?.length == 0 {
            string = nil
        }
        if (string as? NSAttributedString)?.length == 0 {
            string = nil
        }

        // Force reload layout.
        updateBadgeLayout()
    }
    fileprivate func updateBadgeLayout() {

        // Calculate the size of normal string.
        (string as? NSString).map {
            cachedTextSize = $0.boundingRect(with: .zero, options: .usesLineFragmentOrigin, attributes: [.font: font as Any], context: nil).size
        }

        // Calculate the size of style string.
        (string as? NSAttributedString).map {
            cachedTextSize = $0.boundingRect(with: .zero, options: .usesLineFragmentOrigin, context: nil).size
        }

        // Calculate the size of image
        cachedImageSize = image?.size
        invalidateIntrinsicContentSize()
        setNeedsDisplay()

    }

    fileprivate func loadImage(_ named: String) -> UIImage? {
        return UIImage(named: named, in: Bundle(for: type(of: self)), compatibleWith: nil)
    }

    fileprivate var image: UIImage?
    fileprivate var string: Any?
    fileprivate var subtype: Subtype = .none
    fileprivate var fillColor: UIColor?

    fileprivate var cachedTextSize: CGSize?
    fileprivate var cachedImageSize: CGSize?
    fileprivate var cachedContentSize: CGSize?

    fileprivate var titleInsets: UIEdgeInsets = .zero
    fileprivate var contentInset: UIEdgeInsets = .init(top: 2.5, left: 8.5, bottom: 2.5, right: 8.5)

    fileprivate enum Subtype {
        case none
        case level
        case gender
        case full
    }
}
