//
//  ExpenseItemCellTableViewCell.swift
//  vyay
//
//  Created by Vishal Dharankar on 26/07/24.
//

import UIKit

class ExpenseItemCell: UITableViewCell {

    @IBOutlet var labelTitle : UILabel!
    @IBOutlet var labelCategory : UILabel!
    @IBOutlet var labelAmount : UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    func configure(with expense: Expense, currencySymbol: String) {
        labelTitle.text = expense.details ?? ""
        labelCategory.text = "" // Set category if needed
        if let amount = expense.amount {
            labelAmount.text = String(format: "%@%.2f", currencySymbol, amount.doubleValue)
        } else {
            labelAmount.text = ""
        }
    }

}
