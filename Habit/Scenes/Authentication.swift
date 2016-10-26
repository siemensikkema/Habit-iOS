import Mortar
import ReactiveCocoa
import ReactiveSwift
import Result
import UIKit
import UnclutterKit

enum Field: Int {
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

final class AuthenticationState {
    let history = MutableProperty<[[Field]]>([])
    let visibleFields: MutableProperty<[Field]>
    private let views: [UIView]

    init(views: [UIView], initiallyVisible fields: [Field]) {
        self.views = views

        visibleFields = MutableProperty(fields)
        visibleFields.producer
            .startWithValues { fields in
                self.history.modify {
                    $0.append(fields)
                }
        }
        history.producer
            .map { $0.last }
            .skipNil()
            .startWithValues(animateVisibleFields)
    }

    func goBack() {
        guard history.value.count > 1 else { return }
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
    let authenticationState: AuthenticationState
    let networkAuthenticator: NetworkAuthenticating

    let stack: UIStackView
    let back = UIButton(title: "Back")

    let signUpWithEmail = UIButton(title: "Email")
    let email = UITextField(placeholder: "Email")
    let username = UITextField(placeholder: "Username")
    let password = UITextField(placeholder: "Password", isSecure: true)
    let alreadyHaveAccount = UIButton(title: "I already have an account")
    let signUp = UIButton(title: "Sign up").then { $0.isEnabled = false }
    let logIn = UIButton(title: "Log in").then { $0.isEnabled = false }
    let forgotPassword = UIButton(title: "Forgot password")
    let resetPassword = UIButton(title: "Reset password").then { $0.isEnabled = false }

    init(networkAuthenticator: NetworkAuthenticating) {
        let views: [UIView] = [signUpWithEmail,
                               email,
                               username,
                               password,
                               alreadyHaveAccount,
                               signUp,
                               logIn,
                               forgotPassword,
                               resetPassword]
        authenticationState = AuthenticationState(
            views: views,
            initiallyVisible: [.signUpWithEmail, .alreadyHaveAccount])
        stack = UIStackView(arrangedSubviews: views).then {
            $0.axis = .vertical
            $0.distribution = .equalSpacing
            $0.alignment = .fill
        }
        self.networkAuthenticator = networkAuthenticator
        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func postInit() {
        view.backgroundColor = .lightGray

        setUpAuthenticationStateChanges()
        setUpBackButton()
        setUpButtonEnabledChanges()
        setUpNetworkActions()
        setUpSubviews()
    }

    private func setUpBackButton() {
        back.reactive.trigger(for: .touchUpInside).observeValues(authenticationState.goBack)
        back.reactive.isHidden <~ authenticationState.history.map { $0.count <= 1 }
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

        logIn.reactive.isEnabled <~ Signal.combineLatest([
            validEmail,
            validPassword
            ]).map(allTrue)
        resetPassword.reactive.isEnabled <~ validEmail
        signUp.reactive.isEnabled <~ Signal.combineLatest([
            validEmail,
            validUsername,
            validPassword
            ]).map(allTrue)
    }

    private func setUpNetworkActions() {
        // log in
        Signal.combineLatest(email.nonNilValues, password.nonNilValues)
            .sample(on: logIn.reactive.trigger(for: .touchUpInside))
            .flatMap(.latest, transform: networkAuthenticator.logIn.apply)
            .observeCompleted {}

        // sign up
        Signal.combineLatest(email.nonNilValues, username.nonNilValues, password.nonNilValues)
            .sample(on: signUp.reactive.trigger(for: .touchUpInside))
            .flatMap(.latest, transform: networkAuthenticator.signUp.apply)
            .observeCompleted {}

        // reset password
        email.nonNilValues
            .sample(on: resetPassword.reactive.trigger(for: .touchUpInside))
            .flatMap(.latest, transform: networkAuthenticator.resetPassword.apply)
            .on(value: authenticationState.goBack)
            .observeCompleted {}
    }

    private func setUpAuthenticationStateChanges() {
        authenticationState.visibleFields <~ Signal.merge(
            alreadyHaveAccount.onTrigger(yield: [.email, .password, .logIn, .forgotPassword]),
            forgotPassword.onTrigger(yield: [.email, .resetPassword]),
            signUpWithEmail.onTrigger(yield: [.email, .username, .password, .signUp]))
    }

    private func setUpSubviews() {
        view |+| [back, stack]

        back |=| [m_topLayoutGuideTop, stack.m_left]
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
