//
//  AppDelegate.swift
//  La App
//
//  Created by MacBook Pro on 8/5/18.
//  Copyright © 2018 MacBook Pro. All rights reserved.
//

import UIKit
import CoreData

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

   var window: UIWindow?

   func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
      return true
   }

   func applicationWillTerminate(_ application: UIApplication) {
      self.saveContext()
   }

   // MARK: - Core Data stack

   lazy var persistentContainer: NSPersistentContainer = {
       let container = NSPersistentContainer(name: "La_App")
       container.loadPersistentStores(completionHandler: { (storeDescription, error) in
           if let error = error as NSError? {
               print("Unresolved error \(error), \(error.userInfo)")
           }
       })
       return container
   }()

   // MARK: - Core Data Saving support

   func saveContext () {
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
      return (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
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
   static func insert(with dict:[String: Any]? = nil) -> Self {
      let new = NSEntityDescription.insertNewObject(forEntityName: name, into: NSManagedObjectContext.shared)
      for (key, val) in dict ?? [:] {
         new.setValue(val, forKey: key)
      }
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
}

