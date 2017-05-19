//
//  DiskCacheTests.swift
//  Cache
//
//  Created by 丁帅 on 2017/5/18.
//  Copyright © 2017年 丁帅. All rights reserved.
//

import XCTest
import Cache

class TestPureSwiftClass: Encodable {
    let intL: Int
    var strV: String
    var nest: TestPureSwiftClass?
    
    init(i: Int, s: String, m: TestPureSwiftClass?) {
        intL = i
        strV = s
        nest = m
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(intL, forKey: "intL")
        aCoder.encode(strV, forKey: "strV")
        aCoder.encode(nest, forKey: "nest")
    }
    
    required init?(coder aDecoder: NSCoder) {
        intL = aDecoder.decodeInteger(forKey: "intL")
        strV = aDecoder.decodeObject(forKey: "strV") as? String ?? "decode fail"
        nest = aDecoder.decodeObject(forKey: "nest") as? TestPureSwiftClass
    }
 }

class DiskCacheTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testSave() {
        DiskCache.default.clean()
        
        DiskCache.default.set("foo", for: "str")
        DiskCache.default.set(100, for: "int")
        
        let inner = TestPureSwiftClass(i: 0, s: "none", m: nil)
        let objc = TestPureSwiftClass(i: 1, s: "str", m: inner)
        DiskCache.default.set(objc, for: "objc")
        
        XCTAssertEqual(DiskCache.default.count, 3)
    }
    
}
