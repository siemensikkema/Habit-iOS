import PlaygroundSupport
@testable import Core

let currentPage = PlaygroundPage.current

currentPage.needsIndefiniteExecution = true

currentPage.liveView = AuthenticationViewController(authenticator: Core.Authenticator()) { print("done!") }

