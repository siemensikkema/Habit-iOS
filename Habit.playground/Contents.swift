import UIKit
import PlaygroundSupport
@testable import Habit

let currentPage = PlaygroundPage.current

currentPage.needsIndefiniteExecution = true
currentPage.liveView = AuthenticationViewController(networkAuthenticator: FakeNetworkAuthenticator())
