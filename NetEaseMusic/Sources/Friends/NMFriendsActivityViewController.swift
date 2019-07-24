//
//  NMFriendsActivityViewController.swift
//  NetEaseMusic
//
//  Created by SAGESSE on 2019/8/16.
//  Copyright © 2019 SAGESSE. All rights reserved.
//

import UIKit
import AsyncDisplayKit


class NMFriendsNode: ASCellNode {
    
    class Header: ASDisplayNode {
        static let timage =  #imageLiteral(resourceName: "user_head")

        let portrait: ASImageNode = .init()
        let title: ASTextNode = .init()
        let subtitle: ASTextNode = .init()
        
        override init() {
            super.init()
            
            self.portrait.cornerRadius = 20
            //self.portrait.backgroundColor = .random
            self.portrait.image = type(of: self).timage
            self.portrait.style.preferredSize = .init(width: 40, height: 40)
            
            //self.title.backgroundColor = .random
            self.title.maximumNumberOfLines = 1
            self.title.attributedText = .init(string: "Title")

            //self.subtitle.backgroundColor = .random
            self.subtitle.maximumNumberOfLines = 1
            self.subtitle.attributedText = .init(string: "Subtitle")

            self.addSubnode(self.portrait)
            self.addSubnode(self.title)
            self.addSubnode(self.subtitle)
        }
        
        override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
            return ASStackLayoutSpec.horizontal().then {
                
                $0.spacing = 10
                $0.children = [
                    portrait,
                    ASStackLayoutSpec.vertical().then {
                        $0.spacing = 5
                        $0.style.flexGrow = 1
                        $0.style.flexShrink = 1
                        $0.children = [title, subtitle]
                        $0.verticalAlignment = .center
                    }
                ]
            }
        }
    }
    
    class Content: ASDisplayNode {
        
        class Text: Content {
            var contentsx: ASTextNode = .init()

            override func setup(_ indexPath: IndexPath) {
                //contentsx.backgroundColor = .random
                contentsx.attributedText = .init(string: "* iPhone XR pricing is after trade‑in of iPhone 7 Plus in good condition. Monthly pricing requires a 24‑month installment loan with a 0% APR, and iPhone activation. Applicable sales tax and fees due at time of purchase. Last payment may be less depending on remaining balance. Additional trade‑in values require purchase of a new iPhone, subject to availability and limits. You must be at least 18 years old. In‑store trade‑in requires presentation of a valid, government‑issued photo ID (local law may require saving this information). Additional terms from Apple or Apple’s trade‑in partners may apply. Full terms apply.", attributes: [.font: UIFont.systemFont(ofSize: 16)])
                addSubnode(contentsx)
            }

        }
        
        class Image: Content {
            
            static let timage =  #imageLiteral(resourceName: "ap2")
            
            override func setup(_ indexPath: IndexPath) {
                (0 ..< (indexPath.item % 10) + 1).forEach { _ in
                    let i = ASImageNode()
                    i.backgroundColor = .random
                    i.image = type(of: self).timage
                    i.cornerRadius = 4
                    //i.style.preferredSize = .init(width: 1280, height: 1080)
                    addSubnode(i)
                }
            }
            
            override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
                return NMAlbumsLayoutSpec().then {
                    $0.spacing = 4
                    $0.children = subnodes
                    $0.singleLayoutSize = .init(min: .init(width: 170, height: 170),
                                                max: .init(width: 0, height: 280))
                }
            }
        }
        
        class Music: Content {
            
            var title: ASTextNode = .init()
            var subtitle: ASTextNode = .init()

            
            var cover: ASImageNode = .init()
            static let timage =  #imageLiteral(resourceName: "user_head")

            override func setup(_ indexPath: IndexPath) {
                self.backgroundColor = .init(white: 0, alpha: 0.2)
                self.cornerRadius = 8
                self.style.preferredSize = .init(width: 0, height: 56)

                self.title.attributedText = .init(string: "Title", attributes: [.font: UIFont.systemFont(ofSize: 15)])
                self.subtitle.attributedText = .init(string: "Subtitle", attributes: [.font: UIFont.systemFont(ofSize: 12)])

                self.cover.image = type(of: self).timage
                self.cover.cornerRadius = 4
                
                self.addSubnode(self.cover)
                self.addSubnode(self.title)
                self.addSubnode(self.subtitle)
            }
            override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
                return ASInsetLayoutSpec(insets: .init(top: 8, left: 8, bottom: 8, right: 8), child: ASStackLayoutSpec.horizontal().then {
                    let v = ASStackLayoutSpec.vertical().then {
                        $0.style.flexGrow = 1
                        $0.spacing = 2
                        $0.children = [title, subtitle]
                        $0.verticalAlignment = .center
                    }
                    
                    let l =  ASRatioLayoutSpec(ratio: 1, child: self.cover).then {
                        $0.style.flexShrink = 1
                    }
                    $0.spacing = 8
                    $0.children = [l, v]
                })
                
            }
        }
        
        class Video: Content {
            
            var player: ASImageNode = .init()
            
            static let timage =  #imageLiteral(resourceName: "txs")
            
            override func setup(_ indexPath: IndexPath) {
                player.cornerRadius = 8
                player.backgroundColor = .random
                player.image = type(of: self).timage
                addSubnode(player)
            }

            override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
                return ASRatioLayoutSpec().then {
                    $0.ratio = 9 / 16
                    $0.child = player
                }
            }
            
        }
        
        class Referenced: Content {
            override func setup(_ indexPath: IndexPath) {
                
                self.backgroundColor = .init(white: 0, alpha: 0.2)
                self.cornerRadius = 8

                self.addSubnode(Text())
                self.addSubnode(Image())
                self.addSubnode(Video())
                self.addSubnode(Music())
                
                subnodes?.forEach {
                    ($0 as? Content)?.setup(indexPath)
                }
            }
            override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
                return ASInsetLayoutSpec(insets: .init(top: 8, left: 8, bottom: 8, right: 8),
                                         child: super.layoutSpecThatFits(constrainedSize))
            }
        }
        
        override init() {
            super.init()
//            self.backgroundColor = .random
        }
        
        override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
            return ASStackLayoutSpec.vertical().then {
                $0.spacing = 4
                $0.children = subnodes
            }
        }
        
        func setup(_ indexPath: IndexPath) {
            
            self.addSubnode(Text())
            self.addSubnode(Image())
            self.addSubnode(Video())
            self.addSubnode(Music())
            self.addSubnode(Referenced())

            subnodes?.forEach {
                ($0 as? Content)?.setup(indexPath)
            }
        }
    }
    
    class Footer: ASDisplayNode {
        override init() {
            super.init()
            self.style.preferredSize = .init(width: 0, height: 32)
            self.backgroundColor = .random
        }
    }
    
    
    let header: Header = .init()
    let content: Content = .init()
    let footer: Footer = .init()
    
    
    convenience init(_ indexPath: IndexPath) {
        self.init()
        
        self.addSubnode(self.header)
        self.addSubnode(self.content)
        self.addSubnode(self.footer)
        
        self.content.setup(indexPath)
    }
    
    override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        return ASInsetLayoutSpec().then {

            $0.insets = .init(top: 16, left: 16, bottom: 16, right: 16)
            $0.child = ASStackLayoutSpec.vertical().then {
                
                $0.spacing = 4
                $0.children = [
                    ASInsetLayoutSpec(insets: .init(top: 0, left: 0, bottom: 0, right: 0), child: header),
                    ASInsetLayoutSpec(insets: .init(top: 0, left: 50, bottom: 0, right: 0), child: content),
                    ASInsetLayoutSpec(insets: .init(top: 0, left: 50, bottom: 0, right: 0), child: footer)
                ]
            }
        }
    }
}


class NMFriendsActivityViewController: UIViewController, ASTableDataSource, ASTableDelegate {

    let table = ASTableNode()
    
    override func loadView() {
        
        view = table.view
        
        table.view.separatorStyle = .none
        
        table.dataSource = self
        table.delegate = self

    }
    
    func tableNode(_ tableNode: ASTableNode, numberOfRowsInSection section: Int) -> Int {
        return 100
    }
    func tableNode(_ tableNode: ASTableNode, nodeBlockForRowAt indexPath: IndexPath) -> ASCellNodeBlock {
        return {
            let node = NMFriendsNode(indexPath)
            //node.backgroundColor = .random
            return node
        }
    }
}



class NMAlbumsLayoutSpec: ASLayoutSpec {
    
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
