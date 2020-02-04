//
//  NMEventNode.swift
//  NetEaseMusic
//
//  Created by SAGESSE on 2020/1/13.
//  Copyright © 2020 SAGESSE. All rights reserved.
//

import UIKit
import AsyncDisplayKit


let timage1: UIImage? = #imageLiteral(resourceName: "ap2")
let timage2: UIImage? = #imageLiteral(resourceName: "txs")
let timage3: UIImage? = #imageLiteral(resourceName: "user_head")
let timage4: UIImage? = #imageLiteral(resourceName: "cm2_icn_user_v")

func nmstr(_ str: String, _ font: CGFloat, _ color: UIColor, spacing: CGFloat = 0) -> NSMutableAttributedString {
    
    // NSFont = "<UICTFont: 0x1268be0a0> font-family: \"Helvetica\"; font-weight: normal; font-style: normal; font-size: 16.00pt";
   // UIFont(name: "Helvetica", size: font) ??
    
    var attributes: [NSAttributedString.Key: Any] = [
        .font: UIFont.systemFont(ofSize: font),
        .foregroundColor: color,
    ]
    
    if spacing > 0 {
        let style = NSMutableParagraphStyle()
        style.lineSpacing = spacing
        attributes[.paragraphStyle] = style
    }
    
//    if #available(iOS 13.0, *) {
//        attributes[.foregroundColor] = UIColor {
////            if $0.userInterfaceStyle == .dark {
////            }
//            return color
//        }
//    }
    
    return NSMutableAttributedString(string: str, attributes: attributes)
}


class NMEventNode: ASCellNode {

    let header: Header
    let tiles: [ASDisplayNode]
    let footer: Footer
    
    /// Create a cell for event.
    init(for event: NMEvent) {
        
        self.header = .init(for: event)
        self.tiles = Display.parse(event.tiles ?? [], for: event)
        self.footer = .init(for: event)
        
        super.init()
        
        self.addSubnode(self.header)
        self.tiles.forEach {
            self.addSubnode($0)
        }
        self.addSubnode(self.footer)
    }
    
    /// Setup layout for all subnodes.
    override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        
        let content = ASStackLayoutSpec.vertical().then {
            $0.spacing = 4
            $0.children = tiles
        }

        let spec = ASStackLayoutSpec.vertical(
            header,
            content.insets(left: header.avatar.style.preferredSize.width + 2),
            footer.insets(left: header.avatar.style.preferredSize.width + 2)
        )
        
        return spec.insets(top: 8, left: 12, bottom: 8, right: 12)
    }
}



// MARK: -


/// Provide the base node.
extension NMEventNode {

    class Header: ASDisplayNode {
        
        let avatar: ASDisplayNode = .init { () -> UIView in
            let view = NMAvatarView()
            view.padding = .init(top: 9, left: 9, bottom: 9, right: 9)
            view.avatar = timage3
            view.badge = timage4
            return view
        }
        
        let title: ASTextNode = .init()
        let subtitle: ASTextNode = .init()

        let badge: NMEventBadgeNode = .init()
        let action: ASTextNode = .init()
        
        /// Create a node for event.
        init(for event: NMEvent) {
            super.init()
            
            self.addSubnode(self.avatar) {
                $0.style.preferredSize = .init(width: 58, height: 58)
            }
            

            
            self.addSubnode(self.title) {
                $0.style.flexShrink = 0
                $0.truncationMode = .byTruncatingTail
                $0.maximumNumberOfLines = 1
                $0.attributedText = nmstr(event.user?.nickname ?? "", 15, #colorLiteral(red: 0.3137254902, green: 0.4901960784, blue: 0.6862745098, alpha: 1))
            }
            
            self.addSubnode(self.subtitle) {
                $0.style.flexShrink = 1
                $0.truncationMode = .byTruncatingTail
                $0.maximumNumberOfLines = 1
                $0.attributedText = nmstr(event.date ?? "", 11, UIColor(white: 0, alpha: 0.4))
            }
            
//            self.action.style.flexShrink = 1
//            self.action.truncationMode = .byTruncatingTail
//            self.action.maximumNumberOfLines = 1
//            self.action.attributedText = nmstr(event.actName ?? "", 15, UIColor(white: 0, alpha: 0.6))
            
//            self.addSubnode(self.badge)
//            self.addSubnode(self.action)
            
        }
        
        /// Setup layout for all subnodes.
        override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
            let spec = ASStackLayoutSpec.horizontal(
                avatar,
                ASStackLayoutSpec.vertical(
                    ASStackLayoutSpec.horizontal(title, badge, action, spacing: 2, verticalAlignment: .center),
                    ASStackLayoutSpec.horizontal(subtitle),
                    spacing: 1,
                    verticalAlignment: .center
                ).then {
                    $0.style.flexShrink = 1
                },
                spacing: 2
            )
            return spec
        }
    }
    
    class Display: ASDisplayNode {
        /// Parse all content nodes for event.
        static func parse<T>(_ contents: [Any], for event: NMEvent) -> [T] {
            return contents.compactMap {
                // If can't convert to an entity object, ignore this content.
                guard let entity = $0 as? NMEventNodeEntityCompatible else {
                    return nil
                }
                return entity.displayType.init(entity, for: event) as? T
            }
        }
    }

    class Footer: ASDisplayNode {
        
        /// Create a node for event.
        init(for event: NMEvent) {
            super.init()
            
            self.addSubnode(self.making(icon: "cm6_event_footer_repost", value: "转发"))
            self.addSubnode(self.making(icon: "cm6_event_footer_comment", value: "评论"))
            self.addSubnode(self.making(icon: "cm6_event_footer_unlike", value: "点赞"))
            self.addSubnode(self.making(icon: "cm6_btn_rcmd_more"))
        }
        
        /// Setup layout for all subnodes.
        override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
            
            let spec = ASStackLayoutSpec.horizontal().then {
                $0.justifyContent = .spaceBetween
                $0.alignItems = .center
                $0.children = subnodes
            }
            
            return spec.insets(top: 20, bottom: 20)
        }
        
        /// Create a display items.
        func making(icon: String, value: String? = nil, selector: Selector? = nil) -> ASButtonNode {
            let btn = ASButtonNode()
            
            btn.contentSpacing = 5
            
            btn.setImage(UIImage(named: icon), for: .normal)
            
            // If no nedd title, the value will is empty.
            value.map {
                btn.setTitle($0, with: UIFont.systemFont(ofSize: 12), with: UIColor(white: 0, alpha: 0.8), for: .normal)
            }
            
            // If no need respond, the selector will is empty.
            selector.map {
                btn.addTarget(self, action: $0, forControlEvents: .touchUpInside)
            }
            
            return btn
        }
    }
}


// MARK: -


extension NMEventNode.Display {
    
    /// The text node for event.
    class Text: ASDisplayNode, ASTextNodeDelegate, NMEventNodeDisplayable {
        
        /// The text attachment for text node.
        class Attachment: NSTextAttachment {
            
            /// A async display node for attachment.
            var display: ASNetworkImageNode = .init()

            /// A remote image url.
            convenience init(_ url: URL) {
                self.init()
                self.display.isHidden = true
                self.display.setURL(url, resetToDefault: false)
            }
            
            /// When the current attachment is displayed, will requeste a image.
            override func image(forBounds imageBounds: CGRect, textContainer: NSTextContainer?, characterIndex charIndex: Int) -> UIImage? {
                
                display.isHidden = false
                
                display.style.layoutPosition = .init(x: imageBounds.minX, y: imageBounds.minY - imageBounds.height)
                display.style.preferredSize = imageBounds.size
                
                display.supernode?.setNeedsLayout()
                
                return nil
            }
        }
        
        /// The real text value.
        let value: ASTextNode = .init()
        
        /// Create a display node using entity and events.
        required init(_ entity: NMEvent.Text, for event: NMEvent) {
            super.init()
            
            var offset = 0
            var attachments = [Attachment]()

            self.addSubnode(self.value) {
                
                $0.isUserInteractionEnabled = true
                $0.delegate = self
                $0.linkAttributeNames = [Text.tap.rawValue]
                $0.attributedText = NSMutableAttributedString(string: entity.value).then { str in

                    let color = UIColor.black
                    let font = UIFont(name: "Helvetica", size: entity.size) ?? UIFont.systemFont(ofSize: entity.size)
                    let style = NSMutableParagraphStyle()
                    
                    style.lineSpacing = 8
                    
                    // Configure the text attributes.
                    str.addAttributes([.font: font, .foregroundColor: color, .paragraphStyle: style], range: NSMakeRange(0, str.length))
                    
                    // Use detector to examine the entire string.
                    Text.detector?.enumerateMatches(in: str.string, range: NSMakeRange(0, str.length)) { result, _, _ in
                        // Match successful, check the match result。
                        guard var range = result?.range, range.location != NSNotFound else {
                            return
                        }
                        
                        // Calibration the matches range.
                        range.location += offset
                        let contents = str.mutableString.substring(with: range)
                        
                        // If the contents is a link needs to replace the specific content.
                        switch contents.first {
                        case "[" where contents.count > 2: // This is a emoticon.
                            // Make a new emotion text.
                            let emoji = String(contents[contents.index(after: contents.startIndex) ..< contents.index(before: contents.endIndex)])
                            
                            // This is a named emoji?
                            if let newValue = NMEmojiCoder.shared.emoji(for: emoji) as NSString? {
                                str.replaceCharacters(in: range, with: newValue as String)
                                offset -= range.length - newValue.length
                                range = NSMakeRange(range.location, newValue.length)
                                return
                            }
                            
                            // This is a custom emotion(sync display)
                            if let newValue = NMEmojiCoder.shared.image(for: emoji) {
                                let attachment = NSTextAttachment()
                                attachment.image = newValue
                                attachment.bounds = .init(x: 0, y: font.descender, width: newValue.size.width, height: newValue.size.height)
                                str.replaceCharacters(in: range, with: NSAttributedString(attachment: attachment))
                                offset -= range.length - 1
                                range = NSMakeRange(range.location, 1)
                                return
                            }
                            
                            // This is a custom emotion(async display)
                            if let newValue = NMEmojiCoder.shared.url(for: emoji) {
                                let attachment = Attachment(newValue)
                                attachment.bounds = .init(x: 0, y: font.descender, width: 22, height: 22)
                                str.replaceCharacters(in: range, with: NSAttributedString(attachment: attachment))
                                offset -= range.length - 1
                                range = NSMakeRange(range.location, 1)
                                attachments.append(attachment)
                                return
                            }
                            
                            // This is a unknow emoji, ignore.
                            return
                            
                        case "@": // This is a at.
                            break
                            
                        case "#": // This is a topic.
                            break
                            
                        default: // This is a normal url.
                            // Make a new link text.
                            let newValue = NSMutableAttributedString(string: "网页连接").then {
                                $0.insert(.init(attachment: NSTextAttachment2.link), at: 0)
                                $0.addAttribute(.font, value: font, range: NSMakeRange(0, $0.length))
                            }
                            str.replaceCharacters(in: range, with: newValue)
                            offset -= range.length - newValue.length
                            range = NSMakeRange(range.location, newValue.length)
                        }
                        
                        // Update the highlighted attributes.
                        str.addAttribute(Text.tap, value: contents, range: range)
                        str.addAttribute(.foregroundColor, value: #colorLiteral(red: 0.3123042285, green: 0.4909963608, blue: 0.6867333055, alpha: 1), range: range)
                    }
                }
            }
            
            // Add all attachments that show node to the current node.
            attachments.forEach {
                self.addSubnode($0.display)
            }
        }
        
        /// Setup layout for all subnodes.
        override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
            return ASOverlayLayoutSpec(child: value.insets(bottom: 4),
                                       overlay: ASAbsoluteLayoutSpec(children: .init(subnodes?.suffix(from: 1) ?? [])))
        }

        /// Enable highlighting now that self.layer has loaded.
        override func didLoad() {
            super.didLoad()
            layer.as_allowsHighlightDrawing = true
        }
        
        /// Indicates to the text node if an attribute should be considered a link.
        func textNode(_ textNode: ASTextNode, shouldHighlightLinkAttribute attribute: String, value: Any, at point: CGPoint) -> Bool {
            // opt into link highlighting -- tap and hold the link to try it!  must enable highlighting on a layer, see -didLoad
            return true
        }
        
        /// Indicates to the delegate that a link was tapped within a text node.
        func textNode(_ textNode: ASTextNode, tappedLinkAttribute attribute: String, value: Any, at point: CGPoint, textRange: NSRange) {
            logger.debug?.write(value)
        }
        
        /// Custom link for textkit.
        static let tap: NSAttributedString.Key = .init(rawValue: "NMEventNode.Display.Text.Tap")

        /// Create a at & link & topic detector regular expression
        static let detector: NSRegularExpression? = try? .init(pattern: "(@\\S+|\\[[^\\[\\]]+\\]|#[^#]+#|\\w{3,}://[\\w.:;?=\\-%+#/]+)")
    }

    /// The image node for event.
    class Image: ASDisplayNode, NMEventNodeDisplayable {
        
        /// The 1 to 3x3 images layout spec.
        class LayoutSpec: ASLayoutSpec {
            
            /// The amount of space between each child.
            var spacing: CGFloat = 0

            /// The size range of single child.
            var singleLayoutSize: ASSizeRange = .init()
            
            /// Asks the layout to return a layout based on given size range.
            override func calculateLayoutThatFits(_ constrainedSize: ASSizeRange) -> ASLayout {
                // Ignore when children is empty or layout spec is empty.
                guard let children = children, !children.isEmpty, constrainedSize.max.width > 0 else {
                    return .init(layoutElement: self, size: constrainedSize.min)
                }
                
                // Adapt content size when there is only one child.
                guard children.count > 1 else {
                    // First calculate out the size of the first child.
                    var size = children[0].layoutThatFits(ASSizeRangeUnconstrained).size
                    
                    // Calculate the minimum size.
                    var minimum = singleLayoutSize.min
                    if minimum.width.isZero || minimum.width.isInfinite {
                        minimum.width = size.width
                    }
                    if minimum.height.isZero || minimum.height.isInfinite {
                        minimum.height = size.height
                    }

                    // Calculate the final scaling.
                    let scale = max(minimum.width / max(size.width, 1), minimum.height / max(size.height, 1))
                    
                    // Calculate the maximum size.
                    var maximum = singleLayoutSize.max
                    if maximum.width.isZero || maximum.width.isInfinite {
                        maximum.width = size.width * scale
                    }
                    if maximum.height.isZero || maximum.height.isInfinite {
                        maximum.height = size.height * scale
                    }

                    // Apply scale and limit size.
                    size.width = min(size.width * scale, min(maximum.width, constrainedSize.max.width))
                    size.height = min(size.height * scale, maximum.height)
                    
                    // Merge everything into the main layout.
                    return .init(layoutElement: children[0], size: size)
                }
                
                // Create a template for each rows.
                let templates = { count -> [(count: Int, column: Int)] in
                    switch count {
                    case 2:  return [(2,2)]
                    case 4:  return [(2,3)]
                    case 5:  return [(2,2),(3,3)]
                    case 7:  return [(3,3),(4,4)]
                    case 8:  return [(4,4)]
                    default: return [(3,3)]
                    }
                }(min(children.count, 9))
                
                // Configuration the environment.
                var index = 0
                var offset = CGFloat.zero
                var layouts = [ASLayout]()
                
                // Iterate through all the sublayouts.
                while index < min(children.count, 9) {
                    // Gets the template being applying.
                    let template = templates[layouts.count % templates.count]
                    let height = (constrainedSize.max.width - (spacing * .init(template.column - 1))) / .init(template.column)
                    
                    // Generate a line of template.
                    let size = CGSize(width: constrainedSize.max.width, height: height)
                    let layout = ASLayout(layoutElement: self, size: size, position: .init(x: 0, y: offset), sublayouts: children[index ..< min(index + template.count, children.count)].enumerated().map {
                        return ASLayout(layoutElement: $1, size: .init(width: height, height: height), position: .init(x: (height + spacing) * .init($0), y: 0), sublayouts: nil)
                    })
                    
                    // And then add sublayout to the rows.
                    layouts.append(layout)
                    offset += height + spacing
                    index += template.0
                }
                
                // Merge everything into the main layout.
                return .init(layoutElement: self, size: .init(width: constrainedSize.max.width, height: max(offset - spacing, 0)), position: .zero, sublayouts: layouts)
            }
        }
        
        /// Create a display node using entity and events.
        required init(_ entity: NMEvent.Image, for event: NMEvent) {
            super.init()
            entity.items.forEach {
                let image = ASNetworkImageNode()
                image.defaultImage = timage1
                image.cornerRadius = 4
                image.backgroundColor = .random
                image.style.preferredSize = $0.size
                image.isLayerBacked = true
                addSubnode(image)
            }
        }
        
        /// Create a node for entity and event if needed.
        required convenience init?(_ entity: NMEventNodeEntityCompatible, for event: NMEvent) {
            // If the conversion fails, it means incompatibility.
            // If no found images, there is no need to create a display node.
            guard let entity = entity as? Entity, !entity.items.isEmpty else {
                return nil
            }
            self.init(entity, for: event)
        }
        
        /// Setup layout for all subnodes.
        override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
            return LayoutSpec().then {
                $0.spacing = 4
                $0.children = subnodes
                $0.singleLayoutSize = .init(min: .init(width: 170, height: 170),
                                            max: .init(width: 0, height: 280))
            }
        }
    }
    
    /// The video node for event.
    class Video: ASDisplayNode, NMEventNodeDisplayable {
        
        let action: ASImageNode = .init()
        let background: ASNetworkImageNode = .init()
        
        let title: ASTextNode = .init()
        let subtitle: ASTextNode = .init()
        let header: ASImageNode = .init()
        
        let total: ASButtonNode = .init()
        let duration: ASButtonNode = .init()
        let footer: ASImageNode = .init()

        /// Create a display node using entity and events.
        required init(_ entity: NMEvent.Video, for event: NMEvent) {
            super.init()
            
            self.cornerRadius = 8
            self.clipsToBounds = true

            self.action.image = #imageLiteral(resourceName: "cm6_play_icon_white_play")
            self.action.isLayerBacked = true

            self.addSubnode(self.background) {
                
                $0.backgroundColor = .random
                $0.isLayerBacked = true
                $0.defaultImage = timage2
                
                
                // self.video.url = URL(string: "https://github.com/texturegroup/texture/raw/master/docs/static/images/logo.png")
                // self.video.url = URL(string: "https://upload-images.jianshu.io/upload_images/327713-b99054ed55f90c30.png")

                   
                // self.video.url = URL(string: "https://p.upyun.com/demo/webp/animated-gif/0.gif")
                // self.video.url = URL(string: "https://p.upyun.com/demo/webp/webp/animated-gif-0.webp")
                   
                // self.video.url = URL(string: "https://raw.githubusercontent.com/qq2225936589/ImageDemos/master/demo01.webp")
                // self.video.url = URL(string: "https://raw.githubusercontent.com/qq2225936589/ImageDemos/master/demo01.gif")
                // self.video.url = URL(string: "https://p1.music.126.net/fiO_JXzIZ2gUxfVaHmOYyA==/2533274794531355.jpg")

                // self.video.url = URL(string: "https://p.upyun.com/demo/webp/webp/gif-0.webp")
                // self.video.url = URL(string: "https://p.upyun.com/demo/webp/webp/png-0.webp")

                //self.video.shouldAutoplay = true
                //self.video.shouldAutorepeat = false
                //self.video.shouldAggressivelyRecoverFromStall = false
                //self.video.isLayerBacked = true
                //self.video.assetURL = URL(string: "https://vfx.mtime.cn/Video/2019/03/14/mp4/190314223540373995.mp4")
                //self.video.assetURL = URL(string: "https://vfx.mtime.cn/Video/2019/07/25/mp4/190725150727428271.mp4")
            }
            
            self.addSubnode(self.header) {
                
                $0.image = #imageLiteral(resourceName: "cm2_mv_mask_top")
                $0.contentMode = .scaleToFill
                $0.style.height = ASDimensionMake(100)
                $0.isLayerBacked = true
                
                $0.addSubnode(self.title) {
                    $0.maximumNumberOfLines = 1
                    $0.truncationMode = .byTruncatingTail
                    $0.isLayerBacked = true
                    $0.attributedText = nmstr("Overture (Live at The Best Of Armin Only)", 15, UIColor(white: 1, alpha: 1)).then {
                        $0.insert(.init(attachment: NSTextAttachment2.mv), at: 0)
//                        $0.addAttribute(.font, value: UIFont.systemFont(ofSize: 15), range: NSMakeRange(0, 1))
                        $0.addAttributes($0.attributes(at: 1, effectiveRange: nil), range: NSMakeRange(0, 1))
                    }
                }
                $0.addSubnode(self.subtitle) {
                    $0.maximumNumberOfLines = 1
                    $0.truncationMode = .byTruncatingTail
                    $0.isLayerBacked = true
                    $0.attributedText = nmstr("Armin van Buuren", 12, UIColor(white: 1, alpha: 0.7))
                }

                $0.layoutSpecBlock = { [unowned title, unowned subtitle] _, _ in
                    return ASStackLayoutSpec.vertical(
                        title,
                        subtitle
                    ).insets(top: 4, left: 6, bottom: .infinity, right: 6)
                }
            }
            
            self.addSubnode(self.footer) {
                
                $0.image = #imageLiteral(resourceName: "cm2_mv_mask_btm")
                $0.contentMode = .scaleToFill
                $0.style.height = ASDimensionMake(100)
                $0.isLayerBacked = true
                
                $0.addSubnode(self.total) {
                    $0.contentSpacing = 2
                    $0.setImage(#imageLiteral(resourceName: "cm4_cover_icn_video"), for: .normal)
                    $0.setTitle("14941", with: UIFont.systemFont(ofSize: 12), with: UIColor.white, for: .normal)
                    $0.isLayerBacked = true
                }
                $0.addSubnode(self.duration) {
                    $0.contentSpacing = 2
                    $0.setImage(#imageLiteral(resourceName: "cm4_act_video_run_1"), for: .normal)
                    $0.setTitle("15:02", with: UIFont.systemFont(ofSize: 12), with: UIColor.white, for: .normal)
                    $0.isLayerBacked = true
                }
                
                $0.layoutSpecBlock = { [unowned total, unowned duration] _, _ in
                    return ASOverlayLayoutSpec.overlay(
                        total.insets(top: .infinity, left: 6, bottom: 4, right: .infinity),
                        duration.insets(top: .infinity, left: .infinity, bottom: 4, right: 6)
                    )
                }
            }
            
            self.addSubnode(self.action)
        }
        
        /// Setup layout for all subnodes.
        override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
            
            var overlays = [ASLayoutElement]()
            
            overlays.append(ASRatioLayoutSpec(ratio: 9 / 16, child: background))
            
            /// The footer contents may not be required.
            if footer.supernode === self {
                overlays.append(footer.insets(top: .infinity))
            }

            /// The header contents may not be required.
            if header.supernode === self {
                overlays.append(header.insets(bottom: .infinity))
            }
            
            overlays.append(ASCenterLayoutSpec(centeringOptions: .XY, sizingOptions: .minimumXY, child: action))
            
            
            return ASOverlayLayoutSpec.overlay(overlays)
        }
        
        
        @objc func play() {
        }
        
        @objc func stop() {
        }
    }

    /// The music node for event.
    class Music: ASDisplayNode, NMEventNodeDisplayable {
        
        let title: ASTextNode = .init()
        let subtitle: ASTextNode = .init()
        
        let icon: ASImageNode = .init()
        let image: ASNetworkImageNode = .init()
        let mask: ASImageNode = .init()

        /// Create a display node using entity and events.
        required init(_ entity: NMEvent.Music, for event: NMEvent) {
            super.init()
            
            self.backgroundColor = .init(white: 0, alpha: 0.2)
            self.cornerRadius = 8

            self.title.truncationMode = .byTruncatingTail
            self.title.maximumNumberOfLines = 1
            self.title.attributedText = nmstr(entity.title, 15, UIColor(white: 0, alpha: 0.8)).then {
                if entity.source == .playlist {
                    $0.insert(.init(attachment: NSTextAttachment2.playlist), at: 0)
                    $0.addAttributes($0.attributes(at: 1, effectiveRange: nil), range: NSMakeRange(0, 1))
                }
            }
            self.title.isLayerBacked = true

            self.subtitle.truncationMode = .byTruncatingTail
            self.subtitle.maximumNumberOfLines = 1
            self.subtitle.attributedText = nmstr(entity.subtitle, 12, UIColor(white: 0, alpha: 0.5))
            self.subtitle.isLayerBacked = true

            self.image.defaultImage = timage1
            self.image.cornerRadius = 4
            self.image.backgroundColor = .random
            self.image.style.preferredSize = .init(width: 40, height: 40)
            self.image.isLayerBacked = true

            self.addSubnode(self.image)

            switch entity.source {
            case .song:
                self.icon.image = #imageLiteral(resourceName: "cm2_list_cover_radio_play")
                self.icon.style.preferredSize = .init(width: 20, height: 20)
                self.icon.isLayerBacked = true
                self.addSubnode(self.icon)

            case .album:
                self.mask.image = #imageLiteral(resourceName: "cm2_act_cover_alb")
                self.mask.isLayerBacked = true
                self.addSubnode(self.mask)

            case .playlist:
                break
            }

            self.addSubnode(self.title)
            self.addSubnode(self.subtitle)
        }
        
        /// Setup layout for all subnodes.
        override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
            
            // Group 1 is album style, using image and mask layer.
            let group1 = mask.supernode.map { _ in
                ASOverlayLayoutSpec.overlay(
                    image.insets(right: 7),
                    mask
                )
            }
            // Group 2 is song style, using image and icon layer.
            let group2 = icon.supernode.map { _ in
                ASOverlayLayoutSpec.overlay(
                    image,
                    ASCenterLayoutSpec(centeringOptions: .XY, child: icon)
                )
            }
           
            let spec = ASStackLayoutSpec.horizontal(
                group1 ?? group2 ?? image,
                ASStackLayoutSpec.vertical(title, subtitle, spacing: 2, verticalAlignment: .center).then {
                    $0.style.flexShrink = 1
                    $0.style.flexGrow = 1
                },
                spacing: 8
            )
            
            return spec.insets(top: 8, left: 8, bottom: 8, right: 8)
        }
    }
    
    /// The referenced node for event.
    class Referenced: ASDisplayNode, NMEventNodeDisplayable {
        
        let tiles: [ASDisplayNode]

        /// Create a display node using entity and events.
        required init(_ entity: NMEvent.Referenced, for event: NMEvent) {
            
            self.tiles = NMEventNode.Display.parse(entity.tiles ?? [], for: event)

            super.init()
            
            self.cornerRadius = 8
            self.backgroundColor = .init(white: 0, alpha: 0.2)

            self.tiles.forEach {
                self.addSubnode($0)
            }
        }
        
        /// Setup layout for all subnodes.
        override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
            
            let spec = ASStackLayoutSpec.vertical().then {
                $0.spacing = 4
                $0.children = tiles
            }
            
            return spec.insets(top: 8, left: 8, bottom: 8, right: 8)
        }
    }
}


// MARK: -


/// The protocol specifies the display node for the entity object binding.
protocol NMEventNodeEntity: NMEventNodeEntityCompatible where Display: NMEventNodeDisplayableCompatible {
    /// The node type that is actually displayed.
    associatedtype Display
}

/// The protocol specifies the entity object  for the display node binding.
protocol NMEventNodeDisplayable: NMEventNodeDisplayableCompatible where Entity: NMEventNodeEntityCompatible {
    /// The entity type that is actually.
    associatedtype Entity
    
    /// Provides a way to create a display node using a real entity object.
    init(_ entity: Entity, for event: NMEvent)
}

/// Same as NMEventNodeEntity.
protocol NMEventNodeEntityCompatible {
    
    /// Provides a type method to get the display node for the current binding.
    var displayType: NMEventNodeDisplayableCompatible.Type { get }
}

/// Same as NMEventNodeDisplayable.
protocol NMEventNodeDisplayableCompatible {
    
    /// If the entity object is not compatible with the object required by the display node, it will return nil.
    init?(_ entity: NMEventNodeEntityCompatible, for event: NMEvent)
}

extension NMEventNodeEntity {
    
    /// Provides the default type binding.
    var displayType: NMEventNodeDisplayableCompatible.Type {
        return Display.self
    }
}

extension NMEventNodeDisplayable {
    
    /// Provide a default convert implementation.
    init?(_ entity: NMEventNodeEntityCompatible, for event: NMEvent) {
        // If the conversion fails, it means incompatibility.
        guard let entity = entity as? Entity else {
            return nil
        }
        self.init(entity, for: event)
    }
}


// MARK: -


fileprivate extension ASDisplayNode {

    func addSubnode<T: ASDisplayNode>(_ subnode: T, before: (T) -> Void) {
        before(subnode)
        addSubnode(subnode)
    }
}

fileprivate extension ASLayoutElement {
    
    func insets(_ edg: UIEdgeInsets) -> ASInsetLayoutSpec {
        return ASInsetLayoutSpec(insets: edg, child: self)
    }
    func insets(top: CGFloat = 0, left: CGFloat = 0, bottom: CGFloat = 0, right: CGFloat = 0) -> ASInsetLayoutSpec {
        return insets(.init(top: top, left: left, bottom: bottom, right: right))
    }

    func flexGrow(_ flexGrow: CGFloat) -> Self {
        self.style.flexGrow = flexGrow
        return self
    }

    func flexShrink(_ flexShrink: CGFloat) -> Self {
        self.style.flexShrink = flexShrink
        return self
    }
    
    func flexBasis(_ flexBasis: ASDimension) -> Self {
        self.style.flexBasis = flexBasis
        return self
    }
}

fileprivate extension ASOverlayLayoutSpec {
    
    static func overlay(_ children: [ASLayoutElement]) -> Self {
        // Initialize a layout spec.
        var last = self.init()
        last.child = children.first
        
        // If there is only one, don't to continue creating.
        if children.count < 2 {
            return last
        }

        // Merge all layout elements.
        last.overlay = children[1]
        for i in 2 ..< children.count {
            last = self.init(child: last, overlay: children[i])
        }
        return last
    }
    
    static func overlay(_ children: ASLayoutElement...) -> Self {
        return overlay(children)
    }
}

fileprivate extension ASStackLayoutSpec {

    static func vertical(_ children: ASLayoutElement..., spacing: CGFloat = 0, horizontalAlignment: ASHorizontalAlignment = .none, verticalAlignment: ASVerticalAlignment = .none) -> Self {
        let layout = self.vertical()
        layout.children = children
        layout.spacing = spacing
        layout.horizontalAlignment = horizontalAlignment
        layout.verticalAlignment = verticalAlignment
        return layout
    }

    static func horizontal(_ children: ASLayoutElement..., spacing: CGFloat = 0, horizontalAlignment: ASHorizontalAlignment = .none, verticalAlignment: ASVerticalAlignment = .none) -> Self {
        let layout = self.horizontal()
        layout.children = children
        layout.spacing = spacing
        layout.horizontalAlignment = horizontalAlignment
        layout.verticalAlignment = verticalAlignment
        return layout
    }
}



fileprivate extension NSTextAttachment2 {
    
    static let mv = NSTextAttachment2().then {
        $0.title = .init(string: "MV", attributes: [
            .font: UIFont.systemFont(ofSize: 9),
            .foregroundColor: UIColor.white
        ])
        $0.alignment = .center
        $0.border = 1 / UIScreen.main.scale
        $0.borderColor = .white
        $0.cornerRadius = 2
        $0.padding = .init(top: 0, left: 3, bottom: 0, right: 3)
        $0.margin = .init(top: 0, left: 0, bottom: 0, right: 2)
    }
    
    static let playlist = NSTextAttachment2().then {
        let color = #colorLiteral(red: 1, green: 0.2274509804, blue: 0.2274509804, alpha: 1)
        $0.title = .init(string: "歌单", attributes: [
            .font: UIFont.systemFont(ofSize: 9),
            .foregroundColor: color
        ])
        $0.alignment = .center
        $0.border = 1 / UIScreen.main.scale
        $0.borderColor = color
        $0.cornerRadius = 2
        $0.padding = .init(top: 0, left: 2, bottom: 0, right: 2)
        $0.margin = .init(top: 0, left: 0, bottom: 0, right: 2)
    }

    static let link = NSTextAttachment2().then {
        $0.image = #imageLiteral(resourceName: "cm2_act_icn_link")
        $0.alignment = .bottom
        $0.margin = .init(top: 0, left: 2, bottom: 0, right: 2)
    }
    
}
