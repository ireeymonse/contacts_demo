//
//  ActiveContactsViewController.swift
//  La App
//
//  Created by MacBook Pro on 8/7/18.
//  Copyright © 2018 Iree García. All rights reserved.
//

import UIKit
import Contacts
import CoreData

class ActiveContactsViewController: UIViewController {
   
   @IBOutlet weak var tableView: UITableView!
   
   internal var sections = [String]()
   internal var contacts = [String: [LocalContact]]()
   
   override func viewDidLoad() {
      super.viewDidLoad()
      fetchContacts()
      
      NotificationCenter.default.addObserver(self, selector:
         #selector(contactsNeedReload(_:)), name: .ActiveUsersDidChange, object: nil)
      NotificationCenter.default.addObserver(self, selector:
         #selector(contactsNeedReload(_:)), name: .CNContactStoreDidChange, object: nil)
   }
   
   @objc func contactsNeedReload(_ notif: Notification) {
      if notif.name == .CNContactStoreDidChange {
         fetchContacts()
      } else {
         reloadContacts()
      }
   }
   
   deinit {
      NotificationCenter.default.removeObserver(self)
   }
   
   // MARK: - Data
   
   internal func fetchContacts() {
      let contactStore = CNContactStore()
      contactStore.requestAccess(for: .contacts) { [weak self] (success, error) in
         
         // handle failure
         guard success, error == nil else {
            DispatchQueue.main.async {
               
               let alert = UIAlertController(title: nil, message:
                  "La App no tiene acceso a tus contactos.", preferredStyle: .alert)
               
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
         let keys = [CNContactGivenNameKey, CNContactMiddleNameKey, CNContactFamilyNameKey,
                     CNContactPhoneNumbersKey] as [CNKeyDescriptor]
         
         var results = [ContactResult]()
         try? contactStore.enumerateContacts(with: CNContactFetchRequest(keysToFetch: keys)) { (contact, _) in
            
            let new = ContactResult()
            
            // retrieve full name and phone numbers
            new.name = [contact.givenName, contact.middleName, contact.familyName]
               .filter { !$0.isEmpty }.joined(separator: " ")
            new.initials = String([contact.givenName.first, contact.familyName.first].compactMap { $0 })
            new.numbers = contact.phoneNumbers.map { $0.value.stringValue }
            
            results.append(new)
         }
         
         // display results
         DispatchQueue.main.async {
            // update records
            try? LocalContact.deleteAll() // brute force: delete all and write again
            
            results.forEach {
               let local = LocalContact.insert()
               local.name = $0.name
               local.initials = $0.initials
               local.numbers = $0.numbers
            }
            try? NSManagedObjectContext.shared.save()
            
            self?.reloadContacts()
         }
      }
   }
   
   internal func reloadContacts() {
      // separate alphabetically
      let byIdAndName = [
         NSSortDescriptor(key: "userId", ascending: true),
         NSSortDescriptor(key: "name", ascending: true, selector: #selector(NSString.localizedStandardCompare(_:)))]
      
      contacts = [String: [LocalContact]]()
      let actives = AppDelegate.shared.activeUsers
      
      LocalContact.all(sorted: byIdAndName).forEach {
         // look for a phone number that corresponds to an active user
         $0.userId = $0.numbers?.first {
            actives.contains(ActiveUser.userId(from: $0)) }
         
         var key = String($0.name?.uppercased().first ?? "#")
         if $0.userId != nil {   // active users go in the first section
            key = ""
         }
         contacts[key] = contacts[key] ?? [LocalContact]()
         contacts[key]!.append($0)
      }
      
      sections = contacts.keys.sorted()
      tableView.reloadData()
   }
   
   @IBAction func unwindToHome(_ segue: UIStoryboardSegue) {}
}


// MARK: -

extension ActiveContactsViewController: UITableViewDataSource, UITableViewDelegate {
   
   func numberOfSections(in tableView: UITableView) -> Int {
      return sections.count
   }
   
   func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
      return contacts[sections[section]]!.count
   }
   
   func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
      
      let key = sections[indexPath.section]
      let contact = contacts[key]![indexPath.row]
      
      let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! ContactCell
      
      cell.titleLabel.text = contact.name
      if contact.name == nil || contact.name!.isEmpty {
         cell.titleLabel.text = "(Sin Nombre)"
      }
      cell.subtitleLabel.text = contact.userId
      
      // TODO: cell.iconView.image = ...
      cell.iconView?.backgroundColor = (contact.userId ?? "").isEmpty ? #colorLiteral(red: 0.7058823529, green: 0.7058823529, blue: 0.7058823529, alpha: 1) : #colorLiteral(red: 0.1875, green: 0.740625, blue: 0.75, alpha: 1)
      
      cell.initialsLabel?.text = contact.initials
      if contact.initials == nil || contact.initials!.isEmpty {
         cell.initialsLabel?.text = ":D"
      }
      
      return cell
   }
   
   func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
      // TODO: finish
      performSegue(withIdentifier: "detail", sender: nil)
   }
   
   func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
      // no header for active contacts
      return sections[section].isEmpty ? 0 : 32
   }
   
   func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
      let hdr = tableView.dequeueReusableCell(withIdentifier: "header") as! ContactHeader
      hdr.titleLabel.text = sections[section]
      return hdr.contentView
   }
}


// MARK: -

class ContactHeader: UITableViewCell {
   @IBOutlet weak var titleLabel: UILabel!
}

class ContactCell: UITableViewCell {
   @IBOutlet weak var titleLabel: UILabel!
   @IBOutlet weak var subtitleLabel: UILabel!
   
   @IBOutlet weak var iconView: UIImageView?
   @IBOutlet weak var initialsLabel: UILabel?
}


// FIXME: relocate

class ContactResult: NSObject {
   var name: String!
   var initials: String!
   var numbers: [String]!
}


