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
                #if Debug
                    fatalError("Load cache file fail.")
                #else
                    return NSPersistentStoreCoordinator()
                #endif
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
            #if Debug
                fatalError("addPersistentStore problems: \(error)")
            #endif
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
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // TODO: save fail ...
                #if Debug
                    fatalError("save fail: \(error)")
                #endif
            }
        }
    }
}

extension CacheObject {
    
    class func insert() -> CacheObject {
        let objc = CacheObject(entity: CacheDBContext.entity, insertInto: CacheDBContext.context)
        objc.creat_time = Date() as NSDate
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
    
    @nonobjc class func remove(with id: NSManagedObjectID) -> CacheObject {
        let objc = CacheDBContext.context.object(with: id) as! CacheObject
        CacheDBContext.context.delete(objc)
        return objc
    }
    
    @nonobjc class func remove(with key: String) -> CacheObject? {
        guard let objc = get(with: NSPredicate(format: "key == %@", key)).first else { return nil }
        CacheDBContext.context.delete(objc)
        return objc
    }
    
    
    class func rollback() {
        CacheDBContext.context.rollback()
    }
    
    class func save() {
        CacheDBContext.saveContext()
    }
}
