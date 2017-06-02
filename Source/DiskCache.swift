//
//  DiskCache.swift
//  Cache
//
//  Created by 丁帅 on 2017/3/21.
//  Copyright © 2017年 丁帅. All rights reserved.
//

import Foundation

public class DiskCache {
    public let basePath: URL
    public let identifer: String
    public var fileNameFormatter: (String) -> String = { $0.md5 }
    
//    /// The Default DiskCache with basePath is "~/Documents/MMDiskCache" and identifer is MMDefaultDiskCache
//    public static let `default`: DiskCache =  {
//        guard var path = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
//            fatalError("MMCahce.DiskCache Error: Get defualt DiskCache directory failed.")
//        }
//        path = path.appendingPathComponent("MMDiskCache")
//        return DiskCache(path: path, identifer: "MMDefaultDiskCache")
//    }()
    public init(path: URL, identifer: String) {
        self.basePath = path
        self.identifer = identifer
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
    
    fileprivate func get(cacheObjcWith key: String) -> CacheObject? {
        guard let objc = CacheObject.get(with: key, identifer: identifer) else { return nil }
        guard objc.expried_time?.compare(Date()) != .orderedAscending else {
            deleteFile(with: objc)
            return nil
        }
        return objc
    }
}

// MARK: data operations
extension DiskCache {
    private func fileFullPath(with key: String) -> String {
        return basePath.appendingPathComponent(fileNameFormatter(key)).absoluteString
    }
    
    fileprivate func set(data: Data, for key: String, expriedInterval interval: TimeInterval) {
        if let objc = get(cacheObjcWith: key) {
            objc.update(with: Int64(data.count), expriedInterval: interval)
            writeToFile(for: data, with: objc)
        } else {
            let objc = CacheObject.insert(with: key,
                                          identifer: identifer,
                                          path: fileNameFormatter(key),
                                          dataSize: Int64(data.count),
                                          expriedInterval: interval)
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
    public func set(_ value: Any?, for key: String, expriedInterval interval: TimeInterval = 3600 * 365 * 10) {
        guard let value = value else {
                remove(with: key)
                return
        }
        let data: Data
        if let value = value as? Encodable {
            data = value.archive()
        } else {
            data = NSKeyedArchiver.archivedData(withRootObject: value)
        }
        set(data: data, for: key, expriedInterval: interval)
    }
    
    public func get<T>(with key: String) -> T? {
        guard let data = get(dataWith: key) else { return nil }
        return NSKeyedUnarchiver.unarchiveObject(with: data) as? T
    }
    
    public func getSwift<T>(with key: String) -> T? where T: Encodable {
        guard let data = get(dataWith: key) else { return nil }
        return NSKeyedUnarchiver.unarchiveObject(with: data)
    }
    
    public func remove(with key: String) {
        guard let objc = CacheObject.remove(with: key, identifer: identifer) else { return }
        deleteFile(with: objc)
    }
    
    public func contains(_ key: String) -> Bool {
        return get(cacheObjcWith: key) != nil
    }
}

// MARK: operation with date
extension DiskCache {
    public func get(before date: Date) -> [(String, Data)] {
        return CacheObject.get(with: NSPredicate(format: "last_update_time < %@ AND cache_identifer = %@", date as NSDate, identifer)).flatMap {
            guard let key = $0.key else { return nil }
            guard let data = readFromFile(with: $0) else { return nil }
            return (key, data)
        }
    }
    
    public func get(after date: Date) -> [(String, Data)] {
        return CacheObject.get(with: NSPredicate(format: "last_update_time > %@ AND cache_identifer = %@", date as NSDate, identifer)).flatMap {
            guard let key = $0.key else { return nil }
            guard let data = readFromFile(with: $0) else { return nil }
            return (key, data)
        }
    }
    
    public func remove(before date: Date) -> Int {
        let objcs = CacheObject.remove(with: NSPredicate(format: "last_update_time < %@ AND cache_identifer = %@", date as NSDate, identifer))
        objcs.forEach {
            deleteFile(with: $0)
        }
        return objcs.count
    }
    
    public func remove(after date: Date) -> Int {
        let objcs = CacheObject.remove(with: NSPredicate(format: "last_update_time > %@ AND cache_identifer = %@", date as NSDate, identifer))
        objcs.forEach {
            deleteFile(with: $0)
        }
        return objcs.count
    }
}

// MARK: operations with size
extension DiskCache {
    public func get(larger size: Int64) -> [(String, Data)] {
        return CacheObject.get(with: NSPredicate(format: "size >= %d AND cache_identifer = %@", size, identifer)).flatMap {
            guard let key = $0.key else { return nil }
            guard let data = readFromFile(with: $0) else { return nil }
            return (key, data)
        }
    }
    
    public func get(lesser size: Int64) -> [(String, Data)] {
        return CacheObject.get(with: NSPredicate(format: "size <= %d AND cache_identifer = %@", size, identifer)).flatMap {
            guard let key = $0.key else { return nil }
            guard let data = readFromFile(with: $0) else { return nil }
            return (key, data)
        }
    }
    
    public func remove(larger size: Int64) -> Int {
        let objcs = CacheObject.remove(with: NSPredicate(format: "size >= %d AND cache_identifer = %@", size, identifer))
        objcs.forEach {
            deleteFile(with: $0)
        }
        return objcs.count
    }
    
    public func remove(lesser size: Int64) -> Int {
        let objcs = CacheObject.remove(with: NSPredicate(format: "size <= %d AND cache_identifer = %@", size, identifer))
        objcs.forEach {
            deleteFile(with: $0)
        }
        return objcs.count
    }
}

// MARK: status
extension DiskCache {
    public var size: Int64 {
        return CacheObject.get(identifer: identifer).reduce(0) { $0 + $1.data_size }
    }
    
    public var count: Int {
        return CacheObject.get(identifer: identifer).count
    }
}

// MARK: others operations
extension DiskCache {
    public func clean() {
        CacheObject.clean(identifer: identifer).forEach {
            deleteFile(with: $0)
        }
    }
}

