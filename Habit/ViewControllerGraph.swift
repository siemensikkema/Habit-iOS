import UIKit
import ReactiveSwift
import Result

public protocol ViewControllerGraphProtocol {
    var rootViewController: UIViewController { get }
}

struct FakeNetworkAuthenticator: NetworkAuthenticating {
    var resetPassword = Action<Email, (), NoError> {
        print("reset password for email: \($0)")
        return SignalProducer(value: ())
    }
    var logIn = Action<(Email, Password), (), NoError> {
        print("log in with email: \($0), password: \($1)")
        return SignalProducer(value: ())
    }
    var signUp = Action<(Email, Username, Password), (), NoError> {
        print("sign up with email: \($0), username: \($1), password: \($2)")
        return SignalProducer(value: ())
    }
}

public struct ViewControllerGraph: ViewControllerGraphProtocol {
    public init() {}
    public let rootViewController: UIViewController =
        AuthenticationViewController(networkAuthenticator: FakeNetworkAuthenticator())
}
