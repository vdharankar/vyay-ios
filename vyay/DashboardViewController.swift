//
//  DashboardViewController.swift
//  vyay
//
//  Created by Vishal Dharankar on 15/06/24.
//

import UIKit
import SideMenu
import CoreData // Add this to use Core Data entities
import SwiftOpenAI

class DashboardViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, MenuViewControllerDelegate, UITextFieldDelegate {
   
    @IBOutlet var dateScroller : UICollectionView!
    @IBOutlet var dayScroller : UICollectionView!
    @IBOutlet var listView : UIView!
    @IBOutlet var dateLabel : UILabel!
    @IBOutlet var expTextField : UITextField!
    @IBOutlet var expTableView : UITableView!
    @IBOutlet var listLabel : UILabel!
    @IBOutlet weak var listNameLabel: UILabel!
    @IBOutlet weak var totalLabel : UILabel!
    @IBOutlet weak var addExpImageView : UIImageView!
    @IBOutlet weak var expTableViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var expInputView : UIView!
    @IBOutlet weak var expInputViewBottomConstraint: NSLayoutConstraint!
   
    
    var selectedDate : Date!
    var dates : [Date]!
    var days : [String]!
    var expenseList: [Expense] = []
    var categoriesDict: [UUID: Categories] = [:]
    var selectedList: Lists?
    var selectedExpense: Expense?
    
    private let selectedListKey = "selectedListName"
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd MMM yyyy"
        return formatter
    }()
    
    private var originalTableViewBottomConstraint: CGFloat = 0
    private var originalInputViewBottomConstraint: CGFloat = 0
    
    struct Config {
        // Static variable to access the OpenAI API key.
        static var openAIKey: String {
            get {
                // Attempt to find the path of 'Config.plist' in the main bundle.
                guard let filePath = Bundle.main.path(forResource: "Config", ofType: "plist") else {
                    // If the file is not found, crash with an error message.
                    fatalError("Couldn't find file 'Config.plist'.")
                }
                
                // Load the contents of the plist file into an NSDictionary.
                let plist = NSDictionary(contentsOfFile: filePath)
                
                // Attempt to retrieve the value for the 'OpenAI_API_Key' from the plist.
                guard let value = plist?.object(forKey: "OpenAI_API_Key") as? String else {
                    // If the key is not found in the plist, crash with an error message.
                    fatalError("Couldn't find key 'OpenAI_API_Key' in 'Config.plist'.")
                }
                
                // Return the API key.
                return value
            }
        }
    }
    
    func menuDidUpdateLists(selectedListDeleted: Bool) {
        menuDidClose()
    }

    private func getDefaultList() -> Lists? {
        let lists = ListsManager.shared.fetchAllLists()
        return lists.first { $0.name == "All Expenses" }
    }
    
    private func saveSelectedList(_ list: Lists) {
        if let listName = list.name {
            UserDefaults.standard.set(listName, forKey: selectedListKey)
        }
    }
    
    private func loadSavedList() -> Lists? {
        if let savedListName = UserDefaults.standard.string(forKey: selectedListKey) {
            let lists = ListsManager.shared.fetchAllLists()
            return lists.first { $0.name == savedListName }
        }
        return nil
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("DashboardViewController viewDidLoad started")
        
        // Store original constraint values
        originalTableViewBottomConstraint = expTableViewBottomConstraint.constant
        originalInputViewBottomConstraint = expInputViewBottomConstraint.constant
        
        // Add keyboard observers
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
        
        // Set return key as Done and set delegate
        expTextField.returnKeyType = .done
        expTextField.delegate = self
        
        // Initialize days array first
        days = ["S","M","T","W","T","F","S"]
        
        expTableView.delegate = self
        expTableView.dataSource = self
        dateScroller.dataSource = self
        dateScroller.delegate = self
        
        dayScroller.dataSource = self
        dayScroller.delegate = self
        
        // Add tap gesture to addExpImageView
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(addExpenseTapped))
        addExpImageView.isUserInteractionEnabled = true
        addExpImageView.addGestureRecognizer(tapGesture)
        
        dates = getAllDates(ofYear: 2025)
        selectedDate = Date() // Set today's date as selected
        dateLabel.text = dateFormatter.string(from: selectedDate)
        
        if let layout = dateScroller.collectionViewLayout as? UICollectionViewFlowLayout {
            layout.scrollDirection = .horizontal
            layout.minimumInteritemSpacing = 0
            layout.minimumLineSpacing = 0
        }
        
        if let layout = dayScroller.collectionViewLayout as? UICollectionViewFlowLayout {
            layout.scrollDirection = .horizontal
            layout.minimumInteritemSpacing = 0
            layout.minimumLineSpacing = 0
        }
        
        // Force layout update for collection views
        dateScroller.layoutIfNeeded()
        dayScroller.layoutIfNeeded()
        
        // Scroll to today's date
        if let todayIndex = findDateIndex(selectedDate) {
            let indexPath = IndexPath(item: todayIndex, section: 0)
            dateScroller.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: false)
            print("Scrolled date scroller to index: \(todayIndex)")
        }
        
        // Scroll day scroller to current day
        let calendar = Calendar.current
        let today = calendar.component(.weekday, from: Date())
        print("Current weekday from calendar: \(today)") // 1 = Sunday, 7 = Saturday
        
        // Our days array is ["S","M","T","W","T","F","S"]
        // So we need to map Calendar.weekday (1-7) to our array index (0-6)
        let dayIndex = today - 1
        print("Calculated day index: \(dayIndex)")
        
        // Verify the index is within bounds
        if dayIndex >= 0 && dayIndex < 7 {
            let dayIndexPath = IndexPath(item: dayIndex, section: 0)
            print("Scrolling day scroller to index: \(dayIndex)")
            dayScroller.scrollToItem(at: dayIndexPath, at: .centeredHorizontally, animated: false)
        } else {
            print("Invalid day index: \(dayIndex)")
        }
        
        // config view container for list combo
        listView.layer.cornerRadius = 12
        dateLabel.layer.cornerRadius = 12
        dateLabel.layer.masksToBounds = true
        
        expTextField.layer.cornerRadius = 10
        expTextField.layer.borderWidth = 1
        expTextField.layer.borderColor = UIColor(rgb:0x662CAA).cgColor
        
        print("Setting up Core Data...")
        // First add categories
        addDummyCategoriesIfNeeded()
        print("Categories setup complete")
        
        // Then add lists
        addDummyListsIfNeeded()
        print("Lists setup complete")
        
        // Then add expenses
        addDummyExpensesIfNeeded()
        print("Expenses setup complete")
        
        // Finally fetch and display data
        fetchCategories()
        
        // Load saved list or default to "All Expenses"
        if let savedList = loadSavedList() {
            selectedList = savedList
            print("Loaded saved list: \(savedList.name ?? "")")
        } else if let defaultList = getDefaultList() {
            selectedList = defaultList
            saveSelectedList(defaultList)
            print("Set default list: \(defaultList.name ?? "")")
        }
        
        listNameLabel.text = selectedList?.name ?? ""
        fetchExpenses()
        setupListViewTapGesture()
        print("DashboardViewController viewDidLoad completed")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Fetch the latest lists
        let lists = ListsManager.shared.fetchAllLists()
        // Check if selectedList still exists in lists
        if let selected = selectedList, lists.contains(where: { $0.objectID == selected.objectID }) {
            // Selected list still exists, update label and reload
            listNameLabel.text = selected.name
            fetchExpenses()
        } else {
            // Selected list was deleted, switch to All Expenses
            if let allExpenses = lists.first(where: { $0.name == "All Expenses" }) {
                selectedList = allExpenses
                listNameLabel.text = allExpenses.name
                fetchExpenses()
            } else if let firstList = lists.first {
                // Fallback: select the first available list
                selectedList = firstList
                listNameLabel.text = firstList.name
                fetchExpenses()
            } else {
                // No lists at all
                selectedList = nil
                listNameLabel.text = ""
                // Optionally clear the table view
                expenseList = []
                expTableView.reloadData()
            }
        }
    }
    
    // MARK: - UITextFieldDelegate
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self)
    }

    private func setupListViewTapGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(listViewTapped))
        listView.isUserInteractionEnabled = true
        listView.addGestureRecognizer(tapGesture)
    }

    @objc private func listViewTapped() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        // Cast to ListsBottomSheetViewController so you can set the delegate
        guard let bottomSheetVC = storyboard.instantiateViewController(withIdentifier: "ListsBottomSheetViewController") as? ListsBottomSheetViewController else { return }
        bottomSheetVC.delegate = self
        if let sheet = bottomSheetVC.sheetPresentationController {
            sheet.detents = [.medium(), .large()]
        }
        present(bottomSheetVC, animated: true)
    }

    @objc private func addExpenseTapped() {
        print("Add expense image tapped")
        if let text = expTextField.text, !text.isEmpty {
            Task {
                await runAI(text: text)
            }
        } else {
            // Show alert for empty text
            let alert = UIAlertController(
                title: "Error",
                message: "Please enter expense details",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
        }
        expTextField.resignFirstResponder()
    }

    func fetchCategories() {
        let allCategories = CategoriesManager.shared.getAllCategories()
        categoriesDict = [:]
        for category in allCategories {
            if let id = category.id {
                categoriesDict[id] = category
            }
        }
    }

    func fetchExpenses() {
        if let list = selectedList, let listName = list.name {
            print("Fetching expenses for list: \(listName) on date: \(dateFormatter.string(from: selectedDate))")
            
            // Use the new method to get expenses for the selected date
            expenseList = ExpenseManager.shared.getListItems(listName: listName, forDate: selectedDate)
            
            // Calculate daily and overall totals
            let dailyTotal = ExpenseManager.shared.calculateTotalForList(listName: listName, forDate: selectedDate)
            let overallTotal = ExpenseManager.shared.calculateTotalForList(listName: listName)
            let currencySymbol = UserDefaults.standard.string(forKey: "currencySymbol") ?? "$"
            // Update total label with both amounts
            totalLabel.text = String(format: "%@%.2f / %@%.2f", currencySymbol, dailyTotal, currencySymbol, overallTotal)
            
            print("Fetched \(expenseList.count) expenses for list: \(listName) on date: \(dateFormatter.string(from: selectedDate))")
            print("Daily total: $\(dailyTotal), Overall total: $\(overallTotal)")
            
            // Debug: Print each expense
            for expense in expenseList {
                print("Expense: \(expense.details ?? "no details") - Amount: \(expense.amount?.doubleValue ?? 0) - Date: \(expense.date?.description ?? "no date")")
            }
        } else {
            expenseList = []
            totalLabel.text = "$0.00 / $0.00"
            print("No selected list, no expenses loaded.")
        }
        expTableView.reloadData()
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        print("TableView numberOfRowsInSection: \(expenseList.count)")
        return expenseList.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ExpenseCell", for: indexPath) as! ExpenseItemCell
        let expense = expenseList[indexPath.row]
        let currencySymbol = UserDefaults.standard.string(forKey: "currencySymbol") ?? "$"
        cell.configure(with: expense, currencySymbol: currencySymbol)
        if let catId = expense.catId, let category = categoriesDict[catId] {
            cell.labelCategory.text = category.name ?? ""
        } else {
            cell.labelCategory.text = ""
        }
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 55.0
    }
    
    func processStatement(expStatement : String) {
        
        let tokens = expStatement.components(separatedBy: " ")
        // You can implement logic to create and add an Expense entity here if needed
    }
    @IBAction func menuClick() {
        performSegue(withIdentifier: "ShowMenuSegue",sender: self)
    }

    // Function to get all dates in a given year
    func getAllDates(ofYear year: Int) -> [Date] {
        var dates: [Date] = []
        let calendar = Calendar.current

        // Create the start date for the given year
        let startComponents = DateComponents(year: year, month: 1, day: 1)
        guard let startDate = calendar.date(from: startComponents) else {
            return dates
        }

        // Create the end date for the given year
        let endComponents = DateComponents(year: year + 1, month: 1, day: 1)
        guard let endDate = calendar.date(from: endComponents) else {
            return dates
        }

        // Calculate the number of days between start date and end date
        let numberOfDays = calendar.dateComponents([.day], from: startDate, to: endDate).day ?? 0

        // Iterate through each day of the year
        for day in 0..<numberOfDays {
            if let date = calendar.date(byAdding: .day, value: day, to: startDate) {
                dates.append(date)
            }
        }

        return dates
    }

    func addDummyCategoriesIfNeeded() {
        let existing = CategoriesManager.shared.getAllCategories()
        if existing.isEmpty {
            _ = CategoriesManager.shared.addCategory(name: "Food")
            _ = CategoriesManager.shared.addCategory(name: "Transport")
            _ = CategoriesManager.shared.addCategory(name: "Shopping")
        }
    }

    func addDummyExpensesIfNeeded() {
        print("Starting addDummyExpensesIfNeeded...")
        let existing = ExpenseManager.shared.getAllExpenses()
        print("Existing expenses count: \(existing.count)")
        
        // Delete existing expenses that have no list
        for expense in existing {
            if expense.list == nil || expense.list?.isEmpty == true {
                print("Deleting expense with no list: \(expense.details ?? "no details")")
                ExpenseManager.shared.deleteExpense(expense: expense)
            }
        }
        
        // Check if we need to add new expenses
        let remainingExpenses = ExpenseManager.shared.getAllExpenses()
        if remainingExpenses.isEmpty {
            print("No valid expenses found, adding dummy data...")
            let categories = CategoriesManager.shared.getAllCategories()
            let lists = ListsManager.shared.fetchAllLists()
            print("Available categories: \(categories.count), Available lists: \(lists.count)")
            
            guard categories.count >= 3, lists.count >= 2 else { 
                print("Not enough categories or lists to add dummy expenses.")
                return 
            }
            
            // Print list names for debugging
            print("Available lists:")
            for list in lists {
                print("- \(list.name ?? "unnamed")")
            }
            
            // Add expenses and store the results
            let exp1 = ExpenseManager.shared.addExpense(
                details: "Pizza",
                amount: NSDecimalNumber(value: 12.5),
                date: Date(),
                catId: categories[0].id!,
                list: lists[0].name ?? ""
            )
            print("Added expense 1: \(exp1 != nil) - List: \(lists[0].name ?? "")")
            
            let exp2 = ExpenseManager.shared.addExpense(
                details: "Coffee",
                amount: NSDecimalNumber(value: 3.0),
                date: Date(),
                catId: categories[0].id!,
                list: lists[0].name ?? ""
            )
            print("Added expense 2: \(exp2 != nil) - List: \(lists[0].name ?? "")")
            
            let exp3 = ExpenseManager.shared.addExpense(
                details: "Bus Ticket",
                amount: NSDecimalNumber(value: 2.75),
                date: Date(),
                catId: categories[1].id!,
                list: lists[1].name ?? ""
            )
            print("Added expense 3: \(exp3 != nil) - List: \(lists[1].name ?? "")")
            
            let exp4 = ExpenseManager.shared.addExpense(
                details: "T-shirt",
                amount: NSDecimalNumber(value: 25.0),
                date: Date(),
                catId: categories[2].id!,
                list: lists[1].name ?? ""
            )
            print("Added expense 4: \(exp4 != nil) - List: \(lists[1].name ?? "")")
            
            // Verify expenses were added
            let allExpenses = ExpenseManager.shared.getAllExpenses()
            print("Total expenses after adding: \(allExpenses.count)")
            for expense in allExpenses {
                print("Expense: \(expense.details ?? "no details") - List: \(expense.list ?? "no list")")
            }
        } else {
            print("Valid expenses already exist in database:")
            for expense in remainingExpenses {
                print("Expense: \(expense.details ?? "no details") - List: \(expense.list ?? "no list")")
            }
        }
    }

    func addDummyListsIfNeeded() {
        let existing = ListsManager.shared.fetchAllLists()
        if existing.isEmpty {
            _ = ListsManager.shared.addList(name: "Personal", total: 0)
            _ = ListsManager.shared.addList(name: "Work", total: 0)
        }
        print("Lists in DB:", ListsManager.shared.fetchAllLists().map { $0.name ?? "" })
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ShowMenuSegue" {
            if let menuVC = segue.destination as? MenuViewController {
                menuVC.delegate = self
            }
        } else if segue.identifier == "SegueEdit" {
            if let editVC = segue.destination as? EditExpenseViewController {
                editVC.expense = selectedExpense
                editVC.delegate = self
            }
        }
    }
    
    // Find index of a date in the dates array
    private func findDateIndex(_ date: Date) -> Int? {
        let calendar = Calendar.current
        return dates.firstIndex { calendar.isDate($0, inSameDayAs: date) }
    }
    
    // MARK: - MenuViewControllerDelegate
    func menuDidSelectList(_ list: Lists) {
        print("Dashboard received selected list from menu: \(list.name ?? "")")
        selectedList = list
        listNameLabel.text = list.name ?? ""
        saveSelectedList(list)
        fetchExpenses()
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedExpense = expenseList[indexPath.row]
        tableView.deselectRow(at: indexPath, animated: true)
        performSegue(withIdentifier: "SegueEdit", sender: self)
    }

    @objc private func keyboardWillShow(notification: NSNotification) {
        print("keyboardWillShow called")
        guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { 
            print("keyboardFrame not found in notification")
            return 
        }
        let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double ?? 0.25
        let safeAreaBottom = view.safeAreaInsets.bottom
        let adjustedKeyboardHeight = keyboardFrame.height - safeAreaBottom
        print("Keyboard frame: \(keyboardFrame), safeAreaBottom: \(safeAreaBottom), adjusted: \(adjustedKeyboardHeight)")
        UIView.animate(withDuration: duration) {
            self.expInputViewBottomConstraint.constant = adjustedKeyboardHeight
            print("Set expInputViewBottomConstraint.constant to \(self.expInputViewBottomConstraint.constant)")
            self.view.layoutIfNeeded()
        }
    }
    
    @objc private func keyboardWillHide(notification: NSNotification) {
        print("keyboardWillHide called")
        let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double ?? 0.25
        UIView.animate(withDuration: duration) {
            self.expInputViewBottomConstraint.constant = self.originalInputViewBottomConstraint
            print("Reset expInputViewBottomConstraint.constant to \(self.expInputViewBottomConstraint.constant)")
            self.view.layoutIfNeeded()
        }
    }

    // MARK: - UITableView Editing (Swipe to Delete with Confirmation)
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let expenseToDelete = expenseList[indexPath.row]
            let alert = UIAlertController(
                title: "Delete Expense",
                message: "Are you sure you want to delete this expense?",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            alert.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { _ in
                // Remove from Core Data (or your data source)
                ExpenseManager.shared.deleteExpense(expense: expenseToDelete)
                // Remove from local array
                self.expenseList.remove(at: indexPath.row)
                // Delete the row from the table view
                tableView.deleteRows(at: [indexPath], with: .automatic)
                // Optionally, update totals or UI
                self.fetchExpenses()
            }))
            present(alert, animated: true)
        }
    }

    func menuDidClose() {
        let lists = ListsManager.shared.fetchAllLists()
        if let selected = selectedList, lists.contains(where: { $0.objectID == selected.objectID }) {
            listNameLabel.text = selected.name
            fetchExpenses()
        } else {
            if let allExpenses = lists.first(where: { $0.name == "All Expenses" }) {
                selectedList = allExpenses
                listNameLabel.text = allExpenses.name
                fetchExpenses()
            } else if let firstList = lists.first {
                selectedList = firstList
                listNameLabel.text = firstList.name
                fetchExpenses()
            } else {
                selectedList = nil
                listNameLabel.text = ""
                expenseList = []
                expTableView.reloadData()
            }
        }
    }
}

extension DashboardViewController : UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        if(collectionView == dateScroller){
            return 365
        }
            else {
                return 7
        }
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        if(collectionView == dateScroller) {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "DateCell", for: indexPath) as! DateCollectionViewCell
            
            let date = dates[indexPath.item]
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "dd"
            cell.dateLabel.text = dateFormatter.string(from: date)
            dateFormatter.dateFormat = "E"
            
            let day = dateFormatter.string(from: date);
            let selectedDay = dateFormatter.string(from: selectedDate)
            
            if(selectedDay != day ) {
                cell.dateLabel.layer.borderColor = UIColor.clear.cgColor
            }
            else {
                cell.dateLabel.layer.borderColor = UIColor(rgb:0x662CAA).cgColor
            }
            
            return cell
        }
        else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "DayCell", for: indexPath) as! DateCollectionViewCell
            
            let day = days[indexPath.item]
            cell.dayLabel.text = day
            
            return cell
        }
    }
    
   
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if collectionView == dateScroller {
            selectedDate = dates[indexPath.item]
            dateScroller.reloadData()
            print("Selected date: \(selectedDate)")
            dateLabel.text = dateFormatter.string(from: selectedDate)
            
            // Refresh expenses for the new date
            fetchExpenses()
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
            let cellWidth = collectionView.bounds.width / 7  // Show 7 days at a time
            print("Setting cell size to: \(cellWidth)x\(collectionView.bounds.height)")  // Debugging output
            return CGSize(width: cellWidth, height: collectionView.bounds.height)
    }
    
    func normalizeDate(_ date: Date) -> Date? {
        let calendar = Calendar.current
        return calendar.date(from: calendar.dateComponents([.year, .month, .day], from: date))
    }

    // Function to compare two dates for equality excluding time
    func areDatesEqualExcludingTime(_ date1: Date, _ date2: Date) -> Bool {
        guard let normalizedDate1 = normalizeDate(date1), let normalizedDate2 = normalizeDate(date2) else {
            return false
        }
        return normalizedDate1 == normalizedDate2
    }
    func runAI(text:String) async {
        
        var chat = "\(text) - identify category of expense,cost,item in response precisely with comma separated string format, keep all words small letters, dont add currency symbol , return result as a perfect JSON, all JSON keys should be string"
        
        var openAI = SwiftOpenAI(apiKey: Config.openAIKey)
        // Define an array of MessageChatGPT objects representing the conversation.
        let messages: [MessageChatGPT] = [
            // A system message to set the context or role of the assistant.
            MessageChatGPT(text: "Want analyze expenses", role: .user),
            // A user message asking a question.
            MessageChatGPT(text: chat, role: .user)
        ]

        // Define optional parameters for the chat completion request.
        let optionalParameters = ChatCompletionsOptionalParameters(
            temperature: 0.7, // Set the creativity level of the response.
            maxTokens: 50 // Limit the maximum number of tokens (words) in the response.
        )

        do {
            // Request chat completions from the OpenAI API.
            let chatCompletions = try await openAI.createChatCompletions(
                model: .gpt4o(.gpt_4o_2024_05_13), // Specify the model, here GPT-4 base model.
                messages: messages, // Provide the conversation messages.
                optionalParameters: optionalParameters // Include the optional parameters.
            )
            if let content = chatCompletions?.choices.first?.message.content {
                // Remove all occurrences of "'" and "json"
                let cleaned = content.replacingOccurrences(of: "`", with: "")
                                     .replacingOccurrences(of: "json", with: "")
                print("Response: \(cleaned)")
                
                // Validate JSON
                if let jsonData = cleaned.data(using: .utf8) {
                    do {
                        // Try to parse the JSON
                        if let json = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
                           let category = json["category"] as? String,
                           let cost = json["cost"] as? String,
                           let item = json["item"] as? String,
                           let amount = Double(cost),
                           let selectedList = self.selectedList,
                           let listName = selectedList.name {
                            
                            // Check if category exists, if not create it
                            let categories = CategoriesManager.shared.getAllCategories()
                            let existingCategory = categories.first { $0.name?.lowercased() == category.lowercased() }
                            
                            let categoryId: UUID
                            if let existing = existingCategory {
                                categoryId = existing.id!
                                print("Using existing category: \(existing.name ?? "")")
                            } else {
                                // Create new category
                                print("Creating new category: \(category)")
                                if let newCategory = CategoriesManager.shared.addCategory(name: category.capitalized) {
                                    categoryId = newCategory.id!
                                    print("Successfully created category: \(newCategory.name ?? "")")
                                } else {
                                    showErrorAlert(message: "Failed to create category")
                                    return
                                }
                            }
                            
                            // Add the expense
                            let expense = ExpenseManager.shared.addExpense(
                                details: item,
                                amount: NSDecimalNumber(value: amount),
                                date: self.selectedDate,
                                catId: categoryId,
                                list: listName
                            )
                            
                            if expense != nil {
                                print("Successfully added expense: \(item) - $\(amount) in category: \(category)")
                                // Clear the text field and refresh data
                                DispatchQueue.main.async {
                                    self.expTextField.text = ""
                                    self.fetchCategories() // Refresh categories first
                                    self.fetchExpenses() // Then refresh expenses
                                }
                            } else {
                                showErrorAlert(message: "Failed to add expense")
                            }
                        } else {
                            showErrorAlert(message: "Please describe your expense correctly.")
                        }
                    } catch {
                        showErrorAlert(message: "Error has ocurred with AI agent, please try again.")
                    }
                } else {
                    showErrorAlert(message: "Please describe your expense correctly.")
                }
            } else {
                showErrorAlert(message: "Please describe your expense correctly.")
            }
        } catch {
            showErrorAlert(message: "Please describe your expense correctly.")
        }
    }
    
    private func showErrorAlert(message: String) {
        DispatchQueue.main.async {
            let alert = UIAlertController(
                title: "Error",
                message: message,
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            self.present(alert, animated: true)
        }
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView == dateScroller {
            let centerPoint = view.convert(dateScroller.center, to: dateScroller)
            if let indexPath = dateScroller.indexPathForItem(at: centerPoint) {
                let centerDate = dates[indexPath.item]
                dateLabel.text = dateFormatter.string(from: centerDate)
            }
        }
    }
}

extension String  {
    var isNumber: Bool {
        return !isEmpty && rangeOfCharacter(from: CharacterSet.decimalDigits.inverted) == nil
    }
}

// Make sure DashboardViewController conforms to ListsBottomSheetDelegate
extension DashboardViewController: ListsBottomSheetDelegate {
    func didSelectList(_ list: Lists) {
        selectedList = list
        listNameLabel.text = list.name ?? ""
        saveSelectedList(list) // Save the selected list
        fetchExpenses()
    }
}

// MARK: - EditExpenseViewControllerDelegate
extension DashboardViewController: EditExpenseViewControllerDelegate {
    func didUpdateExpense() {
        fetchExpenses()
    }
}

