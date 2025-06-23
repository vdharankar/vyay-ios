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
import Instructions
import ObjectiveC

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
    @IBOutlet weak var expTodayTotal : UILabel!
   
    
    var selectedDate : Date!
    var dates : [Date]!
    var days : [String]!
    var expenseList: [Expense] = []
    var categoriesDict: [UUID: Categories] = [:]
    var selectedList: Lists?
    var selectedExpense: Expense?
    
    private let hasSeenTourKey = "hasSeenTour" // Add key for tracking tour status
    private let selectedListKey = "selectedListName" // Move this back inside the class
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd MMM yyyy"
        return formatter
    }()
    
    private var originalTableViewBottomConstraint: CGFloat = 0
    private var originalInputViewBottomConstraint: CGFloat = 0
    
    let coachMarksController = CoachMarksController()
    
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Track screen view
        AnalyticsManager.shared.trackScreen("Dashboard", screenClass: "DashboardViewController")
        print("DashboardViewController viewDidLoad started")
        
        // Store original constraint values
        originalTableViewBottomConstraint = expTableViewBottomConstraint.constant
        originalInputViewBottomConstraint = expInputViewBottomConstraint.constant
        
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
        
        // Get today's date and set it as selected
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        selectedDate = today
        print("Setting selected date to: \(dateFormatter.string(from: today))")
        dateLabel.text = dateFormatter.string(from: today)
        
        // Generate dates for the current year
        let currentYear = calendar.component(.year, from: today)
        print("Generating dates for year: \(currentYear)")
        dates = getAllDates(ofYear: currentYear)
        
        // Configure collection view layouts
        if let dateLayout = dateScroller.collectionViewLayout as? UICollectionViewFlowLayout {
            dateLayout.scrollDirection = .horizontal
            dateLayout.minimumInteritemSpacing = 0
            dateLayout.minimumLineSpacing = 0
            dateLayout.estimatedItemSize = UICollectionViewFlowLayout.automaticSize
        }
        
        if let dayLayout = dayScroller.collectionViewLayout as? UICollectionViewFlowLayout {
            dayLayout.scrollDirection = .horizontal
            dayLayout.minimumInteritemSpacing = 0
            dayLayout.minimumLineSpacing = 0
            dayLayout.estimatedItemSize = UICollectionViewFlowLayout.automaticSize
        }
        
        // Force layout update for collection views
        dateScroller.layoutIfNeeded()
        dayScroller.layoutIfNeeded()
        
        // Scroll to today's date
        if let todayIndex = findDateIndex(today) {
            print("Scrolling date scroller to index: \(todayIndex)")
            let indexPath = IndexPath(item: todayIndex, section: 0)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.dateScroller.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: false)
                self.dateScroller.reloadData()
            }
        }
        
        // Scroll day scroller to current day
        let weekday = calendar.component(.weekday, from: today)
        let dayIndex = weekday - 1
        if dayIndex >= 0 && dayIndex < 7 {
            let dayIndexPath = IndexPath(item: dayIndex, section: 0)
            print("Scrolling day scroller to index: \(dayIndex)")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.dayScroller.scrollToItem(at: dayIndexPath, at: .centeredHorizontally, animated: false)
                self.dayScroller.reloadData()
            }
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
        setupDateLabelTapGesture()
        print("DashboardViewController viewDidLoad completed")
        
        coachMarksController.dataSource = self
        coachMarksController.delegate = self
        
        // Configure a simple semi-transparent gray overlay
        coachMarksController.overlay.backgroundColor = UIColor.gray.withAlphaComponent(0.3)
        coachMarksController.overlay.blurEffectStyle = nil
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // Add keyboard observers
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillShow),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillHide),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
        
        // Show the tour only if user hasn't seen it before
        if !UserDefaults.standard.bool(forKey: hasSeenTourKey) {
            coachMarksController.start(in: .window(over: self))
            // Mark that user has seen the tour
            UserDefaults.standard.set(true, forKey: hasSeenTourKey)
        }
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
        expTextField.resignFirstResponder()
        
        UIView.animate(withDuration: 0.5) {
            // Only adjust the bottom constraints
            self.expInputViewBottomConstraint.constant = self.originalInputViewBottomConstraint
            self.expTableViewBottomConstraint.constant = self.originalTableViewBottomConstraint
            self.view.layoutIfNeeded()
        }
    }

    private func setupListViewTapGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(listViewTapped))
        listView.isUserInteractionEnabled = true
        listView.addGestureRecognizer(tapGesture)
    }

    private func setupDateLabelTapGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dateLabelTapped))
        dateLabel.isUserInteractionEnabled = true
        dateLabel.addGestureRecognizer(tapGesture)
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
    
    @objc private func dateLabelTapped() {
        showDateSelectorBottomSheet()
    }
    
    private func showDateSelectorBottomSheet() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        guard let datePickerVC = storyboard.instantiateViewController(withIdentifier: "DatePickerBottomSheetViewController") as? DatePickerBottomSheetViewController else { return }
        datePickerVC.initialDate = selectedDate
        datePickerVC.delegate = self
        if let sheet = datePickerVC.sheetPresentationController {
            sheet.detents = [.medium()]
            sheet.prefersGrabberVisible = true
        }
        present(datePickerVC, animated: true)
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
            
            // Update total label with list total (overall total)
            totalLabel.text = String(format: "%@%.2f", currencySymbol, overallTotal)
            
            // Update today's total label
            expTodayTotal.text = String(format: "%@%.2f", currencySymbol, dailyTotal)
            
            print("Fetched \(expenseList.count) expenses for list: \(listName) on date: \(dateFormatter.string(from: selectedDate))")
            print("Daily total: \(currencySymbol)\(dailyTotal), Overall total: \(currencySymbol)\(overallTotal)")
            
            // Debug: Print each expense
            for expense in expenseList {
                print("Expense: \(expense.details ?? "no details") - Amount: \(expense.amount?.doubleValue ?? 0) - Date: \(expense.date?.description ?? "no date")")
            }
        } else {
            expenseList = []
            let currencySymbol = UserDefaults.standard.string(forKey: "currencySymbol") ?? "$"
            totalLabel.text = String(format: "%@0.00", currencySymbol)
            expTodayTotal.text = String(format: "%@0.00", currencySymbol)
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
            print("Failed to create start date for year \(year)")
            return dates
        }

        // Get the weekday of January 1st (1 = Sunday, 2 = Monday, etc.)
        let firstWeekday = calendar.component(.weekday, from: startDate)
        
        // Calculate how many days we need to go back to reach the previous Sunday
        let daysToSubtract = firstWeekday - 1 // If firstWeekday is 1 (Sunday), we don't need to go back
        
        // Create a date for the previous year's last Sunday
        guard let previousSunday = calendar.date(byAdding: .day, value: -daysToSubtract, to: startDate) else {
            print("Failed to calculate previous Sunday")
            return dates
        }
        
        // Create the end date for the given year
        let endComponents = DateComponents(year: year + 1, month: 1, day: 1)
        guard let endDate = calendar.date(from: endComponents) else {
            print("Failed to create end date for year \(year)")
            return dates
        }

        // Calculate the number of days between previous Sunday and end date
        let numberOfDays = calendar.dateComponents([.day], from: previousSunday, to: endDate).day ?? 0
        print("Generating \(numberOfDays) dates starting from: \(dateFormatter.string(from: previousSunday))")

        // Iterate through each day from previous Sunday to end of year
        for day in 0..<numberOfDays {
            if let date = calendar.date(byAdding: .day, value: day, to: previousSunday) {
                dates.append(date)
            }
        }

        print("Generated \(dates.count) dates")
        if let firstDate = dates.first {
            print("First date: \(dateFormatter.string(from: firstDate))")
        }
        if let lastDate = dates.last {
            print("Last date: \(dateFormatter.string(from: lastDate))")
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
            
            // Get today's date for dummy expenses
            let today = Date()
            
            // Add expenses and store the results
            let exp1 = ExpenseManager.shared.addExpense(
                details: "Pizza",
                amount: NSDecimalNumber(value: 255.0),
                date: today,
                catId: categories[0].id!,
                list: lists[0].name ?? ""
            )
            print("Added expense 1: \(exp1 != nil) - List: \(lists[0].name ?? "")")
            
            let exp2 = ExpenseManager.shared.addExpense(
                details: "Coffee",
                amount: NSDecimalNumber(value: 100.0),
                date: today,
                catId: categories[0].id!,
                list: lists[0].name ?? ""
            )
            print("Added expense 2: \(exp2 != nil) - List: \(lists[0].name ?? "")")
            
            let exp3 = ExpenseManager.shared.addExpense(
                details: "Bus Ticket",
                amount: NSDecimalNumber(value: 25.0),
                date: today,
                catId: categories[1].id!,
                list: lists[1].name ?? ""
            )
            print("Added expense 3: \(exp3 != nil) - List: \(lists[1].name ?? "")")
            
            let exp4 = ExpenseManager.shared.addExpense(
                details: "T-shirt",
                amount: NSDecimalNumber(value: 450.0),
                date: today,
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
        print("Checking for default lists...")
        
        // Check if "All Expenses" exists
        let hasDefaultList = existing.contains { $0.name == "All Expenses" }
        
        if !hasDefaultList {
            print("Creating default 'All Expenses' list...")
            _ = ListsManager.shared.addList(name: "All Expenses", total: 0)
        }
        
        // Only add example lists if there are no lists at all
        if existing.isEmpty {
            print("Adding example lists...")
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
        } else if segue.identifier == "ShowSettingsSegue" {
            // Handle settings button tap
            if let settingsVC = segue.destination as? UINavigationController {
                // Add a button to show privacy policy
                let privacyButton = UIBarButtonItem(
                    title: "Privacy Policy",
                    style: .plain,
                    target: self,
                    action: #selector(showPrivacyPolicy)
                )
                privacyButton.tintColor = UIColor(rgb: 0x662CAA)
                settingsVC.topViewController?.navigationItem.rightBarButtonItem = privacyButton
            }
        }
    }
    
    // Find index of a date in the dates array
    private func findDateIndex(_ date: Date) -> Int? {
        let calendar = Calendar.current
        let normalizedDate = calendar.startOfDay(for: date)
        let index = dates.firstIndex { calendar.isDate($0, inSameDayAs: normalizedDate) }
        print("Finding index for date: \(dateFormatter.string(from: date))")
        print("Found index: \(index ?? -1)")
        return index
    }
    
    // MARK: - MenuViewControllerDelegate
    func menuDidSelectList(_ list: Lists) {
        print("Dashboard received selected list from menu: \(list.name ?? "")")
        // Track list switch
        if let oldList = selectedList?.name,
           let newList = list.name {
            AnalyticsManager.shared.trackListSwitched(fromList: oldList, toList: newList)
        }
        selectedList = list
        listNameLabel.text = list.name ?? ""
        saveSelectedList(list)
        fetchExpenses()
    }

    func menuDidUpdateLists(selectedListDeleted: Bool) {
        menuDidClose()
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

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedExpense = expenseList[indexPath.row]
        tableView.deselectRow(at: indexPath, animated: true)
        performSegue(withIdentifier: "SegueEdit", sender: self)
    }

    @objc private func keyboardWillShow(notification: NSNotification) {
        guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
              let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double else {
            return
        }

        let safeAreaBottom = view.safeAreaInsets.bottom
        let adjustedKeyboardHeight = keyboardFrame.height - safeAreaBottom
        
        UIView.animate(withDuration: duration) {
            // Only adjust the bottom constraints
            self.expInputViewBottomConstraint.constant = adjustedKeyboardHeight
            self.view.layoutIfNeeded()
        }
    }
    
    @objc private func keyboardWillHide(notification: NSNotification) {
        guard let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double else {
            return
        }
        
        UIView.animate(withDuration: duration) {
            // Only adjust the bottom constraints
            self.expInputViewBottomConstraint.constant = self.originalInputViewBottomConstraint
            self.expTableViewBottomConstraint.constant = self.originalTableViewBottomConstraint
            self.view.layoutIfNeeded()
        }
    }

    @objc private func showPrivacyPolicy() {
        let privacyVC = PrivacyPolicyViewController()
        let navController = UINavigationController(rootViewController: privacyVC)
        
        // Add a close button
        let closeButton = UIBarButtonItem(
            barButtonSystemItem: .close,
            target: self,
            action: #selector(dismissPrivacyPolicy)
        )
        closeButton.tintColor = UIColor(rgb: 0x662CAA)
        privacyVC.navigationItem.leftBarButtonItem = closeButton
        
        // Set the title
        privacyVC.title = "Privacy Policy"
        
        // Present the privacy policy
        present(navController, animated: true)
    }
    
    @objc private func dismissPrivacyPolicy() {
        dismiss(animated: true)
    }

    func runAI(text: String) async {
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
                                // Track AI expense processed
                                AnalyticsManager.shared.trackAIExpenseProcessed(
                                    success: true,
                                    inputText: text
                                )
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
            alert.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { [weak self] _ in
                guard let self = self else { return }
                // Track expense deletion
                if let amount = expenseToDelete.amount?.doubleValue,
                   let category = self.categoriesDict[expenseToDelete.catId ?? UUID()]?.name,
                   let list = expenseToDelete.list {
                    AnalyticsManager.shared.trackExpenseDeleted(amount: amount, category: category, list: list)
                }
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
}

extension DashboardViewController : UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView == dateScroller {
            print("Date scroller items count: \(dates.count)")
            return dates.count
        } else {
            print("Day scroller items count: \(days.count)")
            return days.count
        }
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if collectionView == dateScroller {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "DateCell", for: indexPath) as! DateCollectionViewCell
            
            let date = dates[indexPath.item]
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "dd"
            cell.dateLabel.text = dateFormatter.string(from: date)
            
            // Check if this date is today
            let calendar = Calendar.current
            let isToday = calendar.isDateInToday(date)
            let isSelected = calendar.isDate(date, inSameDayAs: selectedDate)
            
            if isToday {
                cell.dateLabel.layer.borderWidth = 2
                cell.dateLabel.layer.borderColor = UIColor(rgb:0x662CAA).cgColor
                cell.dateLabel.backgroundColor = UIColor(rgb:0x662CAA).withAlphaComponent(0.1)
            } else if isSelected {
                cell.dateLabel.layer.borderWidth = 1
                cell.dateLabel.layer.borderColor = UIColor(rgb:0x662CAA).cgColor
                cell.dateLabel.backgroundColor = .clear
            } else {
                cell.dateLabel.layer.borderWidth = 0
                cell.dateLabel.layer.borderColor = UIColor.clear.cgColor
                cell.dateLabel.backgroundColor = .clear
            }
            
            print("Date cell at \(indexPath.item): \(dateFormatter.string(from: date)), isToday: \(isToday), isSelected: \(isSelected)")
            return cell
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "DayCell", for: indexPath) as! DateCollectionViewCell
            
            let day = days[indexPath.item]
            cell.dayLabel.text = day
            
            // Highlight current day
            let calendar = Calendar.current
            let today = calendar.component(.weekday, from: Date())
            let isCurrentDay = (indexPath.item + 1) == today
            
            if isCurrentDay {
                cell.dayLabel.textColor = UIColor(rgb:0x662CAA)
                cell.dayLabel.font = UIFont.boldSystemFont(ofSize: cell.dayLabel.font.pointSize)
            } else {
                cell.dayLabel.textColor = .black
                cell.dayLabel.font = UIFont.systemFont(ofSize: cell.dayLabel.font.pointSize)
            }
            
            print("Day cell at \(indexPath.item): \(day), isCurrentDay: \(isCurrentDay)")
            return cell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let cellWidth = collectionView.bounds.width / 7  // Show 7 days at a time
        print("Setting cell size to: \(cellWidth)x\(collectionView.bounds.height)")
        return CGSize(width: cellWidth, height: collectionView.bounds.height)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if collectionView == dateScroller {
            selectedDate = dates[indexPath.item]
            print("Selected date: \(dateFormatter.string(from: selectedDate))")
            dateScroller.reloadData()
            dateLabel.text = dateFormatter.string(from: selectedDate)
            // Track date change
            AnalyticsManager.shared.trackDateChanged(date: selectedDate)
            fetchExpenses()
        }
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView == dateScroller {
            let centerPoint = CGPoint(x: scrollView.center.x + scrollView.contentOffset.x, y: scrollView.center.y)
            if let indexPath = dateScroller.indexPathForItem(at: centerPoint) {
                let centerDate = dates[indexPath.item]
                if !Calendar.current.isDate(centerDate, inSameDayAs: selectedDate) {
                    selectedDate = centerDate
                    dateLabel.text = dateFormatter.string(from: centerDate)
                    // Track date change
                    AnalyticsManager.shared.trackDateChanged(date: centerDate)
                    print("Scrolled to date: \(dateFormatter.string(from: centerDate))")
                    fetchExpenses()
                }
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

// MARK: - Instructions Guided Tour
extension DashboardViewController: CoachMarksControllerDataSource, CoachMarksControllerDelegate {
    func numberOfCoachMarks(for coachMarksController: CoachMarksController) -> Int {
        return 8 // Now showing 8 coach marks including the total labels
    }

    func coachMarksController(_ coachMarksController: CoachMarksController, coachMarkAt index: Int) -> CoachMark {
        var coachMark = CoachMark()
        
        switch index {
        case 0:
            // List view coach mark
            coachMark = coachMarksController.helper.makeCoachMark(
                for: listView,
                cutoutPathMaker: { frame in
                    return UIBezierPath(roundedRect: frame.insetBy(dx: -8, dy: -8),
                                      byRoundingCorners: .allCorners,
                                      cornerRadii: CGSize(width: 8, height: 8))
                }
            )
        case 1:
            // Menu icon coach mark - using the navigation bar button's view
            if let menuButton = navigationItem.leftBarButtonItem,
               let menuButtonView = menuButton.value(forKey: "view") as? UIView {
                coachMark = coachMarksController.helper.makeCoachMark(
                    for: menuButtonView,
                    cutoutPathMaker: { frame in
                        return UIBezierPath(roundedRect: frame.insetBy(dx: -8, dy: -8),
                                          byRoundingCorners: .allCorners,
                                          cornerRadii: CGSize(width: 8, height: 8))
                    }
                )
            }
        case 2:
            // Date scroller coach mark
            coachMark = coachMarksController.helper.makeCoachMark(
                for: dateScroller,
                cutoutPathMaker: { frame in
                    return UIBezierPath(roundedRect: frame.insetBy(dx: -8, dy: -8),
                                      byRoundingCorners: .allCorners,
                                      cornerRadii: CGSize(width: 8, height: 8))
                }
            )
        case 3:
            // Total label coach mark
            coachMark = coachMarksController.helper.makeCoachMark(
                for: totalLabel,
                cutoutPathMaker: { frame in
                    return UIBezierPath(roundedRect: frame.insetBy(dx: -8, dy: -8),
                                      byRoundingCorners: .allCorners,
                                      cornerRadii: CGSize(width: 8, height: 8))
                }
            )
        case 4:
            // Today's total label coach mark
            coachMark = coachMarksController.helper.makeCoachMark(
                for: expTodayTotal,
                cutoutPathMaker: { frame in
                    return UIBezierPath(roundedRect: frame.insetBy(dx: -8, dy: -8),
                                      byRoundingCorners: .allCorners,
                                      cornerRadii: CGSize(width: 8, height: 8))
                }
            )
        case 5:
            // Expense input coach mark
            coachMark = coachMarksController.helper.makeCoachMark(
                for: expTextField,
                cutoutPathMaker: { frame in
                    return UIBezierPath(roundedRect: frame.insetBy(dx: -8, dy: -8),
                                      byRoundingCorners: .allCorners,
                                      cornerRadii: CGSize(width: 8, height: 8))
                }
            )
        case 6:
            // Add expense button coach mark
            coachMark = coachMarksController.helper.makeCoachMark(
                for: addExpImageView,
                cutoutPathMaker: { frame in
                    return UIBezierPath(roundedRect: frame.insetBy(dx: -8, dy: -8),
                                      byRoundingCorners: .allCorners,
                                      cornerRadii: CGSize(width: 8, height: 8))
                }
            )
        case 7:
            // Expense item coach mark - highlight first visible cell
            if let firstCell = expTableView.visibleCells.first {
                coachMark = coachMarksController.helper.makeCoachMark(
                    for: firstCell,
                    cutoutPathMaker: { frame in
                        return UIBezierPath(roundedRect: frame.insetBy(dx: -4, dy: -4),
                                          byRoundingCorners: .allCorners,
                                          cornerRadii: CGSize(width: 8, height: 8))
                    }
                )
            } else {
                // Fallback to table view if no cells are visible
                coachMark = coachMarksController.helper.makeCoachMark(
                    for: expTableView,
                    cutoutPathMaker: { frame in
                        return UIBezierPath(roundedRect: frame.insetBy(dx: -8, dy: -8),
                                          byRoundingCorners: .allCorners,
                                          cornerRadii: CGSize(width: 8, height: 8))
                    }
                )
            }
        default:
            fatalError("Unexpected coach mark index: \(index)")
        }
        
        // Ensure the overlay remains interactive
        coachMark.isOverlayInteractionEnabled = true
        
        return coachMark
    }

    func coachMarksController(_ coachMarksController: CoachMarksController, coachMarkViewsAt index: Int, madeFrom coachMark: CoachMark) -> (bodyView: (UIView & CoachMarkBodyView), arrowView: (UIView & CoachMarkArrowView)?) {
        let coachViews = coachMarksController.helper.makeDefaultCoachViews(withArrow: true, arrowOrientation: coachMark.arrowOrientation)
        
        switch index {
        case 0:
            coachViews.bodyView.hintLabel.text = "Tap here to switch between different expense lists"
            coachViews.bodyView.nextLabel.text = "Next"
        case 1:
            coachViews.bodyView.hintLabel.text = "Tap menu to create new lists or manage existing ones"
            coachViews.bodyView.nextLabel.text = "Next"
        case 2:
            coachViews.bodyView.hintLabel.text = "Scroll through dates to view expenses for different days"
            coachViews.bodyView.nextLabel.text = "Next"
        case 3:
            coachViews.bodyView.hintLabel.text = "This shows the total amount for your selected list"
            coachViews.bodyView.nextLabel.text = "Next"
        case 4:
            coachViews.bodyView.hintLabel.text = "This shows today's total expenses for the selected date"
            coachViews.bodyView.nextLabel.text = "Next"
        case 5:
            coachViews.bodyView.hintLabel.text = "Describe your expenses like a note."
            coachViews.bodyView.nextLabel.text = "Next"
        case 6:
            coachViews.bodyView.hintLabel.text = "Tap + once done describing expense."
            coachViews.bodyView.nextLabel.text = "Next"
        case 7:
            coachViews.bodyView.hintLabel.text = "Tap any expense to edit or swipe to delete it"
            coachViews.bodyView.nextLabel.text = "Done"
        default:
            fatalError("Unexpected coach mark index: \(index)")
        }
        
        return (bodyView: coachViews.bodyView, arrowView: coachViews.arrowView)
    }

    func coachMarksController(_ coachMarksController: CoachMarksController, didEndShowingBySkipping skipped: Bool) {
        // Handle tour completion
        print("Tour completed. Skipped: \(skipped)")
        // Ensure we mark that user has seen the tour even if they skipped it
        UserDefaults.standard.set(true, forKey: hasSeenTourKey)
        
        // Show welcome message only if user completed the tour (not skipped)
        if !skipped {
            showWelcomeMessage()
        }
        
        // When user completes the guided tour
        AnalyticsManager.shared.trackTourCompleted()
        // When user skips the guided tour
        AnalyticsManager.shared.trackTourSkipped()
    }
    
    private func showWelcomeMessage() {
        // Show the welcome popup with animation
        showWelcomePopup()
    }
    
    private func showWelcomePopup() {
        // Create a custom popup view controller
        let popupVC = WelcomePopupViewController()
        popupVC.modalPresentationStyle = .overFullScreen
        popupVC.modalTransitionStyle = .crossDissolve
        present(popupVC, animated: true)
    }
}

// MARK: - Welcome Popup View Controller
class WelcomePopupViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupWelcomeAnimation()
    }
    
    private func setupWelcomeAnimation() {
        // Set up the background
        view.backgroundColor = UIColor.black.withAlphaComponent(0.8)
        
        // Create the main container
        let containerView = UIView()
        containerView.backgroundColor = .white
        containerView.layer.cornerRadius = 20
        containerView.clipsToBounds = true
        containerView.alpha = 0
        containerView.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        view.addSubview(containerView)
        
        // Create welcome text label
        let welcomeLabel = UILabel()
        welcomeLabel.text = "🎉 Welcome to Vyay! 🎉"
        welcomeLabel.font = UIFont.boldSystemFont(ofSize: 24)
        welcomeLabel.textColor = UIColor(rgb: 0x662CAA)
        welcomeLabel.textAlignment = .center
        welcomeLabel.alpha = 0
        welcomeLabel.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
        containerView.addSubview(welcomeLabel)
        
        // Create subtitle label
        let subtitleLabel = UILabel()
        subtitleLabel.text = "Your AI-powered expense tracker"
        subtitleLabel.font = UIFont.systemFont(ofSize: 16)
        subtitleLabel.textColor = .darkGray
        subtitleLabel.textAlignment = .center
        subtitleLabel.alpha = 0
        subtitleLabel.transform = CGAffineTransform(translationX: 0, y: 20)
        containerView.addSubview(subtitleLabel)
        
        // Create feature highlights
        let featuresStackView = UIStackView()
        featuresStackView.axis = .vertical
        featuresStackView.spacing = 12
        featuresStackView.alpha = 0
        featuresStackView.transform = CGAffineTransform(translationX: 0, y: 30)
        containerView.addSubview(featuresStackView)
        
        let features = [
            "✨ Natural language expense entry",
            "🤖 AI-powered categorization", 
            "📊 Smart expense tracking",
            "💡 Multiple expense lists"
        ]
        
        for feature in features {
            let featureLabel = UILabel()
            featureLabel.text = feature
            featureLabel.font = UIFont.systemFont(ofSize: 14)
            featureLabel.textColor = .darkGray
            featureLabel.textAlignment = .center
            featuresStackView.addArrangedSubview(featureLabel)
        }
        
        // Create start button
        let startButton = UIButton(type: .system)
        startButton.setTitle("Let's Start! 🚀", for: .normal)
        startButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        startButton.setTitleColor(.white, for: .normal)
        startButton.backgroundColor = UIColor(rgb: 0x662CAA)
        startButton.layer.cornerRadius = 20
        startButton.alpha = 0
        startButton.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        startButton.addTarget(self, action: #selector(startButtonTapped), for: .touchUpInside)
        containerView.addSubview(startButton)
        
        // Set up constraints
        containerView.translatesAutoresizingMaskIntoConstraints = false
        welcomeLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        featuresStackView.translatesAutoresizingMaskIntoConstraints = false
        startButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            // Container constraints
            containerView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            containerView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            containerView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.85),
            containerView.heightAnchor.constraint(equalToConstant: 400),
            
            // Welcome label constraints
            welcomeLabel.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            welcomeLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 30),
            
            // Subtitle label constraints
            subtitleLabel.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            subtitleLabel.topAnchor.constraint(equalTo: welcomeLabel.bottomAnchor, constant: 15),
            
            // Features stack view constraints
            featuresStackView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            featuresStackView.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 30),
            
            // Start button constraints
            startButton.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            startButton.topAnchor.constraint(equalTo: featuresStackView.bottomAnchor, constant: 40),
            startButton.widthAnchor.constraint(equalToConstant: 180),
            startButton.heightAnchor.constraint(equalToConstant: 45)
        ])
        
        // Animation sequence
        UIView.animate(withDuration: 0.4, delay: 0.1, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.5, options: [], animations: {
            containerView.alpha = 1
            containerView.transform = .identity
        }) { _ in
            // Animate welcome label
            UIView.animate(withDuration: 0.5, delay: 0.1, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.5, options: [], animations: {
                welcomeLabel.alpha = 1
                welcomeLabel.transform = .identity
            }) { _ in
                // Animate subtitle
                UIView.animate(withDuration: 0.4, delay: 0.1, options: [], animations: {
                    subtitleLabel.alpha = 1
                    subtitleLabel.transform = .identity
                }) { _ in
                    // Animate features
                    UIView.animate(withDuration: 0.5, delay: 0.1, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.3, options: [], animations: {
                        featuresStackView.alpha = 1
                        featuresStackView.transform = .identity
                    }) { _ in
                        // Animate start button
                        UIView.animate(withDuration: 0.4, delay: 0.2, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.5, options: [], animations: {
                            startButton.alpha = 1
                            startButton.transform = .identity
                        })
                    }
                }
            }
        }
    }
    
    @objc private func startButtonTapped() {
        // Add button press animation
        if let button = view.subviews.first?.subviews.last(where: { $0 is UIButton }) as? UIButton {
            UIView.animate(withDuration: 0.1, animations: {
                button.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
            }) { _ in
                UIView.animate(withDuration: 0.1) {
                    button.transform = .identity
                }
            }
        }
        
        // Dismiss the popup
        UIView.animate(withDuration: 0.3, animations: {
            self.view.alpha = 0
        }) { _ in
            self.dismiss(animated: false)
        }
    }
    
    // Allow dismissal by tapping outside
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            let location = touch.location(in: view)
            if let containerView = view.subviews.first,
               !containerView.frame.contains(location) {
                // Tapped outside the container, dismiss
                UIView.animate(withDuration: 0.3, animations: {
                    self.view.alpha = 0
                }) { _ in
                    self.dismiss(animated: false)
                }
            }
        }
    }
}

// MARK: - Dashboard Helper Functions
extension DashboardViewController {
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

    // When adding a new expense
    func trackExpenseAdded(amount: Double, category: String, list: String) {
        AnalyticsManager.shared.trackExpenseAdded(amount: amount, category: category, list: list)
    }

    // When editing an expense
    func trackExpenseEdited(oldAmount: Double, newAmount: Double, category: String, list: String) {
        AnalyticsManager.shared.trackExpenseEdited(oldAmount: oldAmount, newAmount: newAmount, category: category, list: list)
    }

    // When deleting an expense
    func trackExpenseDeleted(amount: Double, category: String, list: String) {
        AnalyticsManager.shared.trackExpenseDeleted(amount: amount, category: category, list: list)
    }
}

// MARK: - Date Picker Bottom Sheet Delegate
extension DashboardViewController: DatePickerBottomSheetDelegate {
    func didSelectDate(_ date: Date) {
        // Update the selected date
        let calendar = Calendar.current
        let normalizedDate = calendar.startOfDay(for: date)
        selectedDate = normalizedDate
        
        // Update the date label
        dateLabel.text = dateFormatter.string(from: normalizedDate)
        
        // Update the date scroller to show the selected date
        if let dateIndex = findDateIndex(normalizedDate) {
            let indexPath = IndexPath(item: dateIndex, section: 0)
            dateScroller.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
            dateScroller.reloadData()
        }
        
        // Update the day scroller to show the correct day of week
        let weekday = calendar.component(.weekday, from: normalizedDate)
        let dayIndex = weekday - 1
        if dayIndex >= 0 && dayIndex < 7 {
            let dayIndexPath = IndexPath(item: dayIndex, section: 0)
            dayScroller.scrollToItem(at: dayIndexPath, at: .centeredHorizontally, animated: true)
            dayScroller.reloadData()
        }
        
        // Fetch expenses for the new date
        fetchExpenses()
        
        // Track date change
        AnalyticsManager.shared.trackDateChanged(date: normalizedDate)
        
        print("Date changed to: \(dateFormatter.string(from: normalizedDate))")
    }
}

