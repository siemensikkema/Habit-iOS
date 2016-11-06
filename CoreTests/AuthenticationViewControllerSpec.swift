@testable import Core
import Nimble
import Quick
import ReactiveSwift
import Result

final class Credentials {
    var email: Email?
    var password: Password?
    var username: Username?

    func clear() {
        email = nil
        password = nil
        username = nil
    }
}

struct FakeAuthenticator: Authenticating {
    var logIn: Action<(Email, Password), (), NoError>
    var resetPassword: Action<Email, (), NoError>
    var signUp: Action<(Email, Username, Password), (), NoError>

    init(credentials: Credentials) {
        logIn = Action<(Email, Password), (), NoError> {
            credentials.email = $0
            credentials.password = $1
            return SignalProducer(value: ())
        }
        resetPassword = Action<Email, (), NoError> {
            credentials.email = $0
            return SignalProducer(value: ())
        }
        signUp = Action<(Email, Username, Password), (), NoError> {
            credentials.email = $0
            credentials.username = $1
            credentials.password = $2
            return SignalProducer(value: ())
        }
    }
}

class AuthenticationViewControllerSpec: QuickSpec {
    override func spec() {
        let credentials = Credentials()
        let authenticator = FakeAuthenticator(credentials: credentials)
        var viewController: AuthenticationViewController!
        var done = false

        beforeEach {
            viewController = AuthenticationViewController(authenticator: authenticator) {
                done = true
            }
        }

        afterEach {
            credentials.clear()
            done = false
        }

        var visibleFields: [UIView] {
            return viewController.stack.arrangedSubviews.filter { !$0.isHidden }
        }

        var back: UIButton { return viewController.back }
        var cancel: UIButton { return viewController.cancel }

        var signUpWithEmail: UIButton { return viewController.signUpWithEmail }
        var email: UITextField { return viewController.email }
        var username: UITextField { return viewController.username }
        var password: UITextField { return viewController.password }
        var alreadyHaveAccount: UIButton { return viewController.alreadyHaveAccount }
        var signup: UIButton { return viewController.signup }
        var login: UIButton { return viewController.login }
        var forgotPassword: UIButton { return viewController.forgotPassword }
        var resetPassword: UIButton { return viewController.resetPassword }

        func enter(_ text: String, inTo textField: UITextField) {
            textField.text = text
            textField.sendActions(for: .editingChanged)
        }

        describe("back") {
            var initiallyVisibleFields: [UIView] = []

            beforeEach {
                initiallyVisibleFields = visibleFields
                alreadyHaveAccount.sendActions(for: .touchUpInside)
                // wait for state change
                expect(visibleFields).toEventuallyNot(equal(initiallyVisibleFields))
                back.sendActions(for: .touchUpInside)
            }

            it("is able to go back to the initial state") {
                expect(visibleFields) == initiallyVisibleFields
            }
        }

        describe("cancel") {
            beforeEach {
                cancel.sendActions(for: .touchUpInside)
            }

            it("calls done") {
                expect(done) == true
            }
        }
        
        context("initial state") {
            it("shows the correct fields") {
                expect(visibleFields) == [signUpWithEmail, alreadyHaveAccount]
            }

            describe("back button") {
                it("is not visible") {
                    expect(back.isHidden) == true
                }
            }
        }

        context("sign up with email state") {
            beforeEach {
                signUpWithEmail.sendActions(for: .touchUpInside)
            }

            it("shows the correct fields") {
                expect(visibleFields) == [email, username, password, signup]
            }

            describe("back button") {
                it("is visible") {
                    expect(back.isHidden) == false
                }
            }

            context("invalid values entered") {
                describe("signup button") {
                    it("is not enabled") {
                        expect(signup.isEnabled) == false
                    }
                }
            }

            context("valid values entered") {
                beforeEach {
                    enter("a@b.com", inTo: email)
                    enter("username", inTo: username)
                    enter("password", inTo: password)
                }

                describe("signup button") {
                    it("is enabled") {
                        expect(signup.isEnabled) == true
                    }
                }

                describe("sign up") {
                    beforeEach {
                        signup.sendActions(for: .touchUpInside)
                    }

                    it("signs up with email, password, and username") {
                        expect(credentials.email) == "a@b.com"
                        expect(credentials.password) == "password"
                        expect(credentials.username) == "username"
                    }

                    it("calls done") {
                        expect(done) == true
                    }
                }
            }
        }

        context("login state") {
            beforeEach {
                alreadyHaveAccount.sendActions(for: .touchUpInside)
            }

            it("shows the correct fields") {
                expect(visibleFields) == [email, password, login, forgotPassword]
            }

            context("invalid values entered") {
                describe("login button") {
                    it("is not enabled") {
                        expect(login.isEnabled) == false
                    }
                }
            }

            context("valid values entered") {
                beforeEach {
                    enter("a@b.com", inTo: email)
                    enter("password", inTo: password)
                }

                describe("login button") {
                    it("is enabled") {
                        expect(login.isEnabled) == true
                    }
                }

                describe("log in") {
                    beforeEach {
                        login.sendActions(for: .touchUpInside)
                    }

                    it("logs in with email and password") {
                        expect(credentials.email) == "a@b.com"
                        expect(credentials.password) == "password"
                        expect(credentials.username).to(beNil())
                    }

                    it("calls done") {
                        expect(done) == true
                    }
                }
            }

            describe("back button") {
                it("is visible") {
                    expect(back.isHidden) == false
                }
            }
        }

        context("forgot password state") {
            beforeEach {
                let initiallyVisibleFields = visibleFields
                alreadyHaveAccount.sendActions(for: .touchUpInside)
                // wait for state change
                expect(visibleFields).toEventuallyNot(equal(initiallyVisibleFields))
                forgotPassword.sendActions(for: .touchUpInside)
            }

            it("shows the correct fields") {
                expect(visibleFields) == [email, resetPassword]
            }

            context("invalid values entered") {
                describe("reset password button") {
                    it("is not enabled") {
                        expect(resetPassword.isEnabled) == false
                    }
                }
            }

            context("valid values entered") {
                beforeEach {
                    enter("a@b.com", inTo: email)
                }

                describe("reset password button") {
                    it("is enabled") {
                        expect(resetPassword.isEnabled) == true
                    }
                }

                describe("reset password") {
                    beforeEach {
                        resetPassword.sendActions(for: .touchUpInside)
                    }

                    it("logs in with email and password") {
                        expect(credentials.email) == "a@b.com"
                        expect(credentials.password).to(beNil())
                        expect(credentials.username).to(beNil())
                    }

                    it("transitions to login state") {
                        expect(visibleFields) == [email, password, login, forgotPassword]
                    }
                }
            }

            describe("back button") {
                it("is visible") {
                    expect(back.isHidden) == false
                }
            }
        }
    }
}
