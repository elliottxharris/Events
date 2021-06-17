//
//  Contact.swift
//  Events
//
//  Created by Elliott Harris on 6/5/21.
//

import Foundation
import RealmSwift

class DateLabel: Object {
    @objc dynamic var label: String = ""
    @objc dynamic var date: Date = Date()
    @objc dynamic var isNotified: Bool = false
}

class Contact: Object {
    @objc dynamic var name: String = ""
    @objc dynamic var phone: String? = nil
    let dates = List<DateLabel>()
}
