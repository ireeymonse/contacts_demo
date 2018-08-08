//
//  ActiveUserCreationViewController.swift
//  La App
//
//  Created by MacBook Pro on 8/8/18.
//  Copyright © 2018 Iree García. All rights reserved.
//

import UIKit
import CoreData

// TODO: add a way to delete an active user?
class ActiveUserCreationViewController: ActiveContactsViewController {
   
   @IBOutlet weak var textField: UITextField!
   @IBOutlet weak var editionResultLabel: UILabel!
   @IBOutlet weak var saveButton: UIBarButtonItem!
   
   /// Reflects only those numbers of a contact that can be used as an userId
   private var validNumbers = [LocalContact: [String]]()
   fileprivate var result: String?
   
   override func fetchContacts() {
      reloadContacts()
   }
   
   override func reloadContacts() {
      // separate alphabetically
      let byName = [NSSortDescriptor(key: "name", ascending: true, selector: #selector(NSString.localizedStandardCompare(_:)))]
      
      guard let inactive = try? LocalContact.matching("userId = NULL", sorted: byName) else {
         return
      }
      
      contacts = [String: [LocalContact]]()
      inactive.forEach {
         let key = String($0.name?.uppercased().first ?? "#")
         contacts[key] = contacts[key] ?? [LocalContact]()
         contacts[key]!.append($0)
         
         // filter possible userIds in numbers
         validNumbers[$0] = $0.numbers?.compactMap {
            ActiveUser.userId(from: $0).count == 10 ? $0 : nil
         }
      }
      
      sections = contacts.keys.sorted()
      tableView.reloadData()
   }
   
   override func contactsNeedReload(_ notif: Notification) {}
   
   fileprivate func input(_ text: String) {
      result = ActiveUser.userId(from: text)
      editionResultLabel.text = "= \(result ?? "")"
      saveButton.isEnabled = result?.count == 10
   }
   
   @IBAction func save(_ sender: Any) {
      guard let result = result, result.count == 10 else {
         return
      }
      
      let user = ActiveUser.insert()
      user.id = result
      try? NSManagedObjectContext.shared.save()
      
      AppDelegate.shared.reloadActiveUsers()

      performSegue(withIdentifier: "unwind", sender: nil)
   }
   
   
   // MARK: -
   
   internal func validNumbersForContact(at indexPath: IndexPath) -> [String] {
      let key = sections[indexPath.section]
      let contact = contacts[key]![indexPath.row]
      return validNumbers[contact] ?? []
   }
   
   override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
      let cell = super.tableView(tableView, cellForRowAt: indexPath) as! ContactSuggestionCell
      
      let nums = validNumbersForContact(at: indexPath)
      cell.subtitleLabel.text = nums.joined(separator: ", ")
      cell.availabilityIndicator.isHidden = nums.isEmpty
      
      return cell
   }
   
   func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
      return validNumbersForContact(at: indexPath).count > 0
   }
   
   func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
      return validNumbersForContact(at: indexPath).count > 0 ? indexPath: nil
   }
   
   override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
      if let number = validNumbersForContact(at: indexPath).first {
         textField.text = number
         input(number)
      }
   }
}

// MARK: -

extension ActiveUserCreationViewController: UITextFieldDelegate {
   
   func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
      
      input((textField.text! as NSString).replacingCharacters(in: range, with: string))
      return true
   }
   
   func textFieldShouldReturn(_ textField: UITextField) -> Bool {
      textField.resignFirstResponder()
      return false
   }
}

// MARK: -

class ContactSuggestionCell: ContactCell {
   @IBOutlet weak var availabilityIndicator: UIView!
}
