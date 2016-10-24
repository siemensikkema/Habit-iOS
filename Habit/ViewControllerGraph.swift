import UIKit

protocol ViewControllerGraphProtocol {
    var rootViewController: UIViewController { get }
}

struct ViewControllerGraph: ViewControllerGraphProtocol {
    var rootViewController = UIViewController()
}
