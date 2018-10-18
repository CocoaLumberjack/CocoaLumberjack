//
//  AppDelegate.swift
//  iOSSwiftIntegration
//
//  Created by Dmitry Lobanov on 17.10.2018.
//  Copyright © 2018 Dmitry Lobanov. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        let window = UIWindow()
        window.backgroundColor = UIColor.black
        self.window = window
        self.window?.makeKeyAndVisible()
        return true
    }

}

