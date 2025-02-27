//
//  AppDelegate.swift
//  NetEaseMusic
//
//  Created by SAGESSE on 2019/6/11.
//  Copyright © 2019 SAGESSE. All rights reserved.
//

import UIKit
import AsyncDisplayKit

//
//
//func UITabBarButton_iOS_12_1_Patch() {
//
//    guard #available(iOS 12.1, *) else {
//        return
//    }
//
//    guard let m = class_getInstanceMethod(NSClassFromString("UITabBarButton"), #selector(setter: UIControl.frame)) else {
//        return
//    }
//
//    let origin = unsafeBitCast(method_getImplementation(m), to: (@convention(c) (UIView, Selector, CGRect) -> ()).self)
//    method_setImplementation(m, imp_implementationWithBlock({
//
//        if $1.size == .zero {
//            return
//        }
//
//        origin($0, #selector(setter: UIControl.frame), $1)
//
//    } as @convention(block) (UIView, CGRect) -> () ))
//}
//    class Tracker {
//
//        func add(_ offset: CGFloat, timestamp: TimeInterval = CACurrentMediaTime()) {
//
//            let distance = offset - self.offset
//            let elapsed = timestamp - self.timestamp
//
//            self.offset = offset
//            self.timestamp = timestamp
//
//            self.elapsed = elapsed
//            self.velocity = (elapsed != 0 ? distance / CGFloat(elapsed) : 0)
//        }
//
//        private var offset: CGFloat = 0
//        private var timestamp: TimeInterval = 0
//
//        private var elapsed: TimeInterval = 0
//        private var velocity: CGFloat = 0
//    }


@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // Disable Async display kit all logs.
        ASDisableLogging()

        #if DEBUG
        NMLaunchViewController.show(2)
        #endif
        
        //#if DEBUG
        //DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(2)) {
        //    UIApplication.shared.keyWindow?.showsFPS = true
        //}
        //#endif

        // Override point for customization after application launch.
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.

    }

}
