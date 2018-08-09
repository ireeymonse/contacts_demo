//
//  ActiveContactsTests.swift
//  La AppTests
//
//  Created by MacBook Pro on 8/8/18.
//  Copyright © 2018 Iree García. All rights reserved.
//

import XCTest
@testable import La_App
import CoreData

class ActiveContactsTests: XCTestCase {
   
   var appDelegate: AppDelegate {
      return UIApplication.shared.delegate as! AppDelegate
   }
   var contactsViewController: ActiveContactsViewController!
   
   override func setUp() {
      super.setUp()
      
      // mock core data
      let container = NSPersistentContainer(name: "La_App")
      
      let description = NSPersistentStoreDescription()
      description.type = NSInMemoryStoreType    // resets on every test
      description.shouldAddStoreAsynchronously = false
      container.persistentStoreDescriptions = [description]
      
      container.loadPersistentStores { (description, error) in
         XCTAssert(description.type == NSInMemoryStoreType, "Data store is not in-memory")
         XCTAssertNil(error, "Error creation in-memory data store: \(error!)")
      }
      appDelegate.persistentContainer = container
      appDelegate.reloadActiveUsers()
      
      // recreate controller stack
      
      let nav = UIStoryboard(name: "Main", bundle: .main).instantiateInitialViewController() as! UINavigationController
      UIApplication.shared.keyWindow!.rootViewController = nav
      XCTAssertNotNil(nav.view)
      
      contactsViewController = nav.topViewController as? ActiveContactsViewController
      XCTAssertNotNil(contactsViewController?.view, "Lead capture not presented")
   }
   
   override func tearDown() {
      super.tearDown()
   }
   
   func testAllContactsInactiveByDefault() {
      // create expectation over async method to be finished with a notification
      expectation(forNotification: .ContactsLoaded, object: nil) { (notif) -> Bool in
         
         let actives = try? LocalContact.matching("userId <> NULL")
         XCTAssertNil(actives?.first, "No active contacts should be in the data store")
         XCTAssertNil(self.contactsViewController.contacts[""], "View controller should not be displaying any active contacts")
         return true
      }
      waitForExpectations(timeout: 10)
   }
   
   func testFindActiveContacts() {
      // add test data
      _ = ActiveUser.insert(with: ["id": "5518728874"])
      
      let me = LocalContact.insert(with:
         ["name": "IREE GARCIA", "initials": "IG", "numbers": ["+52 1 5518728874", "1234567890"]])
      _ = LocalContact.insert(with:
         ["name": "USER", "initials": "U", "numbers": ["0987654321"]])
      
      // trigger a contact reload
      appDelegate.reloadActiveUsers()
      
      // tests
      XCTAssertEqual(appDelegate.activeUsers.count, 1, "Active user not reflected in AppDelegate")
      
      let active = try! LocalContact.matching("userId <> NULL").first
      XCTAssertNotNil(active, "One active contact should be in the data store")
      XCTAssertEqual(active?.name, "IREE GARCIA", "Incorrect contact matched as active")
      
      XCTAssertEqual(contactsViewController.contacts[""]?.first, active,
                     "View controller should be displaying one active contact")
      XCTAssertEqual(me.userId, me.numbers?.first, "Active contact's userId not set correctly")
   }
   
   func testActiveUsersChange() {
      // initial setup
      testFindActiveContacts()
      
      // modify active users
      ActiveUser.all().first?.id = "0987654321" // "USER"
      appDelegate.reloadActiveUsers()
      
      // tests
      let active = try! LocalContact.matching("userId <> NULL").first
      XCTAssertNotNil(active, "One active contact should be present")
      XCTAssertEqual(active?.name, "USER", "Incorrect contact matched as active")
   }
   
   func testLocalContactsChange() {
      // initial setup
      testFindActiveContacts()
      
      // modify local contacts
      let me = try! LocalContact.matching("name = %@", "IREE GARCIA").first!
      me.numbers = []
      NotificationCenter.default.post(name: .ActiveUsersDidChange, object: nil)
      
      // tests
      let actives = try? LocalContact.matching("userId <> NULL")
      XCTAssertNil(actives?.first, "No active contacts should be in the data store")
      XCTAssertNil(contactsViewController.contacts[""], "View controller should not be displaying any active contacts")
      XCTAssertNil(me.userId, "Active contact's userId should be nil")
   }
}
