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
        
        let cache = CacheObject.insert()
        cache.key = "foo"
        cache.size = 123456
        cache.path = "/foo"
        CacheObject.save()
        
        let result = CacheObject.get(with: "foo")
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.path, cache.path)
    }
}
