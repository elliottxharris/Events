//
//  ViewController.swift
//  Events
//
//  Created by Elliott Harris on 6/3/21.
//

import UIKit
import ContactsUI

class ViewController: UIViewController, CNContactPickerDelegate, UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return addedContects.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ContactCell", for: indexPath)
        let contact = addedContects[indexPath.row]
        let name = [contact.namePrefix, contact.givenName, contact.middleName, contact.familyName, contact.nameSuffix].filter({ $0 != "" }).joined(separator: " ")
        cell.textLabel?.text = name
        
        return cell
    }
    
    var contactStore = CNContactStore()
    var addedContects: [CNContact] = []
    
    @IBOutlet weak var tableView: UITableView!
    @IBAction func addButtonPressed(_ sender: Any) {
        let contactPickerViewController = CNContactPickerViewController()
        
        contactPickerViewController.delegate = self
        
        present(contactPickerViewController, animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationController?.navigationBar.prefersLargeTitles = true
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    func contactPicker(_ picker: CNContactPickerViewController, didSelect contact: CNContact) {
        addedContects.append(contact)
        tableView.beginUpdates()
        let indexPath = IndexPath(row: addedContects.count - 1, section: 0)
        tableView.insertRows(at: [indexPath], with: UITableView.RowAnimation.bottom)
        tableView.endUpdates()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let contactVC = segue.destination as? EventsViewController, let selectedIndex = tableView.indexPathForSelectedRow?.row else {
            return
        }
        
        contactVC.contact = addedContects[selectedIndex]
    }
}

