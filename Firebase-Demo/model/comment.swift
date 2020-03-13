//
//  comment.swift
//  Firebase-Demo
//
//  Created by Pursuit on 3/11/20.
//  Copyright © 2020 Alex Paul. All rights reserved.
//

import Foundation
import Firebase

struct Comment {
    // if these arent spelled right from where we created the post thingy then it didnt workb
    let commentDate: Timestamp
    let commentedBy: String
    let itemId: String
    let itemName: String
    let sellerName: String
    let text: String
}

extension Comment{
    // we use this initializer when converting a snapshot firebase data object to our swift model (comment)
    init(_ dictionary: [String: Any]) {
        self.commentDate = dictionary["commentDate"] as? Timestamp ?? Timestamp(date: Date())
        self.commentedBy = dictionary["commentedBy"] as? String ?? "no commentedBy name"
        self.itemId = dictionary["itemID"] as? String ?? "no item id"
        self.itemName = dictionary["itemName"] as? String ?? "no item"
        self.sellerName = dictionary["sellerName"] as? String ?? "no seller name"
        self.text = dictionary["text"] as? String ?? "no text "
    }
}
