//
//  ActiveContactsViewController.swift
//  La App
//
//  Created by MacBook Pro on 8/7/18.
//  Copyright © 2018 Iree García. All rights reserved.
//

import UIKit
import Contacts

class ActiveContactsViewController: UIViewController {
   
   @IBOutlet weak var tableView: UITableView!
   
   private var contacts = [LocalContact]()
   
   override func viewDidLoad() {
      super.viewDidLoad()
      fetchContacts()
   }
   
   private func fetchContacts() {
      let contactStore = CNContactStore()
      contactStore.requestAccess(for: .contacts) { [weak self] (success, error) in
         
         // handle failure
         guard success, error == nil else {
            DispatchQueue.main.async {

               let alert = UIAlertController(title: nil, message: "La App no tiene acceso a tus contactos.", preferredStyle: .alert)
               
               alert.addAction(UIAlertAction(title: "Configuración", style: .default) { _ in
                  // open app settings
                  if let settings = URL(string: UIApplicationOpenSettingsURLString) {
                     UIApplication.shared.open(settings, options: [:])
                  }
               })
               alert.addAction(UIAlertAction(title: "Cancelar", style: .cancel))
               
               self?.present(alert, animated: true)
            }
            return
         }
         
         // get contacts
         let keys = [CNContactGivenNameKey, CNContactMiddleNameKey, CNContactFamilyNameKey, CNContactPhoneNumbersKey] as [CNKeyDescriptor]
         
         var results = [(name: String, numbers: [String])]()
         try? contactStore.enumerateContacts(with: CNContactFetchRequest(keysToFetch: keys)) { (contact, _) in
            
            // retrieve full name and phone numbers
            let name = [contact.givenName, contact.middleName, contact.familyName]
               .filter { !$0.isEmpty }.joined(separator: " ")
            let numbers = contact.phoneNumbers.map { $0.value.stringValue }

            results.append((name, numbers))
         }
         
         // display results
         DispatchQueue.main.async {
            // FIXME: duplicates contacts each time
            results.forEach {
               let local = LocalContact.insert()
               local.name = $0.name
               local.numbers = $0.numbers
               try? local.managedObjectContext?.save()
            }
            
            // TODO: separate alphabetically
            self?.contacts = LocalContact.all()
            self?.tableView.reloadData()
         }
      }
   }
   
   override func didReceiveMemoryWarning() {
      super.didReceiveMemoryWarning()
   }
   
   @IBAction func unwindToHome(_ segue: UIStoryboardSegue) {}
}


// MARK: -

extension ActiveContactsViewController: UITableViewDataSource, UITableViewDelegate {
   
   func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
      return contacts.count
   }
   
   func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
      
      // FIXME: custom cell class
      let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
      let contact = contacts[indexPath.row]
      cell.textLabel?.text = contact.name
      cell.detailTextLabel?.text = contact.numbers?.first
      
      return cell
   }
   
   func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
      // TODO: finish
      performSegue(withIdentifier: "detail", sender: nil)
   }
}


// MARK: -

class ContactHeader: UITableViewCell {
   @IBOutlet weak var titleLabel: UILabel!
}

class ContactCell: UITableViewCell {
   @IBOutlet weak var titleLabel: UILabel!
   @IBOutlet weak var subtitleLabel: UILabel!
   
   @IBOutlet weak var iconView: UIImageView!
   @IBOutlet weak var initialsLabel: UILabel!
}


