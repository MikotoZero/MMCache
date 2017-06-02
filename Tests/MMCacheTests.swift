//
//  MMCacheTests.swift
//  MMCacheTests
//
//  Created by 丁帅 on 2017/5/23.
//  Copyright © 2017年 M_M. All rights reserved.
//

import XCTest
import MMCache

private func `do`(_ block: () -> Void) {
    block()
}

class MMCacheTests: XCTestCase {
    
    let cache = Cache(withIdentifer: "MMCacheTest")

    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testSet() {
        let key = Key<String>("test")
        cache.set("Hellow World", for: key)
        let r = cache.get(with: key)

        XCTAssertEqual(r, "Hellow World")
    }
    
    func testSetSwift() {
        // struct
        do {
            let foo = Foo("foo")
            let key = SwiftKey<Foo>("foo")

            cache.set(foo, for: key)
            let r = cache.get(with: key)
            
            XCTAssertEqual(r?.foo, foo.foo)
        }
        
        // class
        do {
            let foo = Foo("foo")
            let bar = Bar("bar", foo: foo)
            let key = SwiftKey<Bar>("bar")
            
            cache.set(bar, for: key)
            let r = cache.get(with: key)
            
            XCTAssertEqual(r?.bar, bar.bar)
            XCTAssertEqual(r?.foo?.foo, foo.foo)
        }
    
        // enum
        do {
            let quzA = Quzz.A
            let quzB = Quzz.B("quz")
            let key = SwiftKey<Quzz>("quz")
            
            cache.set(quzB, for: key)
            let r = cache.get(with: key)
            
            XCTAssertNotEqual(r, quzA)
            XCTAssertEqual(r, quzB)
        }
    }
    
}
