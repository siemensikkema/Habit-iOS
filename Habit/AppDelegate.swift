import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    let viewControllerGraph: ViewControllerGraphProtocol = ViewControllerGraph()
    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {

        window = UIWindow(frame: UIScreen.main.bounds).then {
            $0.rootViewController = viewControllerPresenter.rootViewController
            $0.makeKeyAndVisible()
        }
        return true
    }
}
