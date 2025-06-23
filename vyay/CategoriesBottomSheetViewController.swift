import UIKit

protocol CategoriesBottomSheetDelegate: AnyObject {
    func didSelectCategory(_ category: Categories)
}

class CategoriesBottomSheetViewController: UIViewController {
    
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var tableView: UITableView!
    
    weak var delegate: CategoriesBottomSheetDelegate?
    private var categories: [Categories] = []
    private var filteredCategories: [Categories] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
        setupSearchBar()
        loadCategories()
    }
    
    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        //tableView.register(UINib(nibName: "ListItemCell", bundle: nil), forCellReuseIdentifier: "ListItemCell")
    }
    
    private func setupSearchBar() {
        searchBar.delegate = self
        searchBar.placeholder = "Search categories..."
    }
    
    private func loadCategories() {
        categories = CategoriesManager.shared.getAllCategories()
        filteredCategories = categories
        tableView.reloadData()
    }
}

// MARK: - UITableViewDelegate, UITableViewDataSource
extension CategoriesBottomSheetViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredCategories.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ListCell", for: indexPath) as! ListItemCell
        let category = filteredCategories[indexPath.row]
        cell.nameLabel.text = category.name
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let category = filteredCategories[indexPath.row]
        delegate?.didSelectCategory(category)
        dismiss(animated: true)
    }
}

// MARK: - UISearchBarDelegate
extension CategoriesBottomSheetViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.isEmpty {
            filteredCategories = categories
        } else {
            filteredCategories = categories.filter { category in
                category.name?.lowercased().contains(searchText.lowercased()) ?? false
            }
        }
        tableView.reloadData()
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
} 
