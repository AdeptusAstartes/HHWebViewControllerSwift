//
//  AppDelegate.swift
//  HHWebViewControllerSwift
//
//  Created by Donald Angelillo on 6/26/16.
//  Copyright © 2016 Donald Angelillo. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        self.window = UIWindow(frame: UIScreen.mainScreen().bounds)
        self.window?.backgroundColor = UIColor.clearColor()
        
        let webViewController = HHWebViewControllerSwift(url: NSURL(string: "http://www.google.com")!)
        webViewController.customShareMessage = "- Shared via test"
        
        let navController = UINavigationController(rootViewController: webViewController)
        navController.navigationBar.barTintColor = UIColor.redColor()
        
        
        self.window?.rootViewController = navController
        self.window?.makeKeyAndVisible()
        return true
    }

}

