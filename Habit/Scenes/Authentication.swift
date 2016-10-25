import UIKit
import UnclutterKit

private final class EmailField: TableViewCell, ReusableViewProtocol {
    let label = UILabel().then {
        $0.translatesAutoresizingMaskIntoConstraints = false
    }
    var viewModel: String? {
        didSet {
            label.text = viewModel
        }
    }

    override func configure() {
        addSubview(label)
        label.constrain(to: self)
    }
}

private enum Field {
    case email
    case username
    case password
}

public final class AuthenticationViewController: ViewController {
    private let table: Table
    private let tableView: UITableView
    let tableHeightConstraint: NSLayoutConstraint

    public init() {

        let tableView = UITableView(frame: .zero, style: .plain).then {
            $0.register(EmailField.self)
            $0.translatesAutoresizingMaskIntoConstraints = false
            $0.tableFooterView = UIView()
            $0.rowHeight = UITableViewAutomaticDimension
            $0.estimatedRowHeight = 50
            $0.bounces = false
        }

        let initialFields: [Field] = [.email, .password]
        let section = Section(items: initialFields)
        let dataSource = SimpleDataSource(sections: [section]) { (dataSource, field) -> TableItem in
            TableItem(EmailField.self, viewModel: "a@b.com") { (_, indexPath) in
                dataSource.sections = [Section(items: [.email, .username, .password])]
                tableView.reloadData()
            }
        }
        self.tableView = tableView
        table = Table(dataSource: dataSource)

        tableHeightConstraint = tableView.heightAnchor.constraint(equalToConstant: 0)
            .then { $0.isActive = true }
        super.init(nibName: nil, bundle: nil)
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func configure() {
        view.backgroundColor = .lightGray
        view.addSubview(tableView)

        [view.centerYAnchor.constraint(equalTo: tableView.centerYAnchor),
         view.leftAnchor.constraint(equalTo: tableView.leftAnchor, constant: -20),
         view.rightAnchor.constraint(equalTo: tableView.rightAnchor, constant: 20)]
            .forEach { $0.isActive = true }

        table.configure(with: tableView)
    }

    public override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        tableHeightConstraint.constant = tableView.contentSize.height
    }
}
