//
//  AppDelegate.swift
//  La App
//
//  Created by MacBook Pro on 8/5/18.
//  Copyright © 2018 MacBook Pro. All rights reserved.
//

import UIKit
import CoreData

extension NSNotification.Name {
   public static let ActiveUsersDidChange = Notification.Name("notif:userChanged!")
}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
   
   private(set) static var shared = UIApplication.shared.delegate as! AppDelegate
   var window: UIWindow?

   func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
      
      reloadActiveUsers(notifying: false)
      return true
   }

   func applicationWillTerminate(_ application: UIApplication) {
      saveContext()
   }
   
   
   // MARK: - Active users
   
   /// userIds are phone numbers, normalized to 10 digits
   private(set) var activeUsers: Set<ActiveUserId> = []
   
   private func reloadActiveUsers(notifying: Bool) {
      activeUsers = Set(ActiveUser.all().compactMap { $0.id })
      if notifying {
         NotificationCenter.default.post(name: .ActiveUsersDidChange, object: nil)
      }
   }
   
   func reloadActiveUsers() { reloadActiveUsers(notifying: true) }

   
   // MARK: - Core Data stack

   lazy var persistentContainer: NSPersistentContainer = {
       let container = NSPersistentContainer(name: "La_App")
       container.loadPersistentStores { (_, error) in
           if let error = error as NSError? {
               print("NSPersistentContainer error \(error), \(error.userInfo)")
           }
       }
       return container
   }()

   // MARK: - Core Data Saving support

   func saveContext() {
       let context = persistentContainer.viewContext
       if context.hasChanges {
           do {
               try context.save()
           } catch {
               let nserror = error as NSError
               print("Unresolved error \(nserror), \(nserror.userInfo)")
           }
       }
   }

}


// MARK: - Core Data extensions

extension NSManagedObjectContext {
   static var shared: NSManagedObjectContext {
      return AppDelegate.shared.persistentContainer.viewContext
   }
}

extension NSObjectProtocol {
   /// The name of the current class
   static var name: String { return String(describing: self) }
}

extension NSFetchRequestResult where Self: NSManagedObject {
   
   // MARK: - Manipulation
   
   /// Inserts a new NSManagedObject subclass instance in the shared context.
   /// *WARNING: don't call this on `NSManagedObject` directly
   static func insert() -> Self {
      let new = NSEntityDescription.insertNewObject(forEntityName: name, into: NSManagedObjectContext.shared)
      return new as! Self
   }
   
   // MARK: - Fetching
   
   static func matching(_ predicate: NSPredicate, sorted: [NSSortDescriptor]? = nil) throws -> [Self] {
      let request = NSFetchRequest<Self>(entityName: name)
      request.predicate = predicate
      request.sortDescriptors = sorted
      return try NSManagedObjectContext.shared.fetch(request)
   }
   
   static func matching(_ predicateFormat: String, _ args: CVarArg..., sorted: [NSSortDescriptor]? = nil) throws -> [Self] {
      return try matching(NSPredicate(format: predicateFormat, argumentArray: args), sorted: sorted)
   }
   
   /// Fetches all instances of an NSManagedObject subclass. *WARNING: don't call this on `NSManagedObject` directly
   static func all(sorted:[NSSortDescriptor]? = nil) -> [Self] {
      let request = NSFetchRequest<Self>(entityName: name)
      request.sortDescriptors = sorted
      return try! NSManagedObjectContext.shared.fetch(request)
   }
   
   static func deleteAll() throws {
      let context = NSManagedObjectContext.shared
      let request = NSFetchRequest<Self>(entityName: name)
      request.includesPropertyValues = false
      
      try context.fetch(request).forEach {
         context.delete($0)
      }
      try context.save()
   }
}

