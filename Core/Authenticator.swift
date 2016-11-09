import Foundation
import ReactiveSwift
import Result
import UnclutterKit

enum Endpoint {
    case login
    case signup
    case resetPassword
}

extension Endpoint: PathComponentsProtocol {
    var pathComponents: [String] {
        let auth = "auth"

        switch self {
        case .login:
            return [auth, "log_in"]
        case .signup:
            return [auth, "sign_up"]
        case .resetPassword:
            return [auth, "reset_password"]
        }
    }
}

protocol Authenticating {
    var logIn: Action<(Email, Password), (), NoError> { get }
    var resetPassword: Action<Email, (), NoError> { get }
    var signUp: Action<(Email, Username, Password), (), NoError> { get }
}

protocol AuthenticationRequestsProtocol {
    var logIn: (Email, Password) -> SignalProducer<Void, NoError> { get }
    var resetPassword: (Email) -> SignalProducer<Void, NoError> { get }
    var signUp: (Email, Username, Password) -> SignalProducer<Void, NoError> { get }
}

struct AuthenticationRequests: AuthenticationRequestsProtocol {
    let logIn: (Email, Password) -> SignalProducer<Void, NoError>
    let resetPassword: (Email) -> SignalProducer<Void, NoError>
    let signUp: (Email, Username, Password) -> SignalProducer<Void, NoError>

    init(urlBuilder urlFor: @escaping (Endpoint) -> URL,
         requestHandler: @escaping (URLRequest?) -> SignalProducer<(Data, URLResponse), NSError>) {
        let email = "email"
        let password = "password"
        let username = "username"
        logIn = {
            let request = URLRequest(
                url: urlFor(.login),
                method: .post,
                body: [email: $0, password: $1])
            return requestHandler(request)
                .map { _ in }
                .flatMapError { _ in .empty }
        }
        resetPassword = {
            let request = URLRequest(
                url: urlFor(.resetPassword),
                method: .post,
                body: [email: $0])
            return requestHandler(request)
                .map { _ in }
                .flatMapError { _ in .empty }
        }
        signUp = {
            let request = URLRequest(
                url: urlFor(.signup),
                method: .post,
                body: [email: $0, username: $1, password: $2])
            return requestHandler(request)
                .map { _ in }
                .flatMapError { _ in .empty }
        }
    }
}

struct Authenticator: Authenticating {
    var logIn: Action<(Email, Password), (), NoError>
    var resetPassword: Action<Email, (), NoError>
    var signUp: Action<(Email, Username, Password), (), NoError>

    init(authenticationRequests: AuthenticationRequestsProtocol) {
        logIn = Action<(Email, Password), (), NoError>(authenticationRequests.logIn)
        resetPassword = Action<Email, (), NoError>(authenticationRequests.resetPassword)
        signUp = Action<(Email, Username, Password), (), NoError>(authenticationRequests.signUp)
    }
}
