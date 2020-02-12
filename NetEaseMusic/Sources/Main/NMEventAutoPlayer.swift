//
//  NMEventAutoPlayer.swift
//  NetEaseMusic
//
//  Created by SAGESSE on 2020/2/12.
//  Copyright © 2020 SAGESSE. All rights reserved.
//

import UIKit
import AsyncDisplayKit


/// The protocol defines whether the display node supports autoplay.
protocol NMEventAutoPlayable: class {

    func play()
    func stop()
}


class NMEventAutoPlayer {
    
    typealias Key = CGRect
    typealias Value = NMEventNode
    
    class Element {
        
        var key: Key
        var value: Value
        var sublayouts: [Key]?

        unowned(unsafe)
        var prev: Element?
        var next: Element?
        
        init(value: Value, for key: Key) {
            self.key = key
            self.value = value
        }
    }
    class Scheduler {

        func delay(_ seconds: TimeInterval, callback: @escaping () -> ()) {
            // Reuse actived timer.
            if self.timer == nil {
                let timer = Timer.scheduledTimer(timeInterval: seconds, target: self, selector: #selector(tick), userInfo: nil, repeats: false)
                RunLoop.main.add(timer, forMode: .tracking)
                self.timer = timer
            }
            
            // Reset the callback and timer fire date.
            self.timer?.fireDate = Date(timeIntervalSinceNow: seconds)
            self.callback = callback
        }
        
        @objc
        private func tick() {
            // Clear the set time to prevent circular references.
            self.timer?.invalidate()
            self.timer = nil
            // Perform user callback.
            self.callback?()
            self.callback = nil
        }
        
        private var timer: Timer?
        private var callback: (() -> ())?
    }
    
    var isEmpty: Bool {
        return head == nil
    }
        
    func add(_ value: Value, for key: Key) {
        // Look up the left node.
        let node = Element(value: value, for: key)
        guard let left = find(forKey: key) else {
            // The left node not found, add to head.
            node.next = head
            head?.prev = node
            head = node
            if tail == nil {
                tail = node
            }
            return
        }
        
        // When node change must adjus node chain.
        let right = left.next
        right?.prev = node
        node.next = left.next
        left.next = node
        node.prev = left
        
        // Move tail node cursor.
        if tail === left {
            tail = node
        }
    }
    func remove(_ value: Value) {
        // The key exists in the chain.
        guard let node = find(forValue: value) else {
            return
        }
        
        // When node change must adjus node chain.
        node.prev?.next = node.next
        node.next?.prev = node.prev
        
        // Head node is removed, reset head.
        if head === node {
            head = node.next
        }
        // Tail node is revmoved, reset tail.
        if tail === node {
            tail = node.prev
        }
        
        // If the removed node is playing, must stop playing.
        if cur?.node === node {
            stop()
        }
    }
    
    func play(_ visible: CGRect) {
        // Find the first playable node.
        guard let (node, playable) = find(in: visible) else {
            // When no any node found, stop the current playing node if needed.
            return stop()
        }
        
        // Ignore the current play node if it has not changes.
        guard cur?.node !== node || cur?.playable !== playable else {
            return
        }
        
        // Stop play immediately.
        stop()
        cur = (node, playable)

        // Start play in 800ms after.
        scheduler.delay(0.8) {
            // If current node is changes, ignore this action.
            guard self.cur?.playable === playable else {
                return
            }
            self.active = playable
            playable.play()
        }
    }
    func stop() {
        cur = nil
        active?.stop()
        active = nil
    }
    
    private func find(forKey key: Key) -> Element? {
        
        var left = head
        var right = tail
        
        while left != nil || right != nil {

            if let right = right, right.key.minY < key.minY {
                return right
            }
            if left === right {
                return left?.prev
            }
            if let left = left, left.key.minY > key.minY {
                return left.prev
            }
            if left?.next === right {
                return left
            }
            
            left = left?.next
            right = right?.prev
            
            print("ov1")
        }
        
        return nil
    }
    private func find(forValue value: Value) -> Element? {
        
        var left = head
        var right = tail
        
        while left != nil || right != nil {

            if let right = right, right.value === value {
                return right
            }
            if left === right {
                return nil
            }
            if let left = left, left.value === value {
                return left
            }
            if left?.next === right {
                return nil
            }
            
            left = left?.next
            right = right?.prev
            
            print("ov2")
        }
        
        return nil
    }
    
    private func find(in visible: CGRect) -> (Element, NMEventAutoPlayable)? {
        
        var left = head
        
        while let event = left, !event.value.playable.isEmpty {
            // Ignore the event when the rect displayed do not intersect.
            if !visible.intersects(event.key) {
                left = left?.next
                continue
            }
            
            // Compute all the layout information for playable node.
            if event.sublayouts == nil {
                event.sublayouts = event.value.playable.compactMap {
                    return ($0 as? ASDisplayNode).map {
                        return $0.convert($0.bounds, to: event.value)
                    }
                }
            }
            
            // If the minY than half of the playable node, can't star this node.
            let minY = visible.minY - event.key.minY
            let maxY = minY + visible.height
            guard let index = event.sublayouts?.firstIndex(where: { minY <= $0.midY && $0.midY <= maxY }) else {
                left = left?.next
                continue
            }
            return (event, event.value.playable[index])
        }
        return nil
    }
    
    private var head: Element?
    private var tail: Element?
    
    private var cur: (node: Element, playable: NMEventAutoPlayable)?
    private var active: NMEventAutoPlayable?
    private var scheduler: Scheduler = .init()
}

