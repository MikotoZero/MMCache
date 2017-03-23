//
//  DiskCache.swift
//  Cache
//
//  Created by 丁帅 on 2017/3/21.
//  Copyright © 2017年 丁帅. All rights reserved.
//

import Foundation

class DiskCache {
    
    
}

// MARK: - Public
// MARK: 数据操作
extension DiskCache {
    public func set<T>(_ value: T, for key: String) where T: NSObject, T: NSCoding {
        
    }
    
    public func set(pureSwift value: Encodable, for key: String) {
        
    }
    
    public func get(with key: String) -> Any? {
        return nil
    }
    
    public func remove(for key: String) -> Any? {
        
        return nil
    }
    
    public func contains(_ key: String) -> Bool {
        return false
    }
}

// MARK: 状态查询
extension DiskCache {
    var size: UInt64 {
        return 0
    }
    
    var count: UInt64 {
        return 0
    }
}

