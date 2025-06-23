import UIKit

class SettingsViewController: UITableViewController {
    @IBOutlet weak var currencyLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Settings"
        navigationController?.navigationBar.prefersLargeTitles = false
        navigationItem.largeTitleDisplayMode = .never

        // Set back button color to theme color
        navigationController?.navigationBar.tintColor = UIColor(rgb: 0x662CAA)

        // Fetch and show the currency symbol from UserDefaults
        currencyLabel.text = UserDefaults.standard.string(forKey: "currencySymbol") ?? "$"
    }
} 