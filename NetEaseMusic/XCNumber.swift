//
//  XCNumber.swift
//  XCNumber
//
//  Created by SAGESSE on 2019/5/18.
//  Copyright © 2019 SAGESSE. All rights reserved.
//

import UIKit

struct XCNumber: SignedNumeric, Comparable, CustomStringConvertible {
    
    init() {
        self.isSigned = false
        self.integers = []
    }
    init(_ source: XCNumber) {
        self.isSigned = source.isSigned
        self.integers = source.integers
    }
    
    // MARK: Numeric
    
    /// Creates an integer from the given floating-point value, if it can be represented exactly.
    init?<T>(exactly source: T) where T : BinaryInteger {
        guard let value = IntegerLiteralType(exactly: source) else {
            return nil
        }
        self.isSigned = value < 0
        self.integers = XCNumber.i2b(UInt64(bitPattern: value))
    }
    
    /// A type that can represent the absolute value of any possible value of the conforming type.
    typealias Magnitude = XCNumber
    
    /// The magnitude of this value.
    var magnitude: XCNumber {
        if self.isSigned {
            return -self
        }
        return self
    }
    
    /// Replaces this value with its additive inverse.
    mutating func negate() {
        var cf = 1
        for pos in 0 ..< integers.count {
            let rax = (~self[pos] & XCNumber.mask) + cf
            self[pos] = rax
            cf = rax &>> XCNumber.nbits
        }
        isSigned = (integers.last ?? 0) & 0x80 != 0
    }
    
    
    // MARK: ExpressibleByIntegerLiteral
    
    
    /// A type that represents an integer literal.
    typealias IntegerLiteralType = Int64
    
    /// Creates an instance initialized to the specified integer value.
    init(integerLiteral value: IntegerLiteralType) {
        self.isSigned = value < 0
        self.integers = XCNumber.i2b(UInt64(bitPattern: value))
    }
    
    static func + (lhs: XCNumber, rhs: XCNumber) -> XCNumber {
        var cf = 0
        var result = XCNumber()
        for pos in 0 ..< max(lhs.integers.count, rhs.integers.count) {
            let rax = lhs[pos] + rhs[pos] + cf
            result[pos] = rax
            cf = rax &>> XCNumber.nbits
        }
        let maximum = (lhs[.max] + rhs[.max] + cf) & XCNumber.mask
        result.isSigned = maximum & 0x80 != 0 // 最高位的值是否为1, 如果为1说明结果是负数
        if maximum != 0 {
            result.integers.append(.init(truncatingIfNeeded: maximum)) // 如果是结果是非负数，需要保存进位
        }
        return result
    }
    static func - (lhs: XCNumber, rhs: XCNumber) -> XCNumber {
        return lhs + -rhs
    }
    static func * (lhs: XCNumber, rhs: XCNumber) -> XCNumber {
        guard !lhs.isZero && !rhs.isZero else {
            return XCNumber() // 如果任何一个数为0都不需要计算
        }
        return XCNumber.calculator(lhs, rhs) { lhs, rhs in
            var result = XCNumber()
            for row in 0 ..< rhs.integers.count {
                var cf = 0
                var pos = row
                for column in 0 ..< lhs.integers.count {
                    let rax = result[pos] + lhs[column] * rhs[row] + cf
                    result[pos] = rax
                    pos += 1
                    cf = rax &>> XCNumber.nbits
                }
                while cf != 0 {
                    let rax = result[pos] + cf
                    result[pos] = rax
                    pos += 1
                    cf = rax &>> XCNumber.nbits
                }
            }
            return result
        }
    }
    static func / (lhs: XCNumber, rhs: XCNumber) -> XCNumber {
        guard !rhs.isZero else {
            fatalError("0不能作为除数")
        }
        guard !lhs.isZero else {
            return XCNumber() // 如果被除数为0, 不需要处理
        }
        return XCNumber.calculator(lhs, rhs) { lhs, rhs in
            var bit = lhs.integers.count * 8 - 1 // 因为是小于count * 8
            var result = XCNumber()
            var remainder = XCNumber(lhs)
            var divisor = rhs << bit  // 移动到最左边(乘N)
            while bit >= 0 {
                if divisor <= remainder {
                    result.set(1, at: bit) // 直接设置比特位
                    remainder -= divisor
                }
                bit = bit - 1
                divisor = divisor >> 1 // 向右移动(恢复)
            }
            return result
        }
    }
    
    static func += (lhs: inout XCNumber, rhs: XCNumber) {
        lhs = lhs + rhs
    }
    static func -= (lhs: inout XCNumber, rhs: XCNumber) {
        lhs += -rhs
    }
    static func *= (lhs: inout XCNumber, rhs: XCNumber) {
        lhs = lhs * rhs
    }
    static func /= (lhs: inout XCNumber, rhs: XCNumber) {
        lhs = lhs / rhs
    }
    
    static func << <RHS>(lhs: XCNumber, rhs: RHS) -> XCNumber where RHS : BinaryInteger {
        // 计算需要移动的字节和比特位
        let byte = Int(rhs / 8)
        let bit = Int(rhs % 8)
        
        var carry = UInt(0)
        var result = XCNumber(lhs)
        
        result.integers = Array(repeating: 0, count: byte)
        result.integers += lhs.integers.map {
            let rax = carry + UInt($0) << bit
            carry = rax &>> XCNumber.nbits
            return Byte(truncatingIfNeeded: rax)
        }
        
        result.integers += XCNumber.i2b(carry) // 保存多出来的进位
        return result
    }
    static func >> <RHS>(lhs: XCNumber, rhs: RHS) -> XCNumber where RHS : BinaryInteger {
        // 计算需要移动的字节和比特位
        let byte = Int(rhs / 8)
        let bit = Int(rhs % 8)
        
        var carry = UInt(0)
        var result = XCNumber(lhs)
        
        result.integers = lhs.integers[byte ..< lhs.integers.count].reversed().map {
            let rax = carry + UInt($0) >> bit
            carry = (UInt($0) << 8) >> bit & 0xff
            return Byte(truncatingIfNeeded: rax)
        }.reversed()
        
        return result
    }
    
    // MARK: Comparable
    
    static func == (lhs: XCNumber, rhs: XCNumber) -> Bool {
        guard lhs.isSigned == rhs.isSigned else {
            return false // 正负不同, 肯定是不等的
        }
        for index in 0 ..< max(max(lhs.integers.count, rhs.integers.count), 1) {
            if lhs[index] != rhs[index] {
                return false
            }
        }
        return true
    }
    
    static func < (lhs: XCNumber, rhs: XCNumber) -> Bool {
        guard lhs.isSigned == rhs.isSigned else {
            return lhs.isSigned
        }
        for index in (0 ..< max(max(lhs.integers.count, rhs.integers.count), 1)).reversed() {
            let a = lhs[index]
            let b = rhs[index]
            if a < b {
                return true
            }
            if a > b {
                return false
            }
        }
        return false
    }
    static func <= (lhs: XCNumber, rhs: XCNumber) -> Bool {
        guard lhs.isSigned == rhs.isSigned else {
            return lhs.isSigned
        }
        for index in (0 ..< max(max(lhs.integers.count, rhs.integers.count), 1)).reversed() {
            let a = lhs[index]
            let b = rhs[index]
            if a < b {
                return true
            }
            if a > b {
                return false
            }
        }
        return true
    }
    
    
    private static func calculator(_ lhs: XCNumber, _ rhs: XCNumber, transform: (XCNumber, XCNumber) -> XCNumber) -> XCNumber {
        guard lhs.isSigned == rhs.isSigned else {
            return -transform(abs(lhs), abs(rhs))
        }
        return transform(abs(lhs), abs(rhs)) // 正正得正，负负得正
    }
    
    private mutating func set(_ flag: Byte, at pos: Int) {
        // 计算需要移动的字节和比特位
        let byte = Int(pos / 8)
        let bit = Int(pos % 8)
        if byte >= integers.count {
            let count = byte - integers.count + 1
            integers.append(contentsOf: Array(repeating: 0, count: count)) // 填充空白区域
        }
        if flag != 0 {
            integers[byte] = integers[byte] | (flag << bit)
        } else {
            integers[byte] = integers[byte] & ~(flag << bit)
        }
    }
    
    private static func i2b<Other>(_ value: Other) -> Array<Byte> where Other : UnsignedInteger  {
        var bytes = Array<Byte>()
        var remainder = value
        
        while remainder != 0 {
            bytes.append(Byte(truncatingIfNeeded: remainder))
            remainder = remainder >> Other(truncatingIfNeeded: XCNumber.nbits)
        }
        
        return bytes
    }
    
    private static func bytes2decimal(_ bytes: Array<Byte>) -> String {
        guard bytes.contains(where: { $0 != 0 } ) else {
            return "0" // 0不需要计算
        }
        var numbers = Array<Int16>() // 0 - 9999, max 32768
        for byte in bytes.reversed() {
            var pos = 0
            var psw = Int(byte) & XCNumber.mask
            while pos < numbers.count {
                let rax = Int(numbers[pos]) * 256 + psw
                numbers[pos] = .init(rax % 10000)
                psw = rax / 10000
                pos += 1
            }
            while psw != 0 {
                numbers.append(.init(psw % 10000))
                psw = psw / 10000
            }
        }
        return numbers.reversed().reduce("") {
            let value = Int($1) & 0xffff
            if $0.isEmpty {
                return $0 + String(format: "%d", value)
            }
            return $0 + String(format: "%04d", value)
        }
    }
    
    var description: String {
        
        guard !isZero else {
            return "0" // 0不需要计算
        }
        guard !isSigned else {
            return "-" + (-self).description // 如果是负数, 取反再处理
        }
        return XCNumber.bytes2decimal(integers)
    }
    
    private subscript(_ pos: Int) -> Int {
        set {
            if pos < integers.count  {
                return integers[pos] = Byte(truncatingIfNeeded: newValue)
            }
            return integers.append(Byte(truncatingIfNeeded: newValue))
        }
        get {
            if pos < integers.count {
                return Int(integers[pos]) & XCNumber.mask
            }
            if isSigned {
                return -1 & XCNumber.mask // 负数的整数部分补ff
            }
            return 0
        }
    }
    
    private var isSigned: Bool = false
    private var isZero: Bool {
        return !integers.contains { $0 != 0 }
    }
    
    private var integers: Array<Byte>
    
    private static let mask: Int = (1 << XCNumber.nbits) - 1
    private static let nbits: Int = MemoryLayout<Byte>.size * 8
    
    private typealias Byte = UInt8
}


func XCNumber_test() {
    
    assert((XCNumber(0xeeff) < XCNumber(0xffee)) == true)
    assert((XCNumber(0xffff) < XCNumber(0xeeee)) == false)
    assert((XCNumber(0xeeee) < XCNumber(0xffff)) == true)
    assert((XCNumber(1) < XCNumber(1)) == false)
    assert((XCNumber(-1) < XCNumber(-1)) == false)
    assert((XCNumber(-1) < XCNumber(1)) == true)
    assert((XCNumber(1) < XCNumber(-1)) == false)
    
    assert((XCNumber(0) - XCNumber(0)).description == "0")
    assert((XCNumber(1) - XCNumber(1)).description == "0")
    assert((XCNumber(0) - XCNumber(1)).description == "-1")
    assert((XCNumber(-1) - XCNumber(-1)).description == "0")
    assert((XCNumber(-1) - XCNumber(1)).description == "-2")
    assert((XCNumber(5000000000000) - XCNumber(1)).description == "4999999999999")
    assert((XCNumber(0) - XCNumber(5000000000000)).description == "-5000000000000")

    assert((XCNumber(-5000000000000) * XCNumber(-5000000000000)).description == "25000000000000000000000000")
    assert((XCNumber(-5000000000000) * XCNumber(5000000000000)).description == "-25000000000000000000000000")
    assert((XCNumber(5000000000000) * XCNumber(-5000000000000)).description == "-25000000000000000000000000")
    assert((XCNumber(5000000000000) * XCNumber(0)).description == "0")
    assert((XCNumber(0) * XCNumber(-5000000000000)).description == "0")
    assert((XCNumber(183524) * XCNumber(889290140324)).description == "163206083712821776")

    assert((XCNumber(163206083712821776) / XCNumber(889290140324)).description == "183524")
    assert((XCNumber(1) / XCNumber(99)).description == "0")
    assert((XCNumber(-5000000000000) / XCNumber(-5000000000000)).description == "1")
    assert((XCNumber(0xffffff) / XCNumber(0xfe)).description == "66052")


}
