//
//  MemoryCacheTests.swift
//  Cache
//
//  Created by 丁帅 on 2017/3/23.
//  Copyright © 2017年 丁帅. All rights reserved.
//

import XCTest
import MMCache

class MemoryCacheTests: XCTestCase {
    let cache = MemoryCache<String>(capacity: 20)
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }

    func testSingleOperation() {
        let target = "target"
        cache.set(target, for: "target")
        XCTAssertEqual(cache.currentSize, 1)
        
        var getTarget = cache.get(for: "target")
        XCTAssertEqual(getTarget, target)
        var shouldNil = cache.get(for: "nil")
        XCTAssertNil(shouldNil)
        
        cache.set("foo", for: "foo")
        getTarget = cache.get(for: "target")
        XCTAssertEqual(getTarget, target)
        
        let removeTarget = cache.remove(for: "target")
        XCTAssertEqual(removeTarget, target)
        shouldNil = cache.remove(for: "nil")
        XCTAssertNil(shouldNil)
        
        cache.set(target, for: "target")
        let replace = "replace"
        cache.set(replace, for: "target")
        getTarget = cache.get(for: "target")
        XCTAssertNotEqual(getTarget, target)
        XCTAssertEqual(getTarget, replace)
    }
    
    func testTrim() {
        var shouldNil: String?
        var shouldNotNil: String?
        for i in 0 ... 20 {
            let str = "\(i)"
            cache.set(str, for: str)
        }
        shouldNil = cache.get(for: "0")
        XCTAssertNil(shouldNil)
        
        for i in 1 ... 10 {
            let str = "\(i)"
            _ = cache.get(for: str)
        }
        
        cache.set("100", for: "100")
        shouldNotNil = cache.get(for: "1")
        XCTAssertNotNil(shouldNotNil)
        shouldNil = cache.get(for: "11")
        XCTAssertNil(shouldNil)
    }
}
