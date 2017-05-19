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

private let id = "DBTests"

class DBTests: XCTestCase {
    

    
    func testSave() {
        CacheObject.clean(identifer: id)

        let cache = CacheObject.insert(with: "foo", identifer: id, path: "/foo", dataSize: 1024, expriedInterval: 100)
        
        let result = CacheObject.get(with: "foo", identifer: id)
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.path, cache.path)
    }
    
    func testGet() {
        CacheObject.clean(identifer: id)
        
        CacheObject.insert(with: "foo", identifer: id, path: "/foo", dataSize: 1024, expriedInterval: 100)
        CacheObject.insert(with: "bar", identifer: id, path: "/bar", dataSize: 512, expriedInterval: 100)
        
        let foo = CacheObject.get(with: "foo", identifer: id)
        let bar = CacheObject.get(with: "bar", identifer: id)
        let baz = CacheObject.get(with: "baz", identifer: id)
            
        XCTAssertNotNil(foo)
        XCTAssertNil(baz)
        XCTAssertNotNil(bar?.last_update_time)
        XCTAssertEqual(bar?.data_size, 512)
        
        sleep(5)
        CacheObject.insert(with: "baz", identifer: id, path: "/baz", dataSize: 256, expriedInterval: 100)
        let date = (bar?.last_update_time)!
        let noNillBaz = CacheObject.get(with: NSPredicate(format: "last_update_time > %@ AND cache_identifer = %@", date, id)).first
        
        XCTAssertNotNil(noNillBaz)
        XCTAssertEqual(noNillBaz?.key, "baz")
        
        let size = 500
        let larges = CacheObject.get(with: NSPredicate(format: "data_size > %d AND cache_identifer = %@", size, id))
        
        XCTAssertEqual(larges.count, 2)
    }
    
    func testGetAll() {
        CacheObject.clean(identifer: id)
        for i in 0..<10 {
            CacheObject.insert(with: "\(i)", identifer: id, path: "/\(i)", dataSize: Int64(2 * i), expriedInterval: 100)
        }
        XCTAssert(CacheObject.get(identifer: id).count == 10)
    }
}
