import Foundation
import UIKit

class SettingsViewController: UIViewController
{
    //MARK: Essentials
    fileprivate var viewModel: SettingsViewModel!
    fileprivate var presenter: SettingsPresenter!
    
    //MARK: Outlets
    @IBOutlet weak var versionLabel: UILabel!
    
    private var tableView: UITableView?
    
    //MARK: Public Methods
    func inject(presenter : SettingsPresenter, viewModel: SettingsViewModel)
    {
        self.viewModel = viewModel
        self.presenter = presenter
    }
    
    //MARK: View Controller Cycle
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        versionLabel.numberOfLines = 0
        let boldAttributes = [
            NSAttributedStringKey.font: UIFont.boldSystemFont(ofSize: 13),
            NSAttributedStringKey.foregroundColor: UIColor.normalGray
        ]
        let regularAttributes = [
            NSAttributedStringKey.font: UIFont.systemFont(ofSize: 13),
            NSAttributedStringKey.foregroundColor: UIColor.normalGray
        ]
        let title = NSMutableAttributedString(string: "Superday\n", attributes: boldAttributes)
        let version = NSAttributedString(string: viewModel.fullAppVersion, attributes: regularAttributes)
        title.append(version)
        versionLabel.attributedText = title
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?)
    {
        guard segue.identifier == "embededTableView",
            let settingsTableViewController = segue.destination as? SettingsTableViewController
            else { return }
        
        settingsTableViewController.presenter = presenter
        settingsTableViewController.viewModel = viewModel
    }
}
