@testable import Core
import Foundation
import Nimble
import Quick
import ReactiveCocoa
import ReactiveSwift
import Result
import UnclutterKit

extension URLRequest {
    var jsonBody: [String: Any] {
        guard
            let data = httpBody,
            let jsonObject = try? JSONSerialization
                .jsonObject(with: data, options: []) as? [String: Any] else {
                return [:]
        }
        return jsonObject ?? [:]
    }
}

class AuthenticationSpec: QuickSpec {
    override func spec() {
        var request: URLRequest?
        let authenticationRequests: AuthenticationRequestsProtocol =
            AuthenticationRequests(
                urlBuilder: {
                    URLComponents(host: "localhost", endpoint: $0).url!
                },
                requestHandler: {
                    request = $0
                    return .empty
            })

        afterEach {
            request = nil
        }

        context("login") {
            beforeEach {
                authenticationRequests.logIn("a@b.com", "password").start()
            }

            describe("request") {
                it("uses correct URL") {
                    expect(request?.url?.absoluteString) == "https://localhost/auth/log_in"
                }

                it("POSTs the request") {
                    expect(request?.httpMethod) == "POST"
                }

                describe("body") {
                    it("contains email") {
                        expect(request?.jsonBody["email"] as? String) == "a@b.com"
                    }

                    it("contains password") {
                        expect(request?.jsonBody["password"] as? String) == "password"
                    }
                }
            }
        }

        context("reset password") {
            beforeEach {
                authenticationRequests.resetPassword("a@b.com").start()
            }

            describe("request") {
                it("uses correct URL") {
                    expect(request?.url?.absoluteString) == "https://localhost/auth/reset_password"
                }

                it("POSTs the request") {
                    expect(request?.httpMethod) == "POST"
                }

                describe("body") {
                    it("contains email") {
                        expect(request?.jsonBody["email"] as? String) == "a@b.com"
                    }
                }
            }
        }

        context("signup") {
            beforeEach {
                authenticationRequests.signUp("a@b.com", "username", "password").start()
            }

            describe("request") {
                it("uses correct URL") {
                    expect(request?.url?.absoluteString) == "https://localhost/auth/sign_up"
                }

                it("POSTs the request") {
                    expect(request?.httpMethod) == "POST"
                }

                describe("body") {
                    it("contains email") {
                        expect(request?.jsonBody["email"] as? String) == "a@b.com"
                    }

                    it("contains password") {
                        expect(request?.jsonBody["password"] as? String) == "password"
                    }

                    it("contains username") {
                        expect(request?.jsonBody["username"] as? String) == "username"
                    }
                }
            }
        }
    }
}
