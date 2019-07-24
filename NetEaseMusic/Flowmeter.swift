//
//  Flowmeter.swift
//  NetEaseMusic
//
//  Created by SAGESSE on 2019/11/7.
//  Copyright © 2019 SAGESSE. All rights reserved.
//

import UIKit

public class Flowmeter {
    
    public init(_ size: CGSize) {
        // Configure the box.
        self.res = [0: 0, size.width: size.height]
    }
    
    public var intrinsicContentSize: CGSize {
        // Count all the widths.
        let keys = res.keys.sorted { $0 < $1 }
        let width = keys[keys.count - 1]

        // Count all the heights except the last item.
        return keys[0 ..< keys.count - 1].reduce(.init(width: width, height: 0)) {
            return .init(width: $0.width, height: max($0.height, res[$1] ?? 0))
        }
    }
    
    public func into(_ size: CGSize) -> CGRect {
        // Sort from low to high & near to the far.
        let keys = res.keys.sorted { $0 < $1 }
        var values = keys.enumerated().map { (index: $0, offset: res[$1] ?? 0) }.sorted { $0.offset < $1.offset || $0.index < $1.index
        }
        
        // Configre the environment.
        var x1 = keys[values[0].index]
        var x2 = keys[values[0].index + 1]
        var y1 = values[0].offset
        var y2 = values[0].offset + size.height
        
        // The boundary is exceeded?
        if values.count > 2 && size.width > (x2 - x1) {
            // Can't fit, merge space.
            var ib = values[0].index
            var ie = values[0].index + 1

            while values.count > 2 {
                // Merge left space.
                while ib > 0, let y = res[keys[ib - 1]], y <= y1, (x2 - x1) < size.width {
                    ib -= 1
                    x1 = keys[ib]
                }
                // Merge right space.
                while ie < keys.count, let y = res[keys[ie]], y <= y1, (x2 - x1) < size.width {
                    ie += 1
                    x2 = keys[ie]
                }
                // When the space can fit, terminate the search.
                guard (x2 - x1) < size.width else {
                    break
                }
                // The first item is no longer valid.
                values.removeFirst()
                
                // Reset all environment.
                ib = values[0].index
                ie = values[0].index + 1
                y1 = values[0].offset
                y2 = values[0].offset + size.height
                x1 = keys[ib]
                x2 = keys[ie]
            }
            // Forced fit space.
            if values.count == 2 {
                ib = 0
                ie = keys.count - 1
                x1 = keys[ib]
                x2 = keys[ie]
            }
            // Remove vaild space.
            keys[ib + 1 ..< ie].forEach {
                res.removeValue(forKey: $0)
            }
        }
        
        // Check space usage.
        switch (x2 - x1) - size.width {
        case let dw where dw > 0:
            // Can fit, split space.
            res[x1] = y2
            res[x1 + size.width] = y1
            
        case let dw where dw < 0:
            // Forced fit.
            res[x1] = y2
            
        default:
            // Perfect fit.
            res[x1] = y2
        }
        
        return .init(x: x1, y: y1, width: size.width, height: size.height)
    }
    
    private var res: [CGFloat: CGFloat]
}


//func testFlowmeter() {
//    
//    
//    let flowmeter = Flowmeter(.init(width: 375, height: .max))
//    
//    print("item:", flowmeter.into(.init(width: (375 / 4.0) * 1, height: 80)))
//    print("item:", flowmeter.into(.init(width: (375 / 4.0) * 1, height: 60)))
//    print("item:", flowmeter.into(.init(width: (375 / 4.0) * 1, height: 40)))
//    print("item:", flowmeter.into(.init(width: (375 / 4.0) * 1, height: 20)))
//    
//    print("item:", flowmeter.into(.init(width: (375 / 4.0) * 3, height: 20)))
//
//
//    print("item:", flowmeter.into(.init(width: 375 , height: 40)))
//
//    print("item:", flowmeter.into(.init(width: (375 / 4.0) * 1, height: 80)))
//
//    print("item:", flowmeter.into(.init(width: 375 , height: 40)))
//
//    print("item:", flowmeter.into(.init(width: (375 / 4.0) * 1, height: 80)))
//    print("item:", flowmeter.into(.init(width: (375 / 4.0) * 1, height: 120)))
//    print("item:", flowmeter.into(.init(width: (375 / 4.0) * 1, height: 160)))
//    //print("item:", flowmeter.into(.init(width: (375 / 4.0) * 1, height: 40)))
//
//    print("item:", flowmeter.into(.init(width: 375 , height: 40)))
//
//
//    print("item:", flowmeter.into(.init(width: (375 / 4.0) * 1, height: 160)))
//    print("item:", flowmeter.into(.init(width: (375 / 4.0) * 1, height: 120)))
//    print("item:", flowmeter.into(.init(width: (375 / 4.0) * 1, height: 80)))
//    //print("item:", flowmeter.into(.init(width: (375 / 4.0) * 1, height: 40)))
//
//    print("item:", flowmeter.into(.init(width: 375 , height: 40)))
//
//    print("item:", flowmeter.into(.init(width: 375 / 2.0, height: 40)))
//    print("item:", flowmeter.into(.init(width: 375 / 2.0, height: 40)))
//
//    print("item:", flowmeter.into(.init(width: 375 , height: 40)))
//
//    print("item:", flowmeter.into(.init(width: 375 / 3.0, height: 40)))
//    print("item:", flowmeter.into(.init(width: 375 / 3.0, height: 40)))
//    print("item:", flowmeter.into(.init(width: 375 / 3.0, height: 40)))
//
//    print("item:", flowmeter.into(.init(width: 375 , height: 40)))
//
//    print("item:", flowmeter.into(.init(width: 375 / 4.0, height: 40)))
//    print("item:", flowmeter.into(.init(width: 375 / 4.0, height: 80)))
//    print("item:", flowmeter.into(.init(width: 375 / 4.0, height: 120)))
//    print("item:", flowmeter.into(.init(width: 375 / 4.0, height: 160)))
//
//    print("item:", flowmeter.into(.init(width: 375 , height: 40)))
//
//    print("item:", flowmeter.into(.init(width: 375 / 4.0, height: 40)))
//    print("item:", flowmeter.into(.init(width: 375 / 4.0, height: 40)))
//    print("item:", flowmeter.into(.init(width: 375 / 4.0, height: 40)))
//
//    print("total:", flowmeter.intrinsicContentSize)
//}
