//
//  NMEvent.swift
//  NetEaseMusic
//
//  Created by SAGESSE on 2020/1/13.
//  Copyright © 2020 SAGESSE. All rights reserved.
//

import UIKit

class NMEvent {
    
    
    var id: Int
    
    
    var tiles: [Any]?

////    var uuid: String?
//
//
//    var expireTime: Int = 0
//
//    //var rcmdInfo: String?
//    var json: String?
//
//    var lotteryEventData: String?
//    var showTime: Int = 0
//
//    var tmplId: Int = 0
//
//    var topEvent: Bool = false
//
////    var info: Any?
//
//    var actId: Int = 0
//    var type: Int = 0
//    var insiteForwardCount: Int = 0
//    var eventTime: Int = 1578384723816
//
//    //var pendantData: Any? {
//    //  "id": 27000,
//    //  "imageUrl": "http://p1.music.126.net/69ADY7MgreUf9Owg_drahQ==/109951164219713265.jpg",
//    //  "imageAndroidUrl": "http://p1.music.126.net/fjHfw3T8jf_7SofWsI9dDg==/109951164255813306.jpg",
//    //  "imageIosUrl": "http://p1.music.126.net/p1fmWjaOMCfP8wIXPMnbgw==/109951164255813310.jpg"
//    //}
//
//    var forwardCount: Int = 0
//
    var user: NMUser?
    
    var date: String?
//
    var actName: String? // 云村有票
//
//    var pics: [Image]?
    
    init(_ id: Int) {
        self.id = id
        
        
        self.user = NMUser()
        self.user?.nickname = "云音乐福利"
        
        self.actName = "分享单曲"
        
        self.date = "1月12日"
            
        self.tiles = [
            NMEvent.Text(value: "🎇🌇🛤🎈🎈🎈🍎🐼🥰[惊恐][呆][小鸡]\n恭喜@淘走的洋 @宇宙的尽头是餐厅 @Erwinnnnn @光阴姑娘 @Kelly狮子合唱团 @Ulna-SJJ @有星的空 @多肉植物ayi 获得门票1张；本次活动为现场取票，请在1月15日15：00前将您的姓名+手机号（作为取票凭证）私信给本喵，逾期不候噢~\n[多多大笑][多多瞌睡][多多笑哭][多多可怜][亲亲][撇嘴][怒][憨笑]", size: 16),
            NMEvent.Image(items: (0 ..< (id % 10)).map { _ in
                return NMEvent.Image.Item(url: nil, size: .init(width: 787, height: 787))
            }),
            NMEvent.Video(),
            NMEvent.Music.playlist("村上春树：与小泽征尔共度的午后音乐时光", subtitle: "by 云音乐古典之声", cover: URL(string: "http://p2.music.126.net/ys9AuM50On9-cb1TRvTZuA==/109951164614286837.jpg")),
            NMEvent.Referenced([ // event:
                NMEvent.Text(value: "@云音乐福利 分享单曲：【福利】#云村有票#漫游多彩的音乐之旅，2月14日情人节，小野丽莎@OnoLisa 上海演唱会邀你一起寻觅音乐的浪漫与温情~\n在歌声中找寻幸福与感动，在音乐里体味美丽人生。\n截至1月13日15：00，转发+评论（缺一不可）本条动态就有机会赢得【门票】！\n购票请戳→https://music.163.com/show/m/detail/2654034\n[多多亲吻][多多可怜][多多大哭][多多大笑][多多捂脸][多多无语][多多比耶][多多瞌睡][多多笑哭][多多耍酷][多多调皮][多多难过][西西再见][西西发怒][西西呕吐][西西奸笑][西西心动][西西惊吓][西西惊讶][西西晕了][西西机智][西西流汗][西西疑问]", size: 15),
                NMEvent.Image(items: [ // event.pics
                     NMEvent.Image.Item(url: URL(string: "http://p2.music.126.net/CbJ-ze_7g5Nkk198vWL3PQ==/109951164612529616.jpg"), size: .init(width: 1080, height: 1511))
                ]),
                NMEvent.Video(),
                NMEvent.Music.song("LA VIE EN ROSE (玫瑰人生)", subtitle: "小野リサ", cover: URL(string: "http://p1.music.126.net/6y-UleORITEDbvrOLV0Q8A==/5639395138885805.jpg")),
            ]),
            NMEvent.Music.album("Skin", subtitle: "Flume", cover: URL(string: "http://p2.music.126.net/N9QDa3qlkRJ3IyFHVY07cg==/109951164430276051.jpg")),
        ]
    }
}


extension NMEvent {
    
    /// The base tile content entity.
    class Tile<T>: NMEventNodeEntity where T: NMEventNodeDisplayable {
        typealias Display = T
    }
    
    /// The text content entity.
    class Text: Tile<NMEventNode.Display.Text> {
        
        var size: CGFloat
        var value: String
        
        init(value: String, size: CGFloat) {
            self.size = size
            self.value = value
        }
    }
    
    /// The image content entity.
    class Image: Tile<NMEventNode.Display.Image> {
        
        class Item {
            
            var url: URL?
            var size: CGSize
            
            init(url: URL?, size: CGSize) {
                self.url = url
                self.size = size
            }
        }
        
        var items: [Item]
        init(items: [Item]) {
            self.items = items
        }
    }
    
    /// The video content entity.
    class Video: Tile<NMEventNode.Display.Video> {
    }
    
    /// The music content entity.
    class Music: Tile<NMEventNode.Display.Music> {
        
        /// Music ref source.
        enum Source: Int {
            case song
            case album
            case playlist
        }
        
        // song: title(name + (transNames[0]))/subtitle(artists.name)/cover(album.picUrl)/has play
        // album: title(album.name)/subtitle(album.artist.name)/cover(album.picUrl)/no play
        // playlist: title([歌单] + name)/subtitle(by + creator.nickname)/cover(coverImgUrl)/no play
        
        var title: String
        var subtitle: String
        var source: Source

        var cover: URL?
        
        required init(title: String, subtitle: String, cover: URL?, source: Source) {
            self.title = title
            self.subtitle = subtitle
            self.source = source
            self.cover = cover
        }
        
        class func song(_ title: String, subtitle: String, cover: URL? = nil) -> Self {
            return self.init(title: title, subtitle: subtitle, cover: cover, source: .song)
        }
        class func album(_ title: String, subtitle: String, cover: URL? = nil) -> Self {
            return self.init(title: title, subtitle: subtitle, cover: cover, source: .album)
        }
        class func playlist(_ title: String, subtitle: String, cover: URL? = nil) -> Self {
            return self.init(title: title, subtitle: subtitle, cover: cover, source: .playlist)
        }
    }
    
    /// The referenced content entity.
    class Referenced: Tile<NMEventNode.Display.Referenced> {
        
        var tiles: [Any]?
        init(_ tiles: [Any]) {
            self.tiles = tiles
            super.init()
        }
    }
}
