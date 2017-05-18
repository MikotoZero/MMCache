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
        addPersistentStore(coordinator)
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
    
    static func addPersistentStore(_ coordinator: NSPersistentStoreCoordinator) {
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
    }
    
    static func cleanPersistentStore() {
        guard let storeURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).last?.appendingPathComponent("store.sqlite") else {
            fatalError("MMCache.DiskCache.CoreData Error: NSPersistentStoreCoordinator get persistentStore path fail.")
        }
        guard let store = persistentStoreCoordinator.persistentStore(for: storeURL) else { return }
        try? persistentStoreCoordinator.remove(store)
        try? FileManager.default.removeItem(at: storeURL)
        addPersistentStore(persistentStoreCoordinator)
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
        objc_sync_enter(CacheDBContext.context)
        let objc = CacheObject(entity: CacheDBContext.entity, insertInto: CacheDBContext.context)
        objc_sync_exit(CacheDBContext.context)
        return objc
    }
    
    @nonobjc class func get(with key: String, identifer: String) -> CacheObject? {
        objc_sync_enter(CacheDBContext.context)
        let objc = get(with: NSPredicate(format: "key = %@ AND cache_identifer = %@", key, identifer)).first
        objc_sync_exit(CacheDBContext.context)
        return objc
    }
    
    @nonobjc class func get(with predicate: NSPredicate? = nil) -> [CacheObject] {
        objc_sync_enter(CacheDBContext.context)
        let fetch = NSFetchRequest<CacheObject>(entityName: "CacheObject")
        fetch.entity = CacheDBContext.entity
        fetch.predicate = predicate
        let result: [CacheObject]
        do {
            result = try CacheDBContext.context.fetch(fetch)
        } catch {
            result = []
        }
        objc_sync_exit(CacheDBContext.context)
        return result
    }
    
    @discardableResult class func remove(with key: String) -> CacheObject? {
        objc_sync_enter(CacheDBContext.context)
        guard let objc = get(with: NSPredicate(format: "key == %@", key)).first else {
            objc_sync_exit(CacheDBContext.context)
            return nil
        }
        CacheDBContext.context.delete(objc)
        objc_sync_exit(CacheDBContext.context)
        return objc
    }
    
    class func remove(_ objc: CacheObject) {
        objc_sync_enter(CacheDBContext.context)
        CacheDBContext.context.delete(objc)
        objc_sync_exit(CacheDBContext.context)
    }
    
    class func clean() {
        objc_sync_enter(CacheDBContext.context)
        CacheDBContext.cleanPersistentStore()
        objc_sync_exit(CacheDBContext.context)
    }
    
    class func rollback() {
        objc_sync_enter(CacheDBContext.context)
        CacheDBContext.context.rollback()
        objc_sync_exit(CacheDBContext.context)
    }
    
    class func save() {
        objc_sync_enter(CacheDBContext.context)
        CacheDBContext.saveContext()
        objc_sync_exit(CacheDBContext.context)
    }
}
