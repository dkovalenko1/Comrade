//
//  AppDelegate.swift
//  Comrade
//
//  Created by david on 05.12.2025.
//

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // Request notification permissions
        NotificationService.shared.requestPermission { granted in
            print("Notifications permission granted: \(granted)")
        }
        
        // Initialize CoreData stack
        _ = CoreDataStack.shared
        
        return true
    }

    // UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Clean up resources for discarded scenes if needed
    }
}
