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
    
    func testSave() {
        let cache: CacheObject
        if let _cache = CacheObject.get(with: "foo") {
            cache = _cache
            print("get:  ", cache.last_update_time as Any)
            cache.last_update_time = Date() as NSDate
            CacheObject.save()
        } else {
            cache = CacheObject.insert()
            cache.key = "foo"
            cache.size = 123456
            cache.path = "/foo"
            cache.last_update_time = Date() as NSDate
            print("insert:  ", cache.last_update_time!)
            CacheObject.save()
        }
        
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
}
