import ReactiveSwift
import Result

protocol NetworkAuthenticating {
    var logIn: Action<(Email, Password), (), NoError> { get }
    var resetPassword: Action<Email, (), NoError> { get }
    var signUp: Action<(Email, Username, Password), (), NoError> { get }
}

struct FakeNetworkAuthenticator: NetworkAuthenticating {
    var logIn = Action<(Email, Password), (), NoError> {
        print("log in with email: \($0), password: \($1)")
        return SignalProducer(value: ())
    }
    var resetPassword = Action<Email, (), NoError> {
        print("reset password for email: \($0)")
        return SignalProducer(value: ())
    }
    var signUp = Action<(Email, Username, Password), (), NoError> {
        print("sign up with email: \($0), username: \($1), password: \($2)")
        return SignalProducer(value: ())
    }
}
