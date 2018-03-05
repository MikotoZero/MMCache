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
        guard let modelURL = Bundle(for: MMCache.CacheObject.self).url(forResource: "MMCache", withExtension: "momd") else {
            fatalError("MMCache.DiskCache.CoreData Error: Load DB cache file fail.")
        }
        // fix Xcode9 beta5 issue
        let optionalModel: NSManagedObjectModel? = NSManagedObjectModel(contentsOf: modelURL)
        guard let model = optionalModel else {
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

    @discardableResult
    class func insert(with key: String, identifer: String, path: String, dataSize size: Int64, expriedInterval interval: TimeInterval) -> CacheObject {
        objc_sync_enter(CacheDBContext.context)
        let objc = CacheObject(entity: CacheDBContext.entity, insertInto: CacheDBContext.context)
        objc.cache_identifer = identifer
        objc.key = key
        objc.path = path
        objc.data_size = size
        let date = Date()
        objc.creat_time = date as NSDate
        objc.last_update_time = date as NSDate
        objc.expried_time = Date(timeInterval: interval, since: date) as NSDate
        CacheDBContext.saveContext()
        objc_sync_exit(CacheDBContext.context)
        return objc
    }

    @nonobjc
    class func get(with key: String, identifer: String) -> CacheObject? {
        objc_sync_enter(CacheDBContext.context)
        let objc = get(with: NSPredicate(format: "key = %@ AND cache_identifer = %@", key, identifer)).first
        objc_sync_exit(CacheDBContext.context)
        return objc
    }

    @nonobjc
    class func get(identifer: String) -> [CacheObject] {
        objc_sync_enter(CacheDBContext.context)
        let objcs = get(with: NSPredicate(format: "cache_identifer = %@", identifer))
        objc_sync_exit(CacheDBContext.context)
        return objcs
    }

    @nonobjc
    class func get(with predicate: NSPredicate? = nil) -> [CacheObject] {
        objc_sync_enter(CacheDBContext.context)
        let fetch = NSFetchRequest<CacheObject>(entityName: "CacheObject")
        fetch.entity = CacheDBContext.entity
        fetch.predicate = predicate
        let result: [CacheObject]
        result = (try? CacheDBContext.context.fetch(fetch)) ?? []
        objc_sync_exit(CacheDBContext.context)
        return result
    }

    func update(with size: Int64, expriedInterval interval: TimeInterval) {
        objc_sync_enter(CacheDBContext.context)
        self.data_size = size
        let date = Date()
        self.last_update_time = date as NSDate
        self.expried_time = Date(timeInterval: interval, since: date) as NSDate
        CacheDBContext.saveContext()
        objc_sync_exit(CacheDBContext.context)
    }

    @discardableResult
    class func remove(with key: String, identifer: String) -> CacheObject? {
        objc_sync_enter(CacheDBContext.context)
        guard let objc = get(with: NSPredicate(format: "key == %@ AND cache_identifer = %@", key, identifer)).first else {
            objc_sync_exit(CacheDBContext.context)
            return nil
        }
        CacheDBContext.context.delete(objc)
        CacheDBContext.saveContext()
        objc_sync_exit(CacheDBContext.context)
        return objc
    }

    @discardableResult
    class func remove(with predicate: NSPredicate) -> [CacheObject] {
        objc_sync_enter(CacheDBContext.context)
        let objcs = get(with: predicate)
        objcs.forEach {
            CacheDBContext.context.delete($0)
        }
        CacheDBContext.saveContext()
        objc_sync_exit(CacheDBContext.context)
        return objcs
    }

    @discardableResult
    class func clean(identifer: String) -> [CacheObject] {
        objc_sync_enter(CacheDBContext.context)
        let objcs = get(with: NSPredicate(format: "cache_identifer = %@", identifer))
        objcs.forEach {
            CacheDBContext.context.delete($0)
        }
        CacheDBContext.saveContext()
        objc_sync_exit(CacheDBContext.context)
        return objcs
    }
}
