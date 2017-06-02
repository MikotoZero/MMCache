//
//  Cache.swift
//  Cache
//
//  Created by 丁帅 on 2017/5/18.
//  Copyright © 2017年 丁帅. All rights reserved.
//

import  Foundation

public class Cache {
    // MARK: public properties
    public static let `default` = Cache(withIdentifer: "MMDefaultCache", directoryName: "MMCache")
    
    public init(withIdentifer identifer: String, directoryName name: String? = nil, memoryCapacity capacity: Int = 1000, memoryTrimLevel level: UInt32 = 2) {
        documentDC = DiskCache(path: FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent(name ?? identifer), identifer: identifer)
        cacheDC = DiskCache(path: FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!.appendingPathComponent(name ?? identifer), identifer: identifer)
        tempDC = DiskCache(path: FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent(name ?? identifer), identifer: identifer)
        memoryCache = MemoryCache(capacity: capacity, trimLevel: level)
    }
    
    // MARK: private properties
    fileprivate let documentDC: DiskCache
    fileprivate let cacheDC: DiskCache
    fileprivate let tempDC: DiskCache
    fileprivate let memoryCache: MemoryCache<Any>
}

// MARK: memory cache
extension Cache {
    fileprivate func setToMemory<K>(_ value: K.Result, key: K) where K: KeyType {
        memoryCache[key.key] = value
    }
    
    fileprivate func getFromMemory<K>(with key: K) -> K.Result? where K: KeyType {
        if let memory = memoryCache[key.key] as? K.Result {
            return memory
        }
        return nil
    }
    
    fileprivate func removeFromMemory<K>(with key: K) where K: KeyType {
        memoryCache[key.key] = nil
    }
}

// MARK: disk cache
extension Cache {
    private func diskCache<K>(for key: K) -> DiskCache? where K: KeyType {
        switch key.level {
        case .document:
            return documentDC
        case .cache:
            return cacheDC
        case .temp:
            return tempDC
        case .none:
            return nil
        }
    }
    
    fileprivate func setToDisk<K>(_ value: K.Result, for key: K) where K: KeyType {
        guard let dc = diskCache(for: key) else { return }
        dc.set(value, for: key.key, expriedInterval: key.expriedInterval)
    }

    fileprivate func getFromDisk<K>(with key: K) -> K.Result? where K: KeyType, K.Result: Encodable {
        guard let dc = diskCache(for: key) else { return nil }
        return dc.getSwift(with: key.key)
    }
    
    fileprivate func getFromDisk<K>(with key: K) -> K.Result? where K: KeyType {
        guard let dc = diskCache(for: key) else { return nil }
        return dc.get(with: key.key)
    }

    fileprivate func removeFromDisk<K>(with key: K) where K: KeyType {
        guard let dc = diskCache(for: key) else { return }
        dc.remove(with: key.key)
    }
}

// MARK: - Public
// MARK: set & get
extension Cache {
    public func set<K>(_ value: K.Result?, for key: K) where K: KeyType {
        if let value = value {
            setToMemory(value, key: key)
            setToDisk(value, for: key)
        } else {
            removeFromMemory(with: key)
            removeFromDisk(with: key)
        }
    }
    
    public func get<K>(with key: K) -> K.Result? where K: KeyType, K.Result: Encodable {
        if let memory = getFromMemory(with: key) {
            return memory
        } else if let disk = getFromDisk(with: key) {
            setToMemory(disk, key: key)
            return disk
        }
        return nil
    }
    
    public func get<K>(with key: K) -> K.Result? where K: KeyType {
        if let memory = getFromMemory(with: key) {
            return memory
        } else if let disk = getFromDisk(with: key) {
            setToMemory(disk, key: key)
            return disk
        }
        return nil
    }
}

// MARK: subscript
extension Cache {
    // TODO: Can not use generic type in subscript. This is coming in Swift 4
    /*
    subscript<K>(_ key: K) -> K.Result? where K: KeyType {
    }
     */
}

// MARK: clean
extension Cache {
    public func cleanMemory() {
        memoryCache.clean()
    }
    
    public func cleanDiskDocument() {
        documentDC.clean()
    }
    
    public func cleanDiskCache() {
        cacheDC.clean()
    }
    
    public func cleanDiskTemplate() {
        tempDC.clean()
    }
    
    public func cleanAll() {
        memoryCache.clean()
        documentDC.clean()
        cacheDC.clean()
        tempDC.clean()
    }
}
