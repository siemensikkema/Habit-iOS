import Core
import UIKit
import UnclutterKit

// trigger copying of libswiftCoreData.dylib so it becomes available to Habit
import CoreData

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    let viewControllerGraph: ViewControllerGraphProtocol = ViewControllerGraph()
    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {

        window = UIWindow(frame: UIScreen.main.bounds).then {
            $0.rootViewController = viewControllerGraph.rootViewController
            $0.makeKeyAndVisible()
        }
        return true
    }
}
