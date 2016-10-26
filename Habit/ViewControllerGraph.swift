import UIKit

public protocol ViewControllerGraphProtocol {
    var rootViewController: UIViewController { get }
}

public struct ViewControllerGraph: ViewControllerGraphProtocol {
    public init() {}
    public let rootViewController: UIViewController =
        AuthenticationViewController(networkAuthenticator: FakeNetworkAuthenticator())
}
