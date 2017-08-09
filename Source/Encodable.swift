//
//  Encodable.swift
//  Cache
//
//  Created by 丁帅 on 2017/3/21.
//  Copyright © 2017年 丁帅. All rights reserved.
//

import Foundation

/// 中间层类型, 实现NSCoding协议来序列化内部的object
private class _EncoderWrap <T: Encodable>: NSObject, NSSecureCoding {
    static var supportsSecureCoding: Bool { return true }
    let object: T?

    init(_ object: T) {
        self.object = object
    }

    func encode(with aCoder: NSCoder) {
        object?.encode(with: aCoder)
    }

    required init?(coder aDecoder: NSCoder) {
        object = T(coder: aDecoder)
        super.init()
    }
}

// MARK: - Encodable 协议
/// Encodable 协议， 给 纯swift 类型提供 序列化接口
public protocol Encodable {
    func encode(with aCoder: NSCoder)
    init?(coder aDecoder: NSCoder)
}

// MARK: 把实例序列化为Data，通过Data反序列化实例的便捷方法
public extension Encodable {
    func archive() -> Data {
        return NSKeyedArchiver.archivedData(withRootObject: _EncoderWrap(self))
    }

    init?(unarchive data: Data) {
        guard let wrap = NSKeyedUnarchiver.unarchiveObject(with: data) as? _EncoderWrap<Self> else { return nil }
        guard let object = wrap.object else { return nil }
        self = object
    }
}

// MARK: - NSCoder、NSKeyedArchiver、NSKeyedUnarchiver 扩展，以支持 Encodable 类型
public extension NSCoder {

    /// Encode 纯swift类型，需要此类型实现 Encodable 协议
    ///
    /// - Parameter instance: 要 encode 的实例
    func encodeRootObject<T>(_ instance: T?) where T: Encodable {
        guard let instance = instance else { return }
        encodeRootObject(_EncoderWrap(instance))
    }

    /// Encode 纯swift类型，需要此类型实现 Encodable 协议
    ///
    /// - Parameters:
    ///   - instance: 要 encode 的实例
    ///   - key: 对应的键
    func encode<T>(_ instance: T?, forKey key: String) where T: Encodable {
        guard let instance = instance else { return }
        encode(_EncoderWrap(instance), forKey: key)
    }

    /// Decode 纯swift类型，需要此类型实现 Encodable 协议
    ///
    /// - Returns: 返回 decode 出的实例，若失败或类型不符合，则返回nil
    func decodeObject<T>() -> T? where T: Encodable {
        guard let wrap = decodeObject() as? _EncoderWrap<T> else { return nil }
        return wrap.object
    }

    /// Decode 纯swift类型，需要此类型实现 Encodable 协议
    ///
    /// - Parameter key: 对应的 encode 的 键
    /// - Returns: 返回 decode 出的实例，若失败或类型不符合，则返回nil
    func decodeObject<T>(forKey key: String) -> T? where T: Encodable {
        guard let wrap = decodeObject(forKey: key) as? _EncoderWrap<T> else { return nil }
        return wrap.object
    }
}

public extension NSKeyedArchiver {

    /// 序列化 纯swift类型的实例，需要此类型实现 Encodable 协议
    ///
    /// - Parameter instance: 要序列化的实例
    /// - Returns: 序列化后的 Data
    static func archivedData<T>(withRootObject instance: T) -> Data where T: Encodable {
        return archivedData(withRootObject: _EncoderWrap(instance))
    }
}

public extension NSKeyedUnarchiver {

    /// 反序列化 纯swift类型的实例，需要此类型实现 Encodable 协议
    ///
    /// - Parameter data: 要反序列化的源 Data
    /// - Returns: 返回 解析 出的实例，若失败或类型不符合，则返回nil
    static func unarchiveObject<T>(with data: Data) -> T? where T: Encodable {
        guard let wrap = unarchiveObject(with: data) as? _EncoderWrap<T> else { return nil }
        return wrap.object
    }
}
