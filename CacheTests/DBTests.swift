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
        let cache = CacheObject()
        cache.key = "foo"
        cache.size = 123456
        cache.path = "/foo"
        CacheDBManager.shared.saveContext()
        
        let fetch = NSFetchRequest<CacheObject>(entityName: "CacheObject")
        fetch.entity = CacheObject.entity()
        fetch.predicate = NSPredicate(format: "key == %@", "foo")
        let result = try? CacheDBManager.shared.persistentContainer.viewContext.fetch(fetch)
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.first?.path, cache.path)
    }
}
