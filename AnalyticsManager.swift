import Foundation
import FirebaseAnalytics

class AnalyticsManager {
    static let shared = AnalyticsManager()
    
    private init() {}
    
    // MARK: - Screen Tracking
    func trackScreen(_ screenName: String, screenClass: String) {
        Analytics.logEvent(AnalyticsEventScreenView,
                         parameters: [
                            AnalyticsParameterScreenName: screenName,
                            AnalyticsParameterScreenClass: screenClass
                         ])
    }
    
    // MARK: - Expense Events
    func trackExpenseAdded(amount: Double, category: String, list: String) {
        Analytics.logEvent("expense_added", parameters: [
            "amount": amount,
            "category": category,
            "list": list
        ])
    }
    
    func trackExpenseDeleted(amount: Double, category: String, list: String) {
        Analytics.logEvent("expense_deleted", parameters: [
            "amount": amount,
            "category": category,
            "list": list
        ])
    }
    
    func trackExpenseEdited(oldAmount: Double, newAmount: Double, category: String, list: String) {
        Analytics.logEvent("expense_edited", parameters: [
            "old_amount": oldAmount,
            "new_amount": newAmount,
            "category": category,
            "list": list
        ])
    }
    
    // MARK: - List Events
    func trackListCreated(listName: String) {
        Analytics.logEvent("list_created", parameters: [
            "list_name": listName
        ])
    }
    
    func trackListDeleted(listName: String) {
        Analytics.logEvent("list_deleted", parameters: [
            "list_name": listName
        ])
    }
    
    // MARK: - User Actions
    func trackTourCompleted() {
        Analytics.logEvent("tour_completed", parameters: nil)
    }
    
    func trackTourSkipped() {
        Analytics.logEvent("tour_skipped", parameters: nil)
    }
    
    func trackDateChanged(date: Date) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        Analytics.logEvent("date_changed", parameters: [
            "selected_date": dateFormatter.string(from: date)
        ])
    }
    
    func trackListSwitched(fromList: String, toList: String) {
        Analytics.logEvent("list_switched", parameters: [
            "from_list": fromList,
            "to_list": toList
        ])
    }
    
    // MARK: - AI Features
    func trackAIExpenseProcessed(success: Bool, inputText: String) {
        Analytics.logEvent("ai_expense_processed", parameters: [
            "success": success,
            "input_length": inputText.count
        ])
    }
} 