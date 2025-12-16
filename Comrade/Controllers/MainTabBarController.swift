import UIKit

final class MainTabBarController: UITabBarController {
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTabs()
    }

    private func setupTabs() {
        
        let timerVC = TimerViewController()
        timerVC.tabBarItem = UITabBarItem(title: "Timer", image: UIImage(systemName: "timer"), selectedImage: UIImage(systemName: "timer"))
        let timerNav = UINavigationController(rootViewController: timerVC)
        
        let tasksVC = TasksViewController()
        tasksVC.tabBarItem = UITabBarItem(title: "Tasks", image: UIImage(systemName: "list.bullet"), selectedImage: UIImage(systemName: "list.bullet"))
        let tasksNav = UINavigationController(rootViewController: tasksVC)

        let calendarVC = CalendarViewController()
        calendarVC.tabBarItem = UITabBarItem(title: "Calendar", image: UIImage(systemName: "calendar"), selectedImage: UIImage(systemName: "calendar"))
        let calendarNav = UINavigationController(rootViewController: calendarVC)

        let achievementsVC = AchievementsViewController()
        achievementsVC.tabBarItem = UITabBarItem(title: "Achievements", image: UIImage(systemName: "star"), selectedImage: UIImage(systemName: "star.fill"))
        let achievementsNav = UINavigationController(rootViewController: achievementsVC)

        viewControllers = [timerNav, tasksNav, calendarNav, achievementsNav]

        tabBar.tintColor = .systemRed
        tabBar.unselectedItemTintColor = .gray
    }
}
