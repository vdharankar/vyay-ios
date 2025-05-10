//
//  ExpenseItem.swift
//  vyay
//
//  Created by Vishal Dharankar on 26/07/24.
//

import Foundation

class ExpenseItem {
    var title : String!
    var amount : Int!
    var date : Date!
    var category : String!
    
    init(title: String!, amount: Int!, date: Date!, category: String!) {
        self.title = title
        self.amount = amount
        self.date = date
        self.category = category
    }
    init(){ }
}
