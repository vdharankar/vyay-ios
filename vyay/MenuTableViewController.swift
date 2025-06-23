//
//  MenuTableViewController.swift
//  vyay
//
//  Created by Vishal Dharankar on 15/06/24.
//

import UIKit

class MenuTableViewController: UITableViewController {
    
    let searchController = UISearchController(searchResultsController: nil)
    var filteredData = [String]()
    var data = ["Apple", "Banana", "Cherry", "Date", "Fig", "Grape", "Honeydew"]

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Setup the Search Controller
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search Fruits"
        navigationItem.searchController = searchController
        definesPresentationContext = true

        // Setup the Table View
        tableView.delegate = self
        tableView.dataSource = self
    }

    func filterContentForSearchText(_ searchText: String) {
        filteredData = data.filter { (fruit: String) -> Bool in
            return fruit.lowercased().contains(searchText.lowercased())
        }
        
        tableView.reloadData()
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if isFiltering() {
            return filteredData.count
        }
        
        return data.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        let fruit: String
        if isFiltering() {
            fruit = filteredData[indexPath.row]
        } else {
            fruit = data[indexPath.row]
        }
        cell.textLabel?.text = fruit
        return cell
    }
}

extension MenuTableViewController : UISearchResultsUpdating {
    
    func updateSearchResults(for searchController: UISearchController) {
        let searchBar = searchController.searchBar
        filterContentForSearchText(searchBar.text!)
    }
    
    func searchBarIsEmpty() -> Bool {
        return searchController.searchBar.text?.isEmpty ?? true
    }
    
    func isFiltering() -> Bool {
        return searchController.isActive && !searchBarIsEmpty()
    }
}
