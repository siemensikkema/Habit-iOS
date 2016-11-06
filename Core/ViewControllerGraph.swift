import ReactiveCocoa
import UIKit

public protocol ViewControllerGraphProtocol {
    var rootViewController: UIViewController { get }
}

public class ViewControllerGraph: ViewControllerGraphProtocol {
    public let rootViewController = UIViewController()

    public init() {
        let authenticator: Authenticating = Authenticator()
        let vc = AuthenticationViewController(authenticator: authenticator) {
            self.rootViewController.dismiss(animated: true, completion: nil)
        }

        rootViewController
            .reactive
            .trigger(for: #selector(UIViewController.viewDidAppear))
            .take(first: 1)
            .observeValues {
                self.rootViewController.present(vc, animated: true, completion: nil)
        }
    }
}
