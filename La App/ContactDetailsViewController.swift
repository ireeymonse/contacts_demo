//
//  ContactDetailsViewController.swift
//  La App
//
//  Created by MacBook Pro on 8/8/18.
//  Copyright © 2018 Iree García. All rights reserved.
//

import UIKit

class ContactDetailsViewController: UIViewController {
   
   @IBOutlet weak var numberLabel: UILabel!
   @IBOutlet weak var nameLabel: UILabel!
   
   var contact: LocalContact!
   
   override func viewDidLoad() {
      super.viewDidLoad()
      
      navigationItem.title = contact.name
      numberLabel.text = contact.userId
      nameLabel.text = contact.name
   }
}
