@testable import Core
import Nimble
import Quick

class AuthenticationSpec: QuickSpec {
    override func spec() {
        describe("cancel") {
            var done = false

            beforeEach {
                let authenticator = FakeAuthenticator()

                let authenticationViewController = AuthenticationViewController(authenticator: authenticator) {
                    done = true
                }

                authenticationViewController.cancel.sendActions(for: .touchUpInside)
            }

            it("calls done") {
                expect(done) == true
            }
        }
    }
}
