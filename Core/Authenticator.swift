import ReactiveSwift
import Result

protocol Authenticating {
    var logIn: Action<(Email, Password), (), NoError> { get }
    var resetPassword: Action<Email, (), NoError> { get }
    var signUp: Action<(Email, Username, Password), (), NoError> { get }
}

struct FakeAuthenticator: Authenticating {
    let logIn = Action<(Email, Password), (), NoError> {
        print("log in with email: \($0), password: \($1)")
        return SignalProducer(value: ())
    }
    let resetPassword = Action<Email, (), NoError> {
        print("reset password for email: \($0)")
        return SignalProducer(value: ())
    }
    let signUp = Action<(Email, Username, Password), (), NoError> {
        print("sign up with email: \($0), username: \($1), password: \($2)")
        return SignalProducer(value: ())
    }
}
