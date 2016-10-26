import ReactiveCocoa
import ReactiveSwift
import Result
import UIKit
import UnclutterKit

enum Field: Int {
    case signUpWithEmail
    case alreadyHaveAccount
    case email
    case username
    case password
    case signUp
    case logIn
    case forgotPassword
    case resetPassword
}

extension UIButton {
    convenience init(title: String) {
        self.init()
        setTitle(title, for: .normal)
        translatesAutoresizingMaskIntoConstraints = false
    }
}
extension UITextField {
    convenience init(placeholder: String? = nil, secure: Bool = false) {
        self.init()
        self.placeholder = placeholder
        self.isSecureTextEntry = secure
        translatesAutoresizingMaskIntoConstraints = false
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

public final class AuthenticationViewController: ViewController {
    let authenticationState: AuthenticationState
    let stack: UIStackView

    let back = UIButton(title: "Back")

    let signUpWithEmail = UIButton(title: "Email")
    let alreadyHaveAccount = UIButton(title: "I already have an account")
    let email = UITextField(placeholder: "Email")
    let username = UITextField(placeholder: "Username")
    let password = UITextField(placeholder: "Password", secure: true)
    let signUp = UIButton(title: "Sign up").then { $0.isEnabled = false }
    let logIn = UIButton(title: "Log in").then { $0.isEnabled = false }
    let forgotPassword = UIButton(title: "Forgot password")
    let resetPassword = UIButton(title: "Reset password").then { $0.isEnabled = false }

    public override init() {
        let views: [UIView] = [
            signUpWithEmail,
            alreadyHaveAccount,
            email,
            username,
            password,
            signUp,
            logIn,
            forgotPassword,
            resetPassword,
            ]
        authenticationState = AuthenticationState(
            views: views,
            initiallyVisible: [.signUpWithEmail, .alreadyHaveAccount])
        stack = UIStackView(arrangedSubviews: views).then {
            $0.translatesAutoresizingMaskIntoConstraints = false
            $0.axis = .vertical
            $0.distribution = .equalSpacing
            $0.alignment = .fill
        }
        super.init()
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func postInit() {
        view.backgroundColor = .lightGray

        authenticationState.visibleFields <~ Signal.merge(
            signUpWithEmail.onTrigger(yield: [.email, .username, .password, .signUp]),
            alreadyHaveAccount.onTrigger(yield: [.email, .password, .logIn, .forgotPassword]),
            forgotPassword.onTrigger(yield: [.email, .resetPassword]))

        let emailText = email.reactive.continuousTextValues.skipNil()
        let usernameText = username.reactive.continuousTextValues.skipNil()
        let passwordText = password.reactive.continuousTextValues.skipNil()

        let validEmail = emailText.map(isValidEmailAddress)
        let validUsername = usernameText.map(isValidUsername)
        let validPassword = passwordText.map(isValidPassword)

        signUp.reactive.isEnabled <~ Signal
            .combineLatest(validEmail, validUsername, validPassword).map { $0 && $1 && $2 }
        logIn.reactive.isEnabled <~ Signal
            .combineLatest(validEmail, validPassword).map { $0 && $1 }
        resetPassword.reactive.isEnabled <~ validEmail

        Signal.combineLatest(emailText, usernameText, passwordText)
            .sample(on: signUp.reactive.trigger(for: .touchUpInside))
            .observeValues { (email, username, password) in
                print("signUp", email, username, password)
        }

        Signal.combineLatest(emailText, passwordText)
            .sample(on: logIn.reactive.trigger(for: .touchUpInside))
            .observeValues { (email, password) in
                print("logIn", email, password)
        }

        emailText
            .sample(on: resetPassword.reactive.trigger(for: .touchUpInside))
            .observeValues { (email) in
                print("resetPassword", email)
        }

        back.reactive.trigger(for: .touchUpInside).observeValues(authenticationState.goBack)
        back.reactive.isHidden <~ authenticationState.history.map { $0.count <= 1 }

        view.addSubview(back)
        view.addSubview(stack)
        let margin: CGFloat = 25
        [
            stack.leftAnchor.constraint(equalTo: view.leftAnchor, constant: margin),
            view.rightAnchor.constraint(equalTo: stack.rightAnchor, constant: margin),
            view.centerYAnchor.constraint(equalTo: stack.centerYAnchor),
            back.leftAnchor.constraint(equalTo: view.leftAnchor, constant: margin),
            back.topAnchor.constraint(equalTo: view.topAnchor, constant: margin),
            ].forEach {
                $0.isActive = true
        }
    }
}

private extension UIControl {
    func onTrigger<T>(for controlEvents: UIControlEvents = .touchUpInside,
                   yield: T) -> Signal<T, NoError> {
        return reactive.trigger(for: .touchUpInside).map { yield }
    }
}

// attribution: http://stackoverflow.com/a/25471164/5752402
private func isValidEmailAddress(email: String) -> Bool {
    let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"

    let emailTest = NSPredicate(format: "SELF MATCHES %@", emailRegEx)
    return emailTest.evaluate(with: email)
}

private let isValidUsername = validateStringLength(1)
private let isValidPassword = validateStringLength(8)

private let validateStringLength: (Int) -> (String) -> Bool = { length in
    { string in
        string.characters.count >= length
    }
}
