//
//  MenuViewController.swift
//  vyay
//
//  Created by Vishal Dharankar on 16/06/24.
//

import UIKit
import CoreData

protocol MenuViewControllerDelegate: AnyObject {
    func menuDidSelectList(_ list: Lists)
    func menuDidUpdateLists(selectedListDeleted: Bool)
    func menuDidClose()
}

class MenuViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    var lists: [Lists] = []
    weak var delegate: MenuViewControllerDelegate?
    var selectedList: Lists? // Track the currently selected list

    @IBOutlet var searchTextField: UITextField!
    @IBOutlet var listTableView: UITableView!
    @IBOutlet var addImageView : UIImageView!

    override func viewDidLoad() {
        super.viewDidLoad()
        let backButton = UIBarButtonItem(image: UIImage(named: "back"), style: .plain, target: self, action: #selector(onBackTap))
        self.navigationItem.leftBarButtonItem = backButton

        self.navigationController?.navigationBar.tintColor = UIColor(rgb:0x662CAA)
        styleControls()

        listTableView.delegate = self
        listTableView.dataSource = self
        addDummyListsIfNeeded()
        fetchLists()
        
        // Enable tap gesture on addImageView
        addImageView.isUserInteractionEnabled = true
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(onAddListTap))
        addImageView.addGestureRecognizer(tapGesture)
    }

    func addDummyListsIfNeeded() {
        let existingLists = ListsManager.shared.fetchAllLists()
        print("Checking for default lists...")
        
        // Check if "All Expenses" exists
        let hasDefaultList = existingLists.contains { $0.name == "All Expenses" }
        
        if !hasDefaultList {
            print("Creating default 'All Expenses' list...")
            _ = ListsManager.shared.addList(name: "All Expenses", total: 0.0)
        }
        
        // Only add example lists if there are no lists at all
        if existingLists.isEmpty {
            print("Adding example lists...")
            _ = ListsManager.shared.addList(name: "Groceries", total: 0.0)
            _ = ListsManager.shared.addList(name: "Work", total: 0.0)
            _ = ListsManager.shared.addList(name: "Travel", total: 0.0)
            _ = ListsManager.shared.addList(name: "Personal", total: 0.0)
        }
        
        // Print all available lists
        let allLists = ListsManager.shared.fetchAllLists()
        print("Available lists:")
        for list in allLists {
            print("- \(list.name ?? "unnamed")")
        }
    }

    func fetchLists() {
        lists = ListsManager.shared.fetchAllLists()
        // Update totals for each list using existing manager methods
        for list in lists {
            if let listName = list.name {
                let total = ExpenseManager.shared.calculateTotalForList(listName: listName)
                ListsManager.shared.editList(list: list, newName: nil, newTotal: total)
            }
        }
        // Fetch updated lists
        lists = ListsManager.shared.fetchAllLists()
        listTableView.reloadData()
    }

    func styleControls() {
        searchTextField.layer.cornerRadius = 10
        searchTextField.layer.borderWidth = 1
        searchTextField.layer.borderColor = UIColor(rgb:0x662CAA).cgColor
    }

    @IBAction func onBackTap() {
        delegate?.menuDidClose()
        navigationController?.popViewController(animated: true)
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return lists.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ListCell", for: indexPath) as! MenuItemCell
        let list = lists[indexPath.row]
        cell.menuTitle.text = list.name ?? "No Name"
        let currencySymbol = UserDefaults.standard.string(forKey: "currencySymbol") ?? "$"
        cell.menuSubtitle.text = String(format: "%@%.2f", currencySymbol, list.total)
        return cell
    }

    @IBAction func onTapCancel() {
        delegate?.menuDidClose()
        dismiss(animated: true)
    }

    func isValidListName(_ name: String) -> (Bool, String?) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            return (false, "List name cannot be empty.")
        }
        if trimmed.count < 3 {
            return (false, "List name must be at least 3 characters long.")
        }
        let allowed = CharacterSet.alphanumerics.union(.whitespaces)
        if trimmed.rangeOfCharacter(from: allowed.inverted) != nil {
            return (false, "List name can only contain letters, numbers, and spaces.")
        }
        return (true, nil)
    }

    @IBAction func onAddListTap() {
        let themeColor = UIColor(rgb:0x662CAA)
        let latoTitle = NSAttributedString(string: "New List", attributes: [
            .font: UIFont(name: "Lato-Regular", size: 18) ?? UIFont.systemFont(ofSize: 18),
            .foregroundColor: themeColor
        ])
        let latoMessage = NSAttributedString(string: "Enter a name for your new list", attributes: [
            .font: UIFont(name: "Lato-Regular", size: 16) ?? UIFont.systemFont(ofSize: 16),
            .foregroundColor: UIColor.darkGray
        ])
        let alert = UIAlertController(title: "", message: "", preferredStyle: .alert)
        alert.setValue(latoTitle, forKey: "attributedTitle")
        alert.setValue(latoMessage, forKey: "attributedMessage")
        alert.addTextField { textField in
            textField.placeholder = "List name"
            textField.font = UIFont(name: "Lato-Regular", size: 16)
            textField.defaultTextAttributes = [
                .font: UIFont(name: "Lato-Regular", size: 16) ?? UIFont.systemFont(ofSize: 16)
            ]
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        cancelAction.setValue(themeColor, forKey: "titleTextColor")
        let createAction = UIAlertAction(title: "Create", style: .default, handler: { [weak self] _ in
            guard let self = self else { return }
            if let listName = alert.textFields?.first?.text {
                let (isValid, errorMsg) = self.isValidListName(listName)
                if !isValid {
                    let errorTitle = NSAttributedString(string: "Invalid Name", attributes: [
                        .font: UIFont(name: "Lato-Regular", size: 18) ?? UIFont.systemFont(ofSize: 18),
                        .foregroundColor: themeColor
                    ])
                    let errorMessage = NSAttributedString(string: errorMsg ?? "", attributes: [
                        .font: UIFont(name: "Lato-Regular", size: 16) ?? UIFont.systemFont(ofSize: 16),
                        .foregroundColor: UIColor.darkGray
                    ])
                    let errorAlert = UIAlertController(title: "", message: "", preferredStyle: .alert)
                    errorAlert.setValue(errorTitle, forKey: "attributedTitle")
                    errorAlert.setValue(errorMessage, forKey: "attributedMessage")
                    let okAction = UIAlertAction(title: "OK", style: .default, handler: { _ in
                        self.present(alert, animated: true) // Re-present the original alert
                    })
                    okAction.setValue(themeColor, forKey: "titleTextColor")
                    errorAlert.addAction(okAction)
                    self.present(errorAlert, animated: true)
                    return
                }
                _ = ListsManager.shared.addList(name: listName.trimmingCharacters(in: .whitespacesAndNewlines), total: 0.0)
                self.fetchLists()
            }
        })
        createAction.setValue(themeColor, forKey: "titleTextColor")
        alert.addAction(cancelAction)
        alert.addAction(createAction)
        present(alert, animated: true)
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedList = lists[indexPath.row]
        print("Selected list: \(selectedList.name ?? "")")
        self.selectedList = selectedList // Track the selected list
        // Notify delegate
        delegate?.menuDidSelectList(selectedList)
        // Close the menu
        print("Dismissing menu view...")
        if let navigationController = self.navigationController {
            delegate?.menuDidClose()
            navigationController.popViewController(animated: true)
        } else {
            delegate?.menuDidClose()
            dismiss(animated: true)
        }
        print("Menu view dismissed")
    }

    // MARK: - UITableView Editing (Swipe to Delete for Lists)
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let listToDelete = lists[indexPath.row]
            let themeColor = UIColor(rgb:0x662CAA)
            let latoTitle = NSAttributedString(string: "Delete List", attributes: [
                .font: UIFont(name: "Lato-Regular", size: 18) ?? UIFont.systemFont(ofSize: 18),
                .foregroundColor: themeColor
            ])
            let latoMessage = NSAttributedString(string: "Are you sure you want to delete this list and all its expenses?", attributes: [
                .font: UIFont(name: "Lato-Regular", size: 16) ?? UIFont.systemFont(ofSize: 16),
                .foregroundColor: UIColor.darkGray
            ])
            let alert = UIAlertController(
                title: "",
                message: "",
                preferredStyle: .actionSheet
            )
            alert.setValue(latoTitle, forKey: "attributedTitle")
            alert.setValue(latoMessage, forKey: "attributedMessage")
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
            cancelAction.setValue(themeColor, forKey: "titleTextColor")
            let deleteAction = UIAlertAction(title: "Delete", style: .destructive, handler: { [weak self] _ in
                guard let self = self else { return }
                let wasSelectedList = (listToDelete == self.selectedList)
                // Remove associated expenses
                if let listName = listToDelete.name {
                    ExpenseManager.shared.deleteExpensesForList(listName: listName)
                }
                // Remove the list itself
                ListsManager.shared.deleteList(list: listToDelete)
                // Update local array and reload table
                self.lists.remove(at: indexPath.row)
                tableView.deleteRows(at: [indexPath], with: .automatic)
                // Notify delegate to reload lists and handle selection
                self.delegate?.menuDidUpdateLists(selectedListDeleted: wasSelectedList)
            })
            // Red color for delete is default for .destructive
            alert.addAction(cancelAction)
            alert.addAction(deleteAction)
            // iPad support
            if let popover = alert.popoverPresentationController {
                popover.sourceView = tableView
                popover.sourceRect = tableView.rectForRow(at: indexPath)
            }
            present(alert, animated: true)
        }
    }
}
