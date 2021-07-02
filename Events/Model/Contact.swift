//
//  Contact.swift
//  Events
//
//  Created by Elliott Harris on 6/5/21.
//

import SwiftUI
import RealmSwift

class DateLabel: Object, ObjectKeyIdentifiable {
    @objc dynamic var label: String = ""
    @objc dynamic var date: Date = Date()
    @objc dynamic var isNotified: Bool = false
}

class Contact: Object {
    @objc dynamic var name: String = ""
    @objc dynamic var phone: String? = nil
    let dates = RealmSwift.List<DateLabel>()
}
