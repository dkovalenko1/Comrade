import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // Check for UI Testing reset flag
        if CommandLine.arguments.contains("--reset-data") {
            CoreDataStack.shared.wipePersistentStore()
            CoreDataStack.shared.reset()
            // Also clear UserDefaults if needed
            if let bundleID = Bundle.main.bundleIdentifier {
                UserDefaults.standard.removePersistentDomain(forName: bundleID)
            }
        }
        
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
