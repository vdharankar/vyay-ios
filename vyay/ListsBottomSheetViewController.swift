import UIKit

// Add the delegate protocol at the top
protocol ListsBottomSheetDelegate: AnyObject {
    func didSelectList(_ list: Lists)
}

class ListsBottomSheetViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate {
    // Add the delegate property
    weak var delegate: ListsBottomSheetDelegate?

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchBar: UISearchBar!

    var allLists: [Lists] = []
    var filteredLists: [Lists] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        searchBar.delegate = self
        fetchLists()
    }

    func fetchLists() {
        allLists = ListsManager.shared.fetchAllLists()
        filteredLists = allLists
        tableView.reloadData()
    }

    // MARK: - TableView DataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredLists.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ListCell", for: indexPath) as! ListItemCell
        let list = filteredLists[indexPath.row]
        cell.nameLabel.text = list.name ?? ""
        return cell
    }

    // MARK: - TableView Delegate
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedList = filteredLists[indexPath.row]
        delegate?.didSelectList(selectedList)
        dismiss(animated: true)
    }

    // MARK: - SearchBar Delegate
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.isEmpty {
            filteredLists = allLists
        } else {
            filteredLists = allLists.filter { $0.name?.localizedCaseInsensitiveContains(searchText) == true }
        }
        tableView.reloadData()
    }
} 