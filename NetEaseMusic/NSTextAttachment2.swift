//
//  NSTextAttachment2.swift
//  NetEaseMusic
//
//  Created by SAGESSE on 2020/2/1.
//  Copyright © 2020 SAGESSE. All rights reserved.
//

import UIKit


/// A custom text attachment.
class NSTextAttachment2: NSTextAttachment {
    
    /// The title displayed on the item.
    var title: NSAttributedString? {
        willSet {
            cachedTextSize = nil
            cachedContentSize = nil
            cachedRenderImage = nil
        }
    }
    
    /// The image used to represent the item.
    override var image: UIImage? {
        willSet {
            cachedImageSize = nil
            cachedContentSize = nil
            cachedRenderImage = nil
        }
    }
    
    /// The attachment background color, if setup draw a fill block using the corner and cornerRadius.
    var backgroundColor: UIColor?
    
    /// When this value is greater than 0.0, the attachment draws a border using the current borderColor value.
    var border: CGFloat = 0
    
    /// The attachment border color.
    var borderColor: UIColor?

    /// The mode to use when drawing rounded corners for the attachment background.
    var corner: UIRectCorner = .allCorners
    
    /// The radius to use when drawing rounded corners for the attachment background.
    var cornerRadius: CGFloat = 0
    
    /// The spacing for image to title.
    var spacing: CGFloat = 4 {
        willSet {
            cachedContentSize = nil
            cachedRenderImage = nil
        }
    }
    
    /// The alignment in the line.
    var alignment: UIStackView.Alignment = .firstBaseline

    
    /// The attachment margin.
    var margin: UIEdgeInsets = .zero
    
    /// The attachment padding.
    var padding: UIEdgeInsets = .zero

    /// The attachment content size.
    var intrinsicContentSize: CGSize {
        // Hit cache?
        if let size = cachedContentSize {
            return size
        }
        
        // Recalculation the text and image size if needed.
        if cachedTextSize == nil {
            cachedTextSize = (title?.size()).map {
                return .init(width: trunc($0.width + 0.5), height: trunc($0.height + 0.5))
            }
        }
        if cachedImageSize == nil {
            cachedImageSize = (image?.size).map {
                return .init(width: trunc($0.width + 0.5), height: trunc($0.height + 0.5))
            }
        }
        var size = CGSize(width: -spacing, height: 0)

        cachedImageSize.map {
            size = $0
        }
        
        cachedTextSize.map {
            size.width = size.width + spacing + $0.width
            size.height = max(size.height, $0.height)
        }
        
        size.width = max(trunc(size.width + 0.5), 0)
        size.height = max(trunc(size.height + 0.5), 0)

        cachedContentSize = size
        
        return size
    }
    
    
    override func image(forBounds imageBounds: CGRect, textContainer: NSTextContainer?, characterIndex charIndex: Int) -> UIImage? {
        let bounds = CGRect(origin: .zero, size: imageBounds.size).inset(by: margin)
        guard imageBounds.size != .zero else {
            return nil
        }
        
        // The cache is hit?
        if let newValue = cachedRenderImage {
            return newValue
        }
        
        // Start draw attachment.
        UIGraphicsBeginImageContextWithOptions(imageBounds.size, false, UIScreen.main.scale)

        // Draw background if nneded.
        backgroundColor.map {
            $0.setFill()
            path(bounds).fill()
        }
        
        // Draw border if needed.
        borderColor.map {
            $0.setStroke()
            let frame = bounds.inset(by: .init(top: border / 2, left: border / 2, bottom: border / 2, right: border / 2))
            path(frame).stroke()
        }
        
        // Draw title if needed.
        cachedTextSize.map {
            title?.draw(at: .init(x: (imageBounds.width - $0.width - padding.right - border - margin.right), y: (imageBounds.height - $0.height) / 2))
        }

        // Draw image if needed.
        cachedImageSize.map {
            image?.draw(at: .init(x: (margin.left + border + padding.left), y: (imageBounds.height - $0.height) / 2))
        }
        
        // Save render result to cache.
        let newValue = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        cachedRenderImage = newValue
        return newValue
    }
    
    override func attachmentBounds(for textContainer: NSTextContainer?, proposedLineFragment lineFrag: CGRect, glyphPosition position: CGPoint, characterIndex charIndex: Int) -> CGRect {
        guard let textStorage = textContainer?.layoutManager?.textStorage, title != nil || image != nil else {
            return .zero
        }

        var bounds = CGRect(origin: .zero, size: intrinsicContentSize)
        var descender: CGFloat {
            return (textStorage.attribute(.font, at: charIndex, longestEffectiveRange: nil, in: NSMakeRange(charIndex, 1)) as? UIFont)?.descender ?? 0
        }

        bounds.size.width += margin.left + margin.right + padding.left + padding.right + border * 2
        bounds.size.height += margin.top + margin.bottom + padding.top + padding.bottom + border * 2

        switch alignment {
        case .leading: // aka top
            bounds.origin.y = descender + max(lineFrag.height - bounds.height, 0)

        case .center:
            bounds.origin.y = descender + (lineFrag.height - bounds.height) / 2

        case .trailing: // aka bottom
            bounds.origin.y = descender

        case .fill:
            bounds.origin.y = descender
            bounds.size.height = max(bounds.height, lineFrag.size.height)
            
        default:
            break
        }

        return bounds
    }
    
    
    private func path(_ bounds: CGRect) -> UIBezierPath {
        let path = UIBezierPath(roundedRect: bounds,
                            byRoundingCorners: corner,
                            cornerRadii: .init(width: cornerRadius, height: cornerRadius))
        path.lineWidth = border
        return path
    }
    
    private var cachedTextSize: CGSize?
    private var cachedImageSize: CGSize?
    private var cachedContentSize: CGSize?
    
    private var cachedRenderImage: UIImage?
}
