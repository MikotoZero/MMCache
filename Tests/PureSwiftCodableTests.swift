//
//  PureSwiftCodableTests.swift
//  Cache
//
//  Created by 丁帅 on 2017/3/22.
//  Copyright © 2017年 丁帅. All rights reserved.
//

import Foundation
import XCTest
import MMCache

// MARK: - Struct
struct Foo {
    let foo: String

    init(_ foo: String) {
        self.foo = foo
    }
}

extension Foo: Encodable {
    func encode(with aCoder: NSCoder) {
        aCoder.encode(foo, forKey: "foo")
    }

    init?(coder aDecoder: NSCoder) {
        guard let foo = aDecoder.decodeObject(forKey: "foo") as? String else { return nil }
        self.foo = foo
    }
}

extension Foo: CustomStringConvertible {
    var description: String {
        return "Foo(\n  bar: \"\(foo)\"\n)"
    }
}

// MARK: - Class
class Bar: Encodable {
    let bar: String
    let foo: Foo?

    init(_ bar: String, foo: Foo? = nil) {
        self.bar = bar
        self.foo = foo
    }

    func encode(with aCoder: NSCoder) {
        aCoder.encode(bar, forKey: "bar")
        aCoder.encode(foo, forKey: "foo")
    }

    required init?(coder aDecoder: NSCoder) {
        guard let bar = aDecoder.decodeObject(forKey: "bar") as? String else { return nil }
        self.bar = bar
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
    static func == (lsh: Quzz, rsh: Quzz) -> Bool {
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
        let foo = Foo("foo")
        let data = foo.archive()
        let unarchive = Foo(unarchive: data)
        XCTAssertNotNil(unarchive)
        XCTAssertEqual(unarchive?.foo, foo.foo)
    }

    func testSwiftClass() {
        let bar = Bar("bar")
        let data = bar.archive()
        let unarchive = Bar(unarchive: data)
        XCTAssertNotNil(unarchive)
        XCTAssertEqual(unarchive?.bar, bar.bar)

        let errorBaz = Bar(unarchive: Foo("foo").archive())
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
        let foo = Foo("foo")
        let bar = Bar("bar", foo: foo)
        let data = bar.archive()
        let unarchive = Bar(unarchive: data)
        XCTAssertNotNil(unarchive)
        XCTAssertEqual(unarchive?.bar, bar.bar)
        XCTAssertEqual(unarchive?.foo?.foo, foo.foo)
    }
}
