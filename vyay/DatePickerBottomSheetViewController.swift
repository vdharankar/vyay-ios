import UIKit
import FSCalendar

protocol DatePickerBottomSheetDelegate: AnyObject {
    func didSelectDate(_ date: Date)
}

class DatePickerBottomSheetViewController: UIViewController {
    
    @IBOutlet weak var calendar: FSCalendar!
    @IBOutlet weak var doneButton: UIButton!
    
    weak var delegate: DatePickerBottomSheetDelegate?
    var initialDate: Date?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private func setupUI() {
        // Setup calendar
        calendar.delegate = self
        calendar.dataSource = self
        
        // Calendar appearance
        calendar.appearance.headerTitleColor = UIColor(rgb: 0x662CAA)
        calendar.appearance.weekdayTextColor = UIColor(rgb: 0x662CAA)
        calendar.appearance.todayColor = UIColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1.0)
        calendar.appearance.todaySelectionColor = UIColor(rgb: 0x662CAA)
        calendar.appearance.selectionColor = UIColor(rgb: 0x662CAA)
        calendar.appearance.eventDefaultColor = UIColor(rgb: 0x662CAA)
        calendar.appearance.eventSelectionColor = UIColor(rgb: 0x662CAA)
        
        // Select initial date if available
        if let date = initialDate {
            calendar.select(date)
        }
        
    }
    
    @IBAction func doneButtonTapped(_ sender: Any) {
        if let selectedDate = calendar.selectedDate {
            delegate?.didSelectDate(selectedDate)
        }
        dismiss(animated: true)
    }
}

// MARK: - FSCalendarDelegate, FSCalendarDataSource
extension DatePickerBottomSheetViewController: FSCalendarDelegate, FSCalendarDataSource {
    func calendar(_ calendar: FSCalendar, didSelect date: Date, at monthPosition: FSCalendarMonthPosition) {
        // Date selected
    }
    
    func calendar(_ calendar: FSCalendar, shouldSelect date: Date, at monthPosition: FSCalendarMonthPosition) -> Bool {
        return true
    }
} 
