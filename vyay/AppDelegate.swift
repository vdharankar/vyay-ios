//
//  AppDelegate.swift
//  vyay
//
//  Created by Vishal Dharankar on 06/06/24.
//

import UIKit
import FirebaseCore
import CoreData

@main
class AppDelegate: UIResponder, UIApplicationDelegate {


    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        if #available(iOS 13, *) {
                    // Do not setup window here if targeting iOS 13 or later
        } else {
            window = UIWindow(frame: UIScreen.main.bounds)
            let mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
            let initialViewController = mainStoryboard.instantiateInitialViewController()
            window?.rootViewController = initialViewController
            window?.makeKeyAndVisible()
        }
        
        FirebaseApp.configure()
        
        if let customFont = UIFont(name: "Lato", size: 20) {
            let attributes = [
                NSAttributedString.Key.font: customFont
            ]
            UINavigationBar.appearance().titleTextAttributes = attributes
        }
        
        let defaults = UserDefaults.standard
        if defaults.string(forKey: "currencySymbol") == nil {
            let symbol = Locale.current.currencySymbol ?? "$"
            defaults.set(symbol, forKey: "currencySymbol")
        }
        
        return true
    }


   /* func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }*/
    
    @available(iOS 13.0, *)
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    @available(iOS 13.0, *)
    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
    }

    // MARK: - Core Data stack
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "data")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()

}

