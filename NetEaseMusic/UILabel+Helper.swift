//
//  UILabel+Helper.swift
//  NetEaseMusic
//
//  Created by SAGESSE on 2019/8/12.
//  Copyright © 2019 SAGESSE. All rights reserved.
//

import UIKit


extension UILabel {
    
    open func nm_attributed(forImage named: String, arguments: [String: String]) -> Any? {
        guard let image = UIImage(named: named) else {
            return nil
        }
        guard let text = arguments["text"] else {
            return image
        }
        
        let font = nm_attribute(arguments, for: .font) as? UIFont ?? UIFont.systemFont(ofSize: UIFont.systemFontSize)
        let color = nm_attribute(arguments, for: .foregroundColor) as? UIColor ?? UIColor.black
        
        let mas = NSAttributedString(string: text, attributes: [.foregroundColor: color, .font: font])
        
        let left = arguments["text-left"].flatMap { Double($0).flatMap { CGFloat($0) }} ?? 0
        let top = arguments["text-top"].flatMap { Double($0).flatMap { CGFloat($0) }} ?? 0
        
        UIGraphicsBeginImageContextWithOptions(image.size, false, 0)
        UIGraphicsGetCurrentContext().map {
            // width: 32, height: 16, padding: 6
            $0.clear(.init(origin: .zero, size: image.size))
            image.draw(at: .zero)
            mas.draw(at: .init(x: left, y: top))
        }
        defer {
            UIGraphicsEndImageContext()
        }
        return UIGraphicsGetImageFromCurrentImageContext() ?? image
    }
    
    open func nm_attributed(_ type: String, named: String, arguments: [String: String]) -> Any? {
        
        if type == "img" {
            return nm_attributed(forImage: named, arguments: arguments)
        }
            
        return nil
    }
    
    @IBInspectable
    open var nm_text: String? {
        get { return self.text }
        set { 
            self.attributedText = newValue.map {
                return NSMutableAttributedString(format: $0) {
                    return nm_attributed($0, named: $1, arguments: $2) 
                }
            } 
        }
    }
}

extension NSMutableAttributedString {
    
    fileprivate convenience init(format: String, provider: (_ type: String, _ named: String, _ arguments: [String: String]) -> Any?) {
        // Build an empty string.
        self.init()
        
        var styles = [String: [(Int, String?)]]()
        var locations = [Int: [String: [String?]]]()
        
        var remaining = format.startIndex ..< format.endIndex
        while !remaining.isEmpty {
            // Look for begin anchor in the remaining string.
            guard let begin = format.range(of: "${", options: .caseInsensitive, range: remaining, locale: nil) else {
                break
            }
            // Look for end anchor in the remaining string.
            guard let end = format.range(of: "}", options: .caseInsensitive, range: begin.upperBound ..< remaining.upperBound, locale: nil) else {
                break
            }
            
            // Apply normal string.
            append(.init(string: .init(format[remaining.lowerBound ..< begin.lowerBound])))
            remaining = end.upperBound ..< remaining.upperBound
            
            // Access mode info
            let mode = format[begin.upperBound ..< end.lowerBound]
            let spaced = mode.firstIndex(of: ":") ?? mode.endIndex
            
            var named = ""
            var arguments = [String: String]()
            
            // Load arguments for URL.            
            URLComponents(string: mode[mode.index(after: spaced) ..< mode.endIndex].replacingOccurrences(of: "#", with: "%23")).map {
                $0.queryItems?.forEach {
                    arguments[$0.name] = $0.value ?? ""
                }
                named = $0.path
            }
            
            // Analysis parameter meaning.
            switch mode[..<spaced] {
            case "style" where named == "push":
                // Push some new style.
                arguments.forEach {
                    if styles[$0]?.append((length, $1)) == nil {
                        styles[$0] = [(length, $1)]
                    }
                }
                
            case "style" where named == "pop":
                // Pop all styles?
                guard !arguments.isEmpty else {
                    styles.keys.forEach { 
                        styles[$0]?.append((length, nil))
                    }
                    break
                }
                arguments.forEach {
                    styles[$0]?.append((length, $1))
                }
                
            case "img":
                // Load image.                
                guard let img = provider("img", named, arguments) as? UIImage ?? UIImage(named: named) else {
                    break
                }
                // Gets the placeholder.
                let x = arguments["x"].map { Double($0).map { CGFloat($0) }} ?? nil
                let y = arguments["y"].map { Double($0).map { CGFloat($0) }} ?? nil
                let w = arguments["width"].map { Double($0).map { CGFloat($0) }} ?? nil
                let h = arguments["height"].map { Double($0).map { CGFloat($0) }} ?? nil
                // Generate the attachment.
                let attachment = NSTextAttachment()
                attachment.image = img
                attachment.bounds = CGRect(x: x ?? 0, y: y ?? 0, width: w ?? img.size.width, height: h ?? img.size.height)
                append(.init(attachment: attachment))
                
            default:
                break
            }
            
            // Format at the end.
            guard remaining.lowerBound != format.endIndex && format[remaining.lowerBound] == "\n" else {
                continue
            }
            
            // Format is this line.
            guard begin.lowerBound == format.startIndex || format[format.index(before: begin.lowerBound)] == "\n" else {
                continue
            }
            
            // Ignore this line.
            remaining = format.index(after: remaining.lowerBound) ..< remaining.upperBound
        }
        
        // All attributes pop at the end.
        append(.init(string: .init(format[remaining])))
        styles.keys.forEach { 
            styles[$0]?.append((length, nil))
        }
        
        // Convert to an ordered attributes.
        styles.forEach { (key, values) in
            values.forEach { (location, value) in
                if locations[location] == nil {
                    locations[location] = [:]
                }
                if locations[location]?[key]?.append(value) == nil {
                    locations[location]?[key] = [value]
                }
            }
        }
        
        let keys: [NSAttributedString.Key] = [
            .font,
            .backgroundColor,
            .foregroundColor,
            .paragraphStyle
        ]
        
        var stack: [String: [String]] = [:]
        var setter: ((Int) -> Void)?
        
        locations.keys.sorted().forEach { (location) in
            locations[location]?.forEach { (key, values) in
                values.forEach { 
                    // Pop a value
                    guard let value = $0, !value.isEmpty else {
                        if !(stack[key]?.isEmpty ?? true) {
                            stack[key]?.removeLast()
                        }
                        return
                    }
                    // Push a value.
                    if stack[key]?.append(value) == nil {
                        stack[key] = [value]
                    }
                }
            }
            
            let last = nm_attributes(forAttributes: stack)
            
            
            setter?(location)
            setter = { end in
                keys.forEach { key in
                    nm_attribute(last, for: key).map {
                        self.addAttribute(key, value: $0, range: NSRange(location: location, length: end - location)) 
                    }
                }
            }
        }
    }
    
}

@inline(__always) private func nm_attributes(forAttributes attributes: [String: [String]]) -> [String: String] {
    var newAttributes = [String: String]()
    attributes.forEach { 
        newAttributes[$0] = $1.last
    }
    return newAttributes
}

@inline(__always) private func nm_attribute(_ attributes: [String: String], for key: NSAttributedString.Key) -> Any? {
    switch key {
    case .font:
        // Is custom size.
        let size = attributes["font-size"].map { Double($0).map { CGFloat($0) }} ?? nil
        
        // Is a custom font.
        if let name = attributes["font"] {
            return UIFont(name: name, size: size ?? UIFont.systemFontSize)
        }
        
        // Is a custom weight.
        let weight: UIFont.Weight
        switch attributes["font-weight"] {
        case "ultraLight":  weight = .ultraLight
        case "thin":        weight = .thin
        case "light":       weight = .light
        case "regular":     weight = .regular
        case "medium":      weight = .medium
        case "semibold":    weight = .semibold
        case "bold":        weight = .bold
        case "heavy":       weight = .heavy
        case "black":       weight = .black
        default:            weight = .regular
        }
        
        return size.map {
            return UIFont.systemFont(ofSize: $0, weight: weight) 
        } 
        
    case .foregroundColor:
        // Is a custom color.
        return attributes["color"].flatMap { 
            return Int($0.replacingOccurrences(of: "#", with: ""), radix: 16).map {
                return UIColor(red: .init(($0 >> 16) & 0xff) / 255.0,
                               green: .init(($0 >> 8) & 0xff) / 255.0,
                               blue: .init(($0 >> 0) & 0xff) / 255.0,
                               alpha: 1)
            }
        }
        
    case .backgroundColor:
        // Is a custom color.
        return attributes["background-color"].flatMap { 
            return Int($0.replacingOccurrences(of: "#", with: ""), radix: 16).map {
                return UIColor(red: .init(($0 >> 16) & 0xff) / 255.0,
                               green: .init(($0 >> 8) & 0xff) / 255.0,
                               blue: .init(($0 >> 0) & 0xff) / 255.0,
                               alpha: 1)
            }
        }
        
    case .paragraphStyle:
        // Is a custom style.
        let ls = attributes["line-space"].flatMap { Double($0).flatMap { CGFloat($0) }}
        let lh = attributes["line-height"].flatMap { Double($0).flatMap { CGFloat($0) }}
        
        // Is change? 
        if ls == nil && lh == nil {
            return nil
        }
        
        let paragraphStyle = NSMutableParagraphStyle()
        
        ls.map { paragraphStyle.lineSpacing = $0 }
        lh.map { 
            paragraphStyle.maximumLineHeight = $0
            paragraphStyle.minimumLineHeight = $0
        }
        
        return paragraphStyle

    default:
        return nil
    }
}
