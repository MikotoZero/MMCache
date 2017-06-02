//
//  Keys.swift
//  Cache
//
//  Created by 丁帅 on 2017/5/22.
//  Copyright © 2017年 丁帅. All rights reserved.
//

import Foundation

public protocol KeyType {
    associatedtype Result
    var key: String { get }
    var level: Level { get }
    var expriedInterval: TimeInterval { get }
}

public enum Level {
    case document, cache, temp, none
}

public struct Key<T>: KeyType {
    public typealias Result = T
    public let key: String
    public let level: Level
    public let expriedInterval: TimeInterval
    
    public init(_ key: String, level: Level = .cache, expriedInterval interval: TimeInterval = 3600 * 365 * 10) {
        self.key = key
        self.level = level
        self.expriedInterval = interval
    }
}

public struct SwiftKey<T>: KeyType where T: Encodable {
    public typealias Result = T
    public let key: String
    public let level: Level
    public let expriedInterval: TimeInterval
    
    public init(_ key: String, level: Level = .cache, expriedInterval interval: TimeInterval = 3600 * 365 * 10) {
        self.key = key
        self.level = level
        self.expriedInterval = interval
    }
}


