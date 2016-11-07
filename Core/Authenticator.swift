import ReactiveSwift
import Result

protocol Authenticating {
    var logIn: Action<(Email, Password), (), NoError> { get }
    var resetPassword: Action<Email, (), NoError> { get }
    var signUp: Action<(Email, Username, Password), (), NoError> { get }
}

struct Authenticator: Authenticating {
    var logIn: Action<(Email, Password), (), NoError>
    var resetPassword: Action<Email, (), NoError>
    var signUp: Action<(Email, Username, Password), (), NoError>

    init() {
        logIn = Action<(Email, Password), (), NoError> { _ in
            return SignalProducer(value: ())
        }
        resetPassword = Action<Email, (), NoError> { _ in
            return SignalProducer(value: ())
        }
        signUp = Action<(Email, Username, Password), (), NoError> { _ in
            return SignalProducer(value: ())
        }
    }
}
