//
//  DBTests.swift
//  Cache
//
//  Created by 丁帅 on 2017/3/23.
//  Copyright © 2017年 丁帅. All rights reserved.
//

import XCTest
import CoreData
@testable import Cache

class DBTests: XCTestCase {
    
    @discardableResult private func insertObject(_ key: String) -> CacheObject {
        if let cache = CacheObject.get(with: key) {
            cache.last_update_time = Date() as NSDate
            return cache
        } else {
            let cache = CacheObject.insert()
            cache.key = key
            cache.last_update_time = Date() as NSDate
            return cache
        }
    }
    
    
    func testSave() {
        let cache = insertObject("foo")
        CacheObject.save()
        
        let result = CacheObject.get(with: "foo")
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.path, cache.path)
        
        let delete = CacheObject.remove(with: "foo")
        CacheObject.save()
        XCTAssertNotNil(delete)
        XCTAssertEqual(delete?.path, result?.path)
        
        let beNil = CacheObject.get(with: "foo")
        XCTAssertNil(beNil)
    }
    
    func testGetAll() {
        for i in 0..<10 {
            insertObject("\(i)")
        }
        CacheObject.save()
        
        XCTAssert(CacheObject.get().count == 10)
    }
}
