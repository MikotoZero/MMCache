//
//  DiskCache.swift
//  Cache
//
//  Created by 丁帅 on 2017/3/21.
//  Copyright © 2017年 丁帅. All rights reserved.
//

import Foundation
import CommonCrypto

private extension String {
    var md5: String {
        let messageData = self.data(using:.utf8)!
        var digestData = Data(count: Int(CC_MD5_DIGEST_LENGTH))
        _ = digestData.withUnsafeMutableBytes {digestBytes in
            messageData.withUnsafeBytes {messageBytes in
                CC_MD5(messageBytes, CC_LONG(messageData.count), digestBytes)
            }
        }
        return digestData.map { String(format: "%02hhx", $0) }.joined()
    }
}


public class DiskCache {
    public let basePath: URL
    
    public var fileNameFormatter: (String) -> String = { $0.md5 }
    
    public static let `default`: DiskCache =  {
        guard var path = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            fatalError("MMCahce.DiskCache Error: Get defualt DiskCache directory failed.")
        }
        path = path.appendingPathComponent("MMDiskCache")
        return DiskCache(path: path)
    }()
    
    public init(path: URL) {
        self.basePath = path
        var isDirectory: ObjCBool = false
        let existed = fileManager.fileExists(atPath: path.path, isDirectory: &isDirectory)
        if existed && !isDirectory.boolValue {
                fatalError("MMCahce.DiskCache Error: DiskCache path \"\(path.path)\" is already existed while it isn't a directory")
        }
        if !existed {
            do {
                try fileManager.createDirectory(atPath: path.path, withIntermediateDirectories: true, attributes: nil)
            } catch {
                    fatalError("MMCahce.DiskCache Error: Creat DiskCache directory failed. error: \(error)")
            }
        }
        
    }
    
    // MARK: private properties
    fileprivate let fileManager = FileManager.default
}

// MARK: - Private
// MARK: file operations
extension DiskCache {
    fileprivate func readFromFile(with objc: CacheObject) -> Data? {
        guard
            let path = objc.path,
            let url = URL(string: path)
            else { return nil }
        return try? Data(contentsOf: url)
    }
    
    fileprivate func writeToFile(for data: Data, with objc: CacheObject) {
        guard
            let path = objc.path,
            let url = URL(string: path)
            else { return }
        try? data.write(to: url, options: .atomic)
    }
    
    fileprivate func deleteFile(with objc: CacheObject) {
        guard
            let path = objc.path,
            let url = URL(string: path)
            else { return }
        try? fileManager.removeItem(at: url)
    }
}

// MARK: cacheObject operations
extension DiskCache {
    fileprivate func creat(cacheObjcWith key: String, data: Data, expriedTime time: TimeInterval) -> CacheObject {
        let objc = CacheObject.insert()
        objc.key = key
        let date = Date()
        objc.creat_time = date as NSDate
        objc.last_update_time = date as NSDate
        objc.expried_time = Date(timeInterval: time, since: date) as NSDate
        objc.size = Int64(data.count)
        objc.path = fileNameFormatter(key)
        CacheObject.save()
        return objc
    }
    
    fileprivate func get(cacheObjcWith key: String) -> CacheObject? {
        let objc = CacheObject.get(with: key)
        guard objc?.expried_time?.compare(Date()) != .orderedAscending else { return nil }
        return objc
    }
    
    fileprivate func update(cacheObjc objc: CacheObject, with data: Data, expriedTime time: TimeInterval) {
        let date = Date()
        objc.last_update_time = date as NSDate
        objc.expried_time = Date(timeInterval: time, since: date) as NSDate
        objc.size =  Int64(data.count)
        CacheObject.save()
    }
    
    fileprivate func remove(cacheObjcWith key: String) -> CacheObject? {
        guard let objc = CacheObject.remove(with: key) else { return nil }
        CacheObject.save()
        return objc
    }
    
    @discardableResult fileprivate func get(cacheObjcsWith predicate: NSPredicate, operation: ((CacheObject) -> Void)? = nil) -> [CacheObject] {
        let objcs = CacheObject.get(with: predicate)
        if let operation = operation {
            objcs.forEach(operation)
        }
        CacheObject.save()
        return objcs
    }
}

// MARK: utils
extension DiskCache {
    fileprivate func fileFullPath(with key: String) -> String {
        return basePath.appendingPathComponent(fileNameFormatter(key)).absoluteString
    }
}

// MARK: data operations
extension DiskCache {
    fileprivate func set(data: Data, for key: String, expriedTime time: TimeInterval) {
        if let objc = get(cacheObjcWith: key) {
            update(cacheObjc: objc, with: data, expriedTime: time)
            writeToFile(for: data, with: objc)
        } else {
            let objc = creat(cacheObjcWith: key, data: data, expriedTime: time)
            writeToFile(for: data, with: objc)
        }
    }
    
    fileprivate func get(dataWith key: String) -> Data? {
        guard let objc = get(cacheObjcWith: key) else { return nil }
        return readFromFile(with: objc)
    }
}

// MARK: - Public
// MARK: operations
extension DiskCache {
    public func set<T>(_ value: T?, for key: String, expriedTime time: TimeInterval = 3600 * 365 * 10) where T: NSObject, T: NSCoding {
        guard let value = value else {
                remove(with: key)
                return
        }
        let data = NSKeyedArchiver.archivedData(withRootObject: value)
        set(data: data, for: key, expriedTime: time)
    }
    
    public func set(_ value: Encodable?, for key: String, expriedTime time: TimeInterval = 3600 * 365 * 10) {
        guard let value = value else {
                remove(with: key)
                return
        }
        set(data: value.archive(), for: key, expriedTime: time)
    }
    
    public func get<T>(with key: String) -> T? where T: NSObject, T: NSCoding {
        guard let data = get(dataWith: key) else { return nil }
        return NSKeyedUnarchiver.unarchiveObject(with: data) as? T
    }
    
    public func get<T>(with key: String) -> T? where T: Encodable {
        guard let data = get(dataWith: key) else { return nil }
        return T(unarchive: data)
    }
    
    public func remove(with key: String) {
        guard let objc = remove(cacheObjcWith: key) else { return }
        deleteFile(with: objc)
    }
    
    public func contains(_ key: String) -> Bool {
        return get(cacheObjcWith: key) != nil
    }
}

// MARK: operation with date
extension DiskCache {
    public func get<T>(before date: Date) -> [T] where T: NSObject, T: NSCoding {
        return get(cacheObjcsWith: NSPredicate(format: "last_update_time < %@", date as NSDate))
        .flatMap {
            guard let key = $0.key else { return nil }
            return get(with: key)
        }
    }
    
    public func get<T>(before date: Date) -> [T] where T: Encodable {
        return get(cacheObjcsWith: NSPredicate(format: "last_update_time < %@", date as NSDate))
            .flatMap {
                guard let key = $0.key else { return nil }
                return get(with: key)
        }
    }
    
    public func get<T>(after date: Date) -> [T] where T: NSObject, T: NSCoding {
        return get(cacheObjcsWith: NSPredicate(format: "last_update_time > %@", date as NSDate))
            .flatMap {
                guard let key = $0.key else { return nil }
                return get(with: key)
        }
    }
    
    public func get<T>(after date: Date) -> [T] where T: Encodable {
        return get(cacheObjcsWith: NSPredicate(format: "last_update_time > %@", date as NSDate))
            .flatMap {
                guard let key = $0.key else { return nil }
                return get(with: key)
        }
    }
    
    public func remove(before date: Date) -> Int {
        return get(cacheObjcsWith: NSPredicate(format: "last_update_time < %@", date as NSDate)) {
            CacheObject.remove($0)
            self.deleteFile(with: $0)
        }.count
    }
    
    public func remove(after date: Date) -> Int {
       return get(cacheObjcsWith: NSPredicate(format: "last_update_time > %@", date as NSDate)) {
            CacheObject.remove($0)
            self.deleteFile(with: $0)
        }.count
    }
}

// MARK: status
extension DiskCache {
    public var size: Int64 {
        return CacheObject.get().reduce(0) { $0 + $1.size }
    }
    
    public var count: Int {
        return CacheObject.get().count
    }
}

// MARK: others operations
extension DiskCache {
    public func cleanAll() {
        CacheObject.clean()
    }
}

