import Mortar
import ReactiveCocoa
import ReactiveSwift
import Result
import UIKit
import UnclutterKit

fileprivate enum Field: Int {
    case signUpWithEmail
    case email
    case username
    case password
    case alreadyHaveAccount
    case signUp
    case logIn
    case forgotPassword
    case resetPassword
}

extension UIButton {
    convenience init(title: String) {
        self.init()
        setTitle(title, for: .normal)
    }
}
extension UITextField {
    convenience init(placeholder: String? = nil, isSecure: Bool = false) {
        self.init()
        self.isSecureTextEntry = isSecure
        self.placeholder = placeholder
    }
}

fileprivate struct AuthenticationState {
    let history = MutableProperty<[[Field]]>([])
    let visibleFields: MutableProperty<[Field]>
    private let views: [UIView]

    init(views: [UIView], initiallyVisible fields: [Field]) {
        self.views = views

        visibleFields = MutableProperty(fields)
    }

    func setUp(with lifetime: Lifetime) {
        visibleFields.producer
            .take(during: lifetime)
            .startWithValues { [weak history] fields in
                history?.modify {
                    $0.append(fields)
                }
        }

        history.producer
            .take(during: lifetime)
            .map { $0.last }
            .skipNil()
            .startWithValues(animateVisibleFields)
    }

    func goBack() {
        history.modify {
            $0.removeLast()
        }
    }

    private func animateVisibleFields(_ fields: [Field]) {
        UIView.animate(
            withDuration: 0.33,
            animations: {
                self.setVisibleFields(fields)
            },
            completion: { _ in
                // This prevents messed up layouts due to some UIKit bug
                self.setVisibleFields(fields)
        })
    }

    private func setVisibleFields(_ fields: [Field]) {
        var flags = [Bool].init(repeating: false, count: views.count)
        fields.forEach {
            flags[$0.rawValue] = true
        }

        zip(flags, views).forEach { (flag, view) in
            view.isHidden = !flag
            view.alpha = flag ? 1 : 0
        }
    }
}

typealias Email = String
typealias Username = String
typealias Password = String

final class AuthenticationViewController: ViewController {
    private let authenticationState: AuthenticationState
    private let authenticator: Authenticating
    private let done: () -> Void

    let back = UIButton(title: "Back")
    let cancel = UIButton(title: "Cancel")
    let stack: UIStackView

    // Field related views
    let signUpWithEmail = UIButton(title: "Email")
    let email = UITextField(placeholder: "Email")
    let username = UITextField(placeholder: "Username")
    let password = UITextField(placeholder: "Password", isSecure: true)
    let alreadyHaveAccount = UIButton(title: "I already have an account")
    let signup = UIButton(title: "Sign up").then { $0.isEnabled = false }
    let login = UIButton(title: "Log in").then { $0.isEnabled = false }
    let forgotPassword = UIButton(title: "Forgot password")
    let resetPassword = UIButton(title: "Reset password").then { $0.isEnabled = false }

    init(authenticator: Authenticating, done: @escaping () -> Void) {
        let views: [UIView] = [signUpWithEmail,
                               email,
                               username,
                               password,
                               alreadyHaveAccount,
                               signup,
                               login,
                               forgotPassword,
                               resetPassword]
        authenticationState = AuthenticationState(
            views: views,
            initiallyVisible: [.signUpWithEmail, .alreadyHaveAccount])
        stack = UIStackView(arrangedSubviews: views)
            .then {
            $0.axis = .vertical
            $0.distribution = .equalSpacing
            $0.alignment = .fill
        }
        self.authenticator = authenticator
        self.done = done
        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func postInit() {
        view.backgroundColor = .lightGray

        setUpAuthenticationStateChanges()
        setUpButtons()
        setUpButtonEnabledChanges()
        setUpNetworkActions()
        setUpSubviews()
    }

    private func setUpButtons() {
        back.reactive.trigger(for: .touchUpInside).observeValues(authenticationState.goBack)
        back.reactive.isHidden <~ authenticationState.history.map { $0.count <= 1 }
        cancel.reactive.trigger(for: .touchUpInside).observeValues(done)
    }

    private func setUpButtonEnabledChanges() {
        let validEmail = email.nonNilValues.map(isValidEmailAddress)
        let validUsername = username.nonNilValues.map(isValidUsername)
        let validPassword = password.nonNilValues.map(isValidPassword)

        func allTrue(values: [Bool]) -> Bool {
            for value in values where value == false {
                return false
            }
            return true
        }

        login.reactive.isEnabled <~ Signal.combineLatest([
            validEmail,
            validPassword
            ]).map(allTrue)
        resetPassword.reactive.isEnabled <~ validEmail
        signup.reactive.isEnabled <~ Signal.combineLatest([
            validEmail,
            validUsername,
            validPassword
            ]).map(allTrue)
    }

    private func setUpNetworkActions() {
        // log in
        Signal.combineLatest(email.nonNilValues, password.nonNilValues)
            .sample(on: login.reactive.trigger(for: .touchUpInside))
            .flatMap(.latest, transform: authenticator.logIn.apply)
            .take(during: reactive.lifetime)
            .on(value: done)
            .observeCompleted {}

        // sign up
        Signal.combineLatest(email.nonNilValues, username.nonNilValues, password.nonNilValues)
            .sample(on: signup.reactive.trigger(for: .touchUpInside))
            .flatMap(.latest, transform: authenticator.signUp.apply)
            .take(during: reactive.lifetime)
            .on(value: done)
            .observeCompleted {}

        // reset password
        email.nonNilValues
            .sample(on: resetPassword.reactive.trigger(for: .touchUpInside))
            .flatMap(.latest, transform: authenticator.resetPassword.apply)
            .take(during: reactive.lifetime)
            .on(value: authenticationState.goBack)
            .observeCompleted {}
    }

    private func setUpAuthenticationStateChanges() {
        authenticationState.setUp(with: reactive.lifetime)
        authenticationState.visibleFields <~ Signal.merge(
            alreadyHaveAccount.onTrigger(yield: [.email, .password, .logIn, .forgotPassword]),
            forgotPassword.onTrigger(yield: [.email, .resetPassword]),
            signUpWithEmail.onTrigger(yield: [.email, .username, .password, .signUp]))
    }

    private func setUpSubviews() {
        view |+| [back, cancel, stack]

        [back.m_top, cancel.m_top] |=| [m_topLayoutGuideBottom, m_topLayoutGuideBottom]
        [back, cancel] |=| [stack.m_left, stack.m_right]
        stack |=| [view.m_leftMargin, view.m_rightMargin, view.m_centerY]
    }
}

private extension UITextField {
    var nonNilValues: Signal<String, NoError> {
        return reactive.continuousTextValues.skipNil()
    }
}

private extension UIControl {
    func onTrigger<T>(for controlEvents: UIControlEvents = .touchUpInside,
                   yield: T) -> Signal<T, NoError> {
        return reactive.trigger(for: .touchUpInside).map { yield }
    }
}

// attribution: http://stackoverflow.com/a/25471164/5752402
private func isValidEmailAddress(email: Email) -> Bool {
    let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"

    let emailTest = NSPredicate(format: "SELF MATCHES %@", emailRegEx)
    return emailTest.evaluate(with: email)
}

private let isValidPassword = validateStringLength(8)
private let isValidUsername = validateStringLength(1)
private let validateStringLength: (Int) -> (String) -> Bool = { length in
    { string in
        string.characters.count >= length
    }
}
