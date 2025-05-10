//
//  MenuItemCell.swift
//  vyay
//
//  Created by Vishal Dharankar on 15/06/24.
//

import UIKit

class MenuItemCell: UITableViewCell {

    @IBOutlet var menuTitle : UILabel!
    @IBOutlet var menuSubtitle : UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
