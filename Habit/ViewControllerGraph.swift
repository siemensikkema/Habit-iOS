import ReactiveCocoa
import UIKit

public protocol ViewControllerGraphProtocol {
    var rootViewController: UIViewController { get }
}

public class ViewControllerGraph: ViewControllerGraphProtocol {
    let authenticator: Authenticating = FakeAuthenticator()

    public init() {
        rootViewController
            .reactive
            .trigger(for: #selector(UIViewController.viewDidAppear))
            .take(first: 1)
            .observeValues { [authenticator, rootViewController] _ in
                let vc = AuthenticationViewController(authenticator: authenticator) {
                    rootViewController.dismiss(animated: true, completion: nil)
                }
                rootViewController.present(vc, animated: true, completion: nil)
        }
    }
    public let rootViewController = UIViewController()
}
