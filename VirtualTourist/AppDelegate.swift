//
//  AppDelegate.swift
//  VirtualTourist
//
//  Created by user on 17.04.2020.
//  Copyright © 2020 ulkoart. All rights reserved.
//

import UIKit
import CoreData

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    let dataController = DataController(modelName: "VirtualTourist")
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        dataController.load(completion: { () in
            print ("dataController was loaded!")
            return
        })
        
        let nc = window?.rootViewController as! UINavigationController
        let mapVC = nc.topViewController as! MapVC
        mapVC.dataController = dataController
        
        return true
    }


}

