import UIKit
import CoreData

protocol EditExpenseViewControllerDelegate: AnyObject {
    func didUpdateExpense()
}

class EditExpenseViewController: UIViewController {
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var detailsTextField: UITextField!
    @IBOutlet weak var amountTextField: UITextField!
    @IBOutlet weak var categoryView: UIView!
    @IBOutlet weak var categoryLabel: UILabel!
    @IBOutlet weak var listView: UIView!
    @IBOutlet weak var listLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var updateButton: UIButton!
    @IBOutlet weak var expTableView: UITableView!
    @IBOutlet weak var expTableViewBottomConstraint: NSLayoutConstraint!
    
    var expense: Expense?
    weak var delegate: EditExpenseViewControllerDelegate?
    private var selectedCategory: Categories?
    private var selectedList: Lists?
    private var selectedDate: Date?
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd MMM yyyy"
        return formatter
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Track screen view
        AnalyticsManager.shared.trackScreen("Edit Expense", screenClass: "EditExpenseViewController")
        setupUI()
        setupGestures()
        loadExpenseData()
        setupNavigationBar()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        amountTextField.becomeFirstResponder()
    }
    
    private func setupNavigationBar() {
        // Set title
        title = "Edit Expense"
        
        // Set back button title
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "Edit Expense", style: .plain, target: nil, action: nil)
        
        // Set back button color
        navigationController?.navigationBar.tintColor = UIColor(rgb: 0x662CAA)
    }
    
    private func setupUI() {
        // Style text fields
        detailsTextField.layer.cornerRadius = 10
        detailsTextField.layer.borderColor = UIColor(rgb: 0x662CAA).cgColor
        
        amountTextField.layer.cornerRadius = 10
        amountTextField.layer.borderColor = UIColor(rgb: 0x662CAA).cgColor
        
        // Style views
        categoryView.layer.cornerRadius = 10
        listView.layer.cornerRadius = 10
        
        // Style update button
        updateButton.layer.cornerRadius = 25
        updateButton.backgroundColor = UIColor(rgb: 0x662CAA)
        updateButton.setTitleColor(.white, for: .normal)
        updateButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
    }
    
    private func setupGestures() {
        let categoryTap = UITapGestureRecognizer(target: self, action: #selector(categoryViewTapped))
        categoryView.isUserInteractionEnabled = true
        categoryView.addGestureRecognizer(categoryTap)
        
        let listTap = UITapGestureRecognizer(target: self, action: #selector(listViewTapped))
        listView.isUserInteractionEnabled = true
        listView.addGestureRecognizer(listTap)
        
        let dateTap = UITapGestureRecognizer(target: self, action: #selector(dateLabelTapped))
        dateLabel.isUserInteractionEnabled = true
        dateLabel.addGestureRecognizer(dateTap)
    }
    
    private func loadExpenseData() {
        guard let expense = expense else { return }
        
        detailsTextField.text = expense.details
        if let amount = expense.amount {
            amountTextField.text = String(format: "%.2f", amount.doubleValue)
        }
        
        // Load category
        if let catId = expense.catId,
           let category = CategoriesManager.shared.getCategory(id: catId) {
            categoryLabel.text = category.name
            selectedCategory = category
        }
        
        // Load list
        if let listName = expense.list {
            listLabel.text = listName
            // Find and set the selected list
            let lists = ListsManager.shared.fetchAllLists()
            selectedList = lists.first { $0.name == listName }
        } else {
            // Set default list as "All Expenses"
            listLabel.text = "All Expenses"
            let lists = ListsManager.shared.fetchAllLists()
            selectedList = lists.first { $0.name == "All Expenses" }
        }
        
        // Load date
        if let date = expense.date {
            dateLabel.text = dateFormatter.string(from: date)
            selectedDate = date
        }
    }
    
    @objc private func categoryViewTapped() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        guard let bottomSheet = storyboard.instantiateViewController(withIdentifier: "CategoriesBottomSheetViewController") as? CategoriesBottomSheetViewController else { return }
        
        bottomSheet.delegate = self
        if let sheet = bottomSheet.sheetPresentationController {
            sheet.detents = [.medium()]
            sheet.prefersGrabberVisible = true
        }
        
        present(bottomSheet, animated: true)
    }
    
    @objc private func listViewTapped() {
        print("List view tapped")
        
        // Add visual feedback
        UIView.animate(withDuration: 0.1, animations: {
            self.listView.alpha = 0.5
        }) { _ in
            UIView.animate(withDuration: 0.1) {
                self.listView.alpha = 1.0
            }
        }
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        guard let bottomSheet = storyboard.instantiateViewController(withIdentifier: "ListsBottomSheetViewController") as? ListsBottomSheetViewController else {
            print("Failed to instantiate ListsBottomSheetViewController")
            return
        }
        
        print("Successfully created bottom sheet")
        bottomSheet.delegate = self
        if let sheet = bottomSheet.sheetPresentationController {
            sheet.detents = [.medium()]
            sheet.prefersGrabberVisible = true
            print("Configured sheet presentation")
        }
        
        present(bottomSheet, animated: true)
        print("Presented bottom sheet")
    }
    
    @objc private func dateLabelTapped() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        guard let bottomSheet = storyboard.instantiateViewController(withIdentifier: "DatePickerBottomSheetViewController") as? DatePickerBottomSheetViewController else { return }
        
        bottomSheet.delegate = self
        bottomSheet.initialDate = selectedDate
        
        if let sheet = bottomSheet.sheetPresentationController {
            sheet.detents = [.medium()]
            sheet.prefersGrabberVisible = true
        }
        
        present(bottomSheet, animated: true)
    }
    
    @IBAction func updateButtonTapped(_ sender: Any) {
        guard let expense = expense,
              let details = detailsTextField.text,
              let amountText = amountTextField.text,
              let amount = Double(amountText),
              let category = selectedCategory,
              let list = selectedList,
              let listName = list.name,
              let date = selectedDate else {
            showErrorAlert(message: "Please fill all fields correctly")
            return
        }
        
        // Track expense edit
        if let oldAmount = expense.amount?.doubleValue {
            AnalyticsManager.shared.trackExpenseEdited(
                oldAmount: oldAmount,
                newAmount: amount,
                category: category.name ?? "",
                list: listName
            )
        }
        
        // Update expense
        if ExpenseManager.shared.updateExpense(
            expense: expense,
            details: details,
            amount: NSDecimalNumber(value: amount),
            date: date,
            catId: category.id ?? UUID(),
            list: listName
        ) {
            delegate?.didUpdateExpense()
            navigationController?.popViewController(animated: true)
        } else {
            showErrorAlert(message: "Failed to update expense")
        }
    }
    
    @IBAction func cancelButtonTapped(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    private func showErrorAlert(message: String) {
        let alert = UIAlertController(
            title: "Error",
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - UITextFieldDelegate
extension EditExpenseViewController: UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        // Implementation needed
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        // Implementation needed
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

// MARK: - CategoriesBottomSheetDelegate
extension EditExpenseViewController: CategoriesBottomSheetDelegate {
    func didSelectCategory(_ category: Categories) {
        selectedCategory = category
        categoryLabel.text = category.name
    }
}

// MARK: - ListsBottomSheetDelegate
extension EditExpenseViewController: ListsBottomSheetDelegate {
    func didSelectList(_ list: Lists) {
        selectedList = list
        listLabel.text = list.name
    }
}

// MARK: - DatePickerBottomSheetDelegate
extension EditExpenseViewController: DatePickerBottomSheetDelegate {
    func didSelectDate(_ date: Date) {
        selectedDate = date
        dateLabel.text = dateFormatter.string(from: date)
    }
} 
