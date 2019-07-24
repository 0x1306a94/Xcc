//
//  NMUserHomeAboutViewController.swift
//  NetEaseMusic
//
//  Created by SAGESSE on 2019/7/20.
//  Copyright © 2019 SAGESSE. All rights reserved.
//

import UIKit



class NMUserHomeAboutViewController: UITableViewController {

    @IBOutlet weak var authLabel: UILabel!
    @IBOutlet weak var authIconView: UIImageView!

    @IBOutlet weak var infoLabel: UILabel!
    @IBOutlet weak var introLabel: UILabel!

    @IBOutlet weak var activityLabel: UILabel!
    @IBOutlet weak var commentsLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()

        self.tableView.estimatedRowHeight = 44

        update()
        //        let height = view.frame.height - topLayoutGuide.length - bottomLayoutGuide.length - 40
        //        if tableView.contentSize.height < height {
        //            tableView.contentSize.height = height
        //        }
    }

    func update() {

        let name = "云音乐小甜心"
        let info = """
        ${style:push?line-space=8}
        等级: ${img:cm2_set_lv?&y=-3&text-left=21.5&text-top=1.5&text=8&font-size=11&font-weight=bold&color=#999999}
        性别: 女
        年龄: 90后 魔蝎座
        地区: 北京
        """
        let intro = """
        ${style:push?line-space=8}
        网易云音乐是6亿人都在使用的音乐平台，致力于帮助用户发现音乐惊喜，帮助音乐人实现梦想。
        客服 @云音乐客服 在线时间：9：00 - 24：00，如您在使用过程中遇到任何问题，欢迎私信咨询，我们会尽快回复。
        如果仍然不能解决您的问题，请邮件我们：
        用户：mc5990@163.com
        音乐人: yyr599@163.com
        """

        authLabel.text = name
        authIconView.isHidden = false

        infoLabel.nm_text = info
        introLabel.nm_text =  intro 
    }


    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 1 {
            return super.tableView(tableView, numberOfRowsInSection: section)
        }
        return super.tableView(tableView, numberOfRowsInSection: section)
    }
    
    override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 88
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0.001
    }

    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0.001
    }

}
