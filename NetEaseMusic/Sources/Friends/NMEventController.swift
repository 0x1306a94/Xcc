//
//  NMEventController.swift
//  NetEaseMusic
//
//  Created by SAGESSE on 2020/1/13.
//  Copyright © 2020 SAGESSE. All rights reserved.
//

import UIKit
import AsyncDisplayKit


class NMEventController: ASViewController<ASTableNode>, ASTableDataSource, ASTableDelegate {
    
    override init(node: ASTableNode) {
        super.init(node: node)
        node.dataSource = self
        node.delegate = self
    }
    
    required init?(coder: NSCoder) {
        super.init(node: ASTableNode())
        node.dataSource = self
        node.delegate = self
    }
    
    func tableNode(_ tableNode: ASTableNode, numberOfRowsInSection section: Int) -> Int {
        return 100
    }
    
    func tableNode(_ tableNode: ASTableNode, nodeBlockForRowAt indexPath: IndexPath) -> ASCellNodeBlock {
        return {
            let event = NMEvent(indexPath.item)
            let node = NMEventNode(for: event)
            node.backgroundColor = .white// .random
            func fill(_ node: ASDisplayNode) {
                node.borderWidth = 1 / UIScreen.main.scale
                node.borderColor = UIColor.red.cgColor
                //if node.backgroundColor == nil {
                //    node.backgroundColor = UIColor.black.withAlphaComponent(0.2)
                //}
                node.subnodes?.forEach(fill)
            }
            //fill(node)
            return node
        }
    }
}


// MARK: -


class NMEventBadgeNode: ASDisplayNode {
    
    override init() {
        super.init()
        self.style.preferredSize = CGSize(width: 32, height: 12)
        self.backgroundColor = .random
        self.cornerRadius = 2
    }
}

//class NMEventAvatarNode: ASDisplayNode {
//
//    let avatar: ASImageNode = .init()
//
//    let background: ASImageNode = .init()
//    let foreground: ASImageNode = .init()
//
//    let badge: ASImageNode = .init()
//    let decorator: ASImageNode = .init()
//
//    var padding: UIEdgeInsets = .init(top: 9, left: 9, bottom: 9, right: 9)
//
//    override init() {
//        super.init()
//
//        self.addSubnode(self.background)
//        self.addSubnode(self.avatar)
//        self.addSubnode(self.foreground)
//        self.addSubnode(self.decorator)
//        self.addSubnode(self.badge)
//
//        self.style.preferredSize = CGSize(width: 58, height: 58)
//
//        self.background.backgroundColor = .random
//        self.background.cornerRadius = max(self.style.preferredSize.width - padding.left - padding.right - 2, 0) / 2
//
//        self.badge.backgroundColor = .random
//        self.badge.cornerRadius = 8
//
//        self.badge.style.preferredSize = .init(width: 16, height: 16)
//    }
//
//    /// Setup layout for all subnodes.
//    override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
//        return ASOverlayLayoutSpec.overlay(
//            background.insets(top: padding.top + 1, left: padding.left + 1, bottom: padding.bottom + 1, right: padding.right + 1),
//            avatar.insets(padding),
//            foreground.insets(padding),
//            decorator,
//            badge.insets(top: .infinity, left: .infinity, bottom: padding.bottom, right: padding.right - 5)
//        )
//    }
//}
