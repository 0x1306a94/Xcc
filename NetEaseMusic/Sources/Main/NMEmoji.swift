//
//  NMEmojiCoder.swift
//  NetEaseMusic
//
//  Created by SAGESSE on 2020/2/3.
//  Copyright © 2020 SAGESSE. All rights reserved.
//

import UIKit
import CommonCrypto


class NMBundle {
    
    static let shared: NMBundle = .init()
    
    func host() -> String {
        return "https://p2.music.126.net"
    }

    func url(forImageIdentifier imageId: String, withExtension ext: String = "jpg") -> URL? {
        return nm_md5_encode(imageId).flatMap {
            return URL(string: "\(host())/\($0)/\(imageId).\(ext)")
        }
    }
}

class NMEmoji {
    
    static let shared: NMEmoji = .init()
    
    
    func name(for emoji: String) -> String? {
        return e2n[emoji]
    }

    func emoji(for name: String) -> String? {
        return n2e[name]
    }
    
    func image(for custom: String) -> UIImage? {
        return nil
    }
    
    
    func url(for custom: String) -> URL? {
        return c2i[custom].flatMap {
            return NMBundle.shared.url(forImageIdentifier: $0)
        }
    }
    
    
    private init() {
        // Load predefined named emojis.
        let name = "大笑,可爱,憨笑,色,亲亲,惊恐,流泪,亲,呆,哀伤,呲牙,吐舌,撇嘴,怒,奸笑,汗,痛苦,惶恐,生病,口罩,大哭,晕,发怒,开心,鬼脸,皱眉,流感,爱心,心碎,钟情,星星,生气,便便,强,弱,拜,牵手,跳舞,禁止,这边,爱意,示爱,嘴唇,狗,猫,猪,兔子,小鸡,公鸡,幽灵,圣诞,外星,钻石,礼物,男孩,女孩,蛋糕,18,圈,叉".components(separatedBy: ",")
        let emoji = "😃😊☺😍😘😱😭😚😳😔😁😝😒😡😏😓😖😰😨😷😂😲👿😄😜😞😢❤💔💘🌟💢💩👍👎🙏👫👯🙅💁💏💑👄🐶🐱🐷🐰🐤🐔👻🎅👽💎🎁👦👧🎂🔞⭕❌".map { "\($0)" }

        // Generate a quick query table.
        self.n2e = .init(uniqueKeysWithValues: (0 ..< min(name.count, emoji.count)).map { (name[$0], emoji[$0]) })
        self.e2n = .init(uniqueKeysWithValues: (0 ..< min(name.count, emoji.count)).map { (emoji[$0], name[$0]) })
        
        // Generat a custom emoji table.
        self.c2i = [
            "多多亲吻": "109951163626285824",
            "多多可怜": "109951163626289680",
            "多多大哭": "109951163626288209",
            "多多大笑": "109951163626285326",
            "多多捂脸": "109951163626287335",
            "多多无语": "109951163626291589",
            "多多比耶": "109951163626291112",
            "多多瞌睡": "109951163626285332",
            "多多笑哭": "109951163626295026",
            "多多耍酷": "109951163626286808",
            "多多调皮": "109951163626288207",
            "多多难过": "109951163626282475",
            "西西再见": "109951163626290116",
            "西西发怒": "109951163626291586",
            "西西呕吐": "109951163626287760",
            "西西奸笑": "109951163626285329",
            "西西心动": "109951163626284860",
            "西西惊吓": "109951163626292571",
            "西西惊讶": "109951163626290613",
            "西西晕了": "109951163626294527",
            "西西机智": "109951163626295022",
            "西西流汗": "109951163626281959",
            "西西疑问": "109951163626285827"
        ]
    }
    
    private var e2n: [String: String]
    private var n2e: [String: String]
    
    private var c2i: [String: String]
}


func nm_md5_encode(_ key: String) -> String? {
    // Generating bytes data.
    var result = key.data(using: .utf8)
    var security = "3go8&$8*3*3h0k(2)2".data(using: .utf8)

    // Encryption bytes data.
    return result?.withUnsafeMutableBytes { lhs in
        // Perform simpleKeyXOR:withBytes:len:
        security?.withUnsafeMutableBytes { rhs in
            lhs.enumerated().forEach {
                lhs[$0] = $1 ^ rhs.load(fromByteOffset: $0 % rhs.count, as: UInt8.self)
            }
        }
        // Perform MD5 signature.
        let buffer =  UnsafeMutablePointer<UInt8>.allocate(capacity: .init(CC_MD5_DIGEST_LENGTH))
        CC_MD5(lhs.baseAddress, .init(lhs.count), buffer)
        
        // Perform Base64 encryption and formatting result.
        var str = Data(bytes: buffer, count: .init(CC_MD5_DIGEST_LENGTH)).base64EncodedString()
        str = str.replacingOccurrences(of: "/", with: "_")
        str = str.replacingOccurrences(of: "+", with: "-")
        return str
    }
}
