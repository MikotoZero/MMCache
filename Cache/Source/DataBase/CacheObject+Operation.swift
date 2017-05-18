//
//  CacheObject+Operation.swift
//  Cache
//
//  Created by 丁帅 on 2017/3/23.
//  Copyright © 2017年 丁帅. All rights reserved.
//  This file was automatically generated and should not be edited.
//

import Foundation
import CoreData

private class CacheDBContext {
    
    static var context: NSManagedObjectContext = {
        let context = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        context.mergePolicy = NSMergePolicy(merge: .mergeByPropertyStoreTrumpMergePolicyType)
        context.persistentStoreCoordinator = CacheDBContext.persistentStoreCoordinator
        return context
    }()
    
    static var persistentStoreCoordinator: NSPersistentStoreCoordinator = {
        guard
            let modelURL = Bundle.main.url(forResource: "Cache", withExtension: "momd"),
            let model = NSManagedObjectModel(contentsOf: modelURL)
            else {
                fatalError("MMCache.DiskCache.CoreData Error: Load DB cache file fail.")
        }
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: model)
        do {
            let storeURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).last?.appendingPathComponent("store.sqlite")
            let options = [
                NSMigratePersistentStoresAutomaticallyOption: true,
                NSInferMappingModelAutomaticallyOption: true
            ]
            try coordinator.addPersistentStore(ofType: NSSQLiteStoreType,
                                           configurationName: nil,
                                           at: storeURL,
                                           options: options)
        } catch {
            fatalError("MMCache.DiskCache.CoreData Error: NSPersistentStoreCoordinator addPersistentStore fail. Error: \(error)")
        }
        return coordinator
    }()
    
    static var entity: NSEntityDescription {
        guard let entityDesc = NSEntityDescription.entity(forEntityName: "CacheObject", in: CacheDBContext.context) else {
            fatalError("NSEntityDescription init fail")
        }
        return entityDesc
    }
}

private extension CacheDBContext {

    static func saveContext () {
        guard context.hasChanges  else { return }
        do {
            try context.save()
        } catch {
            fatalError("MMCache.DiskCache.CoreData Error: Save DB object fail. Error: \(error)")
        }
    }
}

internal extension CacheObject {
    
    class func insert() -> CacheObject {
        let objc = CacheObject(entity: CacheDBContext.entity, insertInto: CacheDBContext.context)
        return objc
    }
    
    @nonobjc class func get(with key: String) -> CacheObject? {
        return get(with: NSPredicate(format: "key == %@", key)).first
    }
    
    @nonobjc class func get(with predicate: NSPredicate? = nil) -> [CacheObject] {
        let fetch = NSFetchRequest<CacheObject>(entityName: "CacheObject")
        fetch.entity = CacheDBContext.entity
        fetch.predicate = predicate
        do {
            let result = try CacheDBContext.context.fetch(fetch)
            return result
        } catch {
            return []
        }
    }
    
    @nonobjc  @discardableResult class func remove(with key: String) -> CacheObject? {
        guard let objc = get(with: NSPredicate(format: "key == %@", key)).first else { return nil }
        CacheDBContext.context.delete(objc)
        return objc
    }
    
    @nonobjc class func remove(_ objc: CacheObject) {
        CacheDBContext.context.delete(objc)
    }

    
    class func rollback() {
        CacheDBContext.context.rollback()
    }
    
    class func save() {
        CacheDBContext.saveContext()
    }
}
