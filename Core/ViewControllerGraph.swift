import ReactiveCocoa
import ReactiveSwift
import UIKit
import UnclutterKit

public protocol ViewControllerGraphProtocol {
    var rootViewController: UIViewController { get }
}

public class ViewControllerGraph: ViewControllerGraphProtocol {
    public let rootViewController = UIViewController()

    public init() {
        let authenticator: Authenticating = Authenticator(
            authenticationRequests: AuthenticationRequests(urlBuilder: {
                URLComponents(host: "localhost", endpoint: $0).url!
                }) { _ in SignalProducer(value: (Data(), URLResponse())) })
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
