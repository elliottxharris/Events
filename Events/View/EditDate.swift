//
//  EditDate.swift
//  Events
//
//  Created by Elliott Harris on 6/30/21.
//

import SwiftUI
import RealmSwift

final class EditDateViewController: UIHostingController<EditDate> {
    var updateTable: (() -> Void)?
    
    init(date: DateLabel, updateTable: @escaping (() -> Void)) {
        super.init(rootView: EditDate(date: date))
        rootView.dismiss = dismiss
        self.updateTable = updateTable
    }
    
    @objc required dynamic init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func dismiss() {
        updateTable!()
        dismiss(animated: true, completion: nil)
    }
}

struct EditDate: View {
    @ObservedRealmObject var date: DateLabel
    
    var dismiss: (() -> Void)?
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Details"), content: {
                    TextField("Event Name", text: $date.label)
                    DatePicker("Date", selection: $date.date, displayedComponents: [.date])
                })
            }
            .navigationBarItems(trailing: Button("Done", action: {
                dismiss!()
            }))
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
