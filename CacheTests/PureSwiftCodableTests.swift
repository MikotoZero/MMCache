//
//  PureSwiftCodableTests.swift
//  Cache
//
//  Created by 丁帅 on 2017/3/22.
//  Copyright © 2017年 丁帅. All rights reserved.
//

import Foundation
import XCTest
import Cache


// MARK: - Struct
struct Foo {
    let bar: String
    
    init(bar: String) {
        self.bar = bar
    }
}

extension Foo: Encodable {
    func encode(with aCoder: NSCoder) {
        aCoder.encode(bar, forKey: "bar")
    }
    
    init?(coder aDecoder: NSCoder) {
        guard let bar = aDecoder.decodeObject(forKey: "bar") as? String else { return nil }
        self.bar = bar
    }
}

extension Foo: CustomStringConvertible {
    var description: String {
        return "Foo(\n  bar: \"\(bar)\"\n)"
    }
}

// MARK: - Class
class Baz: Encodable {
    let quz: String
    let foo: Foo?
    
    init(quz: String, foo: Foo? = nil) {
        self.quz = quz
        self.foo = foo
    }

    func encode(with aCoder: NSCoder) {
        aCoder.encode(quz, forKey: "quz")
        aCoder.encode(foo, forKey: "foo")
    }
    
    required init?(coder aDecoder: NSCoder) {
        guard let quz = aDecoder.decodeObject(forKey: "quz") as? String else { return nil }
        self.quz = quz
        self.foo = aDecoder.decodeObject(forKey: "foo")
    }
}

// MARK: - Enum
enum Quzz {
    case A
    case B(String)
}

extension Quzz: Encodable {
    func encode(with aCoder: NSCoder) {
        switch self {
        case .A:
            aCoder.encode("A", forKey: "self")
        case let .B(x):
            aCoder.encode("B", forKey: "self")
            aCoder.encode(x, forKey: "B")
        }
    }
    
    init?(coder aDecoder: NSCoder) {
        guard let s = aDecoder.decodeObject(forKey: "self") as? String else { return nil }
        switch s {
        case "A":
            self = .A
        case "B":
            guard let b = aDecoder.decodeObject(forKey: "B") as? String else { return nil }
            self = .B(b)
        default:
            return nil
        }
    }
}

extension Quzz: Equatable {
    static func ==(lsh: Quzz, rsh: Quzz) -> Bool {
        switch (lsh, rsh) {
        case (.A, .A): return true
        case let (.B(l), .B(r)): return l == r
        case (.A, _), (.B, _): return false
        }
    }
}

// MARK: - Test
class PureSwiftCodableTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }

    func testStruct() {
        let foo = Foo(bar: "bar")
        let data = foo.archive()
        let unarchive = Foo(unarchive: data)
        XCTAssertNotNil(unarchive)
        XCTAssertEqual(unarchive?.bar, foo.bar)
    }
    
    func testSwiftClass() {
        let baz = Baz(quz: "quz")
        let data = baz.archive()
        let unarchive = Baz(unarchive: data)
        XCTAssertNotNil(unarchive)
        XCTAssertEqual(unarchive?.quz, baz.quz)
        
        let errorBaz = Baz(unarchive: Foo(bar: "foo").archive())
        XCTAssertNil(errorBaz)
    }
    
    func testEnum() {
        let quzz = Quzz.A
        let data = quzz.archive()
        let unarchive = Quzz(unarchive: data)
        XCTAssertNotNil(unarchive)
        XCTAssertEqual(unarchive, quzz)
    }
    
    func testNestType() {
        let foo = Foo(bar: "bar")
        let baz = Baz(quz: "quz", foo: foo)
        let data = baz.archive()
        let unarchive = Baz(unarchive: data)
        XCTAssertNotNil(unarchive)
        XCTAssertEqual(unarchive?.quz, baz.quz)
        XCTAssertEqual(unarchive?.foo?.bar, foo.bar)
    }
}
