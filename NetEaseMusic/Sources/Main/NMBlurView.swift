//
//  NMBlurView.swift
//  NetEaseMusic
//
//  Created by SAGESSE on 2018/10/25.
//  Copyright © 2018 SAGESSE. All rights reserved.
//

import UIKit
import Accelerate

@IBDesignable
open class NMBlurView: UIView {

    public override init(frame: CGRect) {
        super.init(frame: frame)
        self.setup()
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.setup()
    }

    @IBInspectable
    open var image: UIImage? {
        willSet {
            guard newValue !== image else {
                return
            }

            contentView.image = newValue

            guard let image = newValue, let cgImage = newValue?.cgImage else {
                blurredView.image = nil
                return
            }

            blurredView.image = convert(cgImage, radius: 33, scale: image.scale, orientation: image.imageOrientation)
        }
    }

    @IBInspectable
    open var highlightedImage: UIImage? { // default is nil
        set { return contentView.highlightedImage = newValue }
        get { return contentView.highlightedImage }
    }

    @IBInspectable
    open var blurred: CGFloat {
        set { return blurredView.alpha = newValue }
        get { return blurredView.alpha }
    }

    open override var contentMode: UIView.ContentMode {
        willSet {
            blurredView.contentMode = newValue
            contentView.contentMode = newValue
        }
    }

    @inline(__always) private func setup() {

        contentMode = .scaleAspectFill
        isUserInteractionEnabled = false

        contentView.alpha = 1
        contentView.frame = bounds
        contentView.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        // Create a blurred fill layer.
        blurredView.alpha = 0
        blurredView.frame = bounds
        blurredView.autoresizingMask = [.flexibleWidth, .flexibleHeight]

        // Create a mask fill layer.
        maskedView.backgroundColor = UIColor(white: 0, alpha: 0.4)
        maskedView.frame = bounds
        maskedView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        maskedView.addSubview(gradientView)

        // Create a gradient fill layer.
        gradientView.frame = CGRect(x: 0, y: 0, width: maskedView.bounds.width, height: 120)
        gradientView.image = NMBlurView.cachedGradientImage
        gradientView.autoresizingMask = [.flexibleWidth, .flexibleBottomMargin]

        // Setup subviews.
        addSubview(contentView)
        addSubview(blurredView)
        addSubview(maskedView)
    }

    /// Convert bitmap image to blurred image.
    @inline(__always) private func convert(_ image: CGImage, radius: Int, scale: CGFloat, orientation: UIImage.Orientation) -> UIImage? {

        // Getting source data from CGImage
        guard let source = image.dataProvider?.data else {
            return nil
        }

        // Make input buffer.
        var input = vImage_Buffer(data: .init(mutating: CFDataGetBytePtr(source)),
                                  height: .init(image.height),
                                  width: .init(image.width),
                                  rowBytes: .init(image.bytesPerRow))

        // Make transit buffer.
        var transit = vImage_Buffer(data: .allocate(byteCount: image.bytesPerRow * image.height, alignment: 0),
                                    height: input.height,
                                    width: input.width,
                                    rowBytes: input.rowBytes)

        // Make output buffer.
        var output = vImage_Buffer(data: .allocate(byteCount: image.bytesPerRow * image.height, alignment: 0),
                                   height: input.height,
                                   width: input.width,
                                   rowBytes: input.rowBytes)

        // Convert-1
        guard vImageBoxConvolve_ARGB8888(&input, &transit, nil, 0, 0, .init(radius), .init(radius), nil, .init(kvImageEdgeExtend)) == kvImageNoError else {
            return nil
        }

        // Convert-2
        guard vImageBoxConvolve_ARGB8888(&transit, &output, nil, 0, 0, .init(radius), .init(radius), nil, .init(kvImageEdgeExtend)) == kvImageNoError else {
            return nil
        }

        // Import output data into context.
        let context = CGContext(data: output.data,
                                width: image.width,
                                height: image.height,
                                bitsPerComponent: 8,
                                bytesPerRow: image.bytesPerRow,
                                space: CGColorSpaceCreateDeviceRGB(),
                                bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)

        // Build image.
        return context?.makeImage().map {
            return UIImage(cgImage: $0, scale: scale, orientation: orientation)
        }
    }

    open override var intrinsicContentSize: CGSize {
        return contentView.intrinsicContentSize
    }

    open override func invalidateIntrinsicContentSize() {
        return contentView.invalidateIntrinsicContentSize()
    }

    private lazy var maskedView: UIView = .init()
    private lazy var blurredView: UIImageView = .init()

    private lazy var contentView: UIImageView = .init()
    private lazy var gradientView: UIImageView = .init()

    /// Cached gradient image.
    private static var cachedGradientImage: UIImage? = {

        let size = CGSize(width: 120, height: 120)
        let colors = [UIColor(white: 0, alpha: 0.6).cgColor,
                      UIColor(white: 0, alpha: 0.0).cgColor]

        // Create a gradient image.
        UIGraphicsBeginImageContextWithOptions(size, false, UIScreen.main.scale)

        // Create a gradient color.
        CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors as CFArray, locations: nil).map {
            // Draw gradient line in context.
            UIGraphicsGetCurrentContext()?.drawLinearGradient($0, start: .zero, end: .init(x: 0, y: size.height), options: .drawsBeforeStartLocation)
        }

        // Get the drawed image & clean context.
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image

    }()
}

extension NMBlurView: XCParallaxingViewDelegate {

    open func parallaxingView(_ parallaxingView: XCParallaxingView, didChangeOffset offset: CGPoint) {
        blurred = min(max(offset.y / parallaxingView.contentSize.height, 0), 1)
    }
}
