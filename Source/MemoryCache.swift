//
//  MemoryCache.swift
//  Cache
//
//  Created by 丁帅 on 2017/3/16.
//  Copyright © 2017年 丁帅. All rights reserved.
//

import Foundation

// MARK: 节点
private class _Node<T> {
    weak var pre: _Node?
    var next: _Node?
    let key: String
    var value: T {
        set { _value = _Node.getCopy(newValue) }
        get { return _Node.getCopy(_value) }
    }
    var count: Int = 0
    
    fileprivate weak var linkedList: _List<T>?
    private var _value: T
    
    init(key: String, value: T) {
        self.key = key
        self._value = _Node.getCopy(value)
    }
}

private extension _Node {
    static func getCopy(_ t: T) -> T {
        guard let copying = t as? NSCopying else { return t }
        guard let result = copying.copy(with: nil) as? T else { return t }
        return result
    }
}

// MARK: 链表
// 注！！！此双向链表是不安全的，没有线程保护，节点的上下链接也可以修改；仅内部使用，在外部使用会导致不可预测的结果
private class _List<T> {
    typealias Node = _Node<T>
    var head: Node?
    var tail: Node?
    var count: Int = 0
}

private extension _List {
    func push(_ node: Node) {
        node.pre = nil
        node.next = head
        head?.pre = node
        node.linkedList = self
        head = node
        tail = tail ?? node
        count += 1
    }
    
    func remove(_ node: Node) {
        node.pre?.next = node.next
        node.next?.pre = node.pre
        head = node === head ? head?.next : head
        tail = node === tail ? tail?.pre : tail
        count -= 1
    }
    
    func dropHead() -> Node? {
        guard let temp = head else { return nil }
        remove(temp)
        return temp
    }
    
    func dropTail() -> Node? {
        guard let temp = tail else { return nil }
        remove(temp)
        return temp
    }
    
    func reset() {
        head = nil
        tail = nil
        count = 0
    }
}

// MARK: - 内存缓存
/// 内存缓存，数据的操作线程安全，LUR-2淘汰
public class MemoryCache<Element> {
    // 数据节点封装
    fileprivate typealias Node = _Node<Element>
    // 互斥锁，对缓存的所有数据操作加锁
    fileprivate let lock = UnsafeMutablePointer<pthread_mutex_t>.allocate(capacity: 1)
    // 热数据链
    fileprivate let hotChain = _List<Element>()
    // 冷数据链
    fileprivate let coldChain = _List<Element>()
    // 数据缓存
    fileprivate var source: [String: Node] = [:]
    /// 热数据缓冲池大小，值为 capacity 一半，向上取整
    fileprivate var buffer: Int { return Int(ceil(Double(capacity) / 2)) }

    
    /// 缓存的容量，取自然数，设置小于等于0的值时默认取1
    public let capacity: Int
    /// 淘汰等级，缓存需要淘汰时，会淘汰访问次数小于此值的数据；默认为2
    public var trimLevel: UInt32
    /// 当前缓存个数
    public var currentSize: Int { return source.count }
    
    /// 实例化内存缓存，设置缓存容量和淘汰等级, 缓存使用 LUR-2 算法淘汰冷数据。所有数据初始加入时为冷数据，当冷数据访问次数大于淘汰等级时，变为热数据并清0访问次数；数据需要淘汰时，缓存会淘汰访问次数小于等级的零数据
    ///
    /// - Parameters:
    ///   - capacity: 缓存容量，缓存存储数据的最大数量
    ///   - level: 淘汰等级，当缓存需要淘汰数据是，会淘汰访问次数小于此等级的数据， 默认为2
    public init(capacity: Int, trimLevel level: UInt32 = 2) {
        self.capacity = max(1, capacity)
        self.trimLevel = level
        pthread_mutex_init(lock, nil)
    }
}

// MARK: 节点操作
extension MemoryCache {
    // 添加数据节点
    fileprivate func insert(_ node: Node) {
        // 若当前缓存大小已超过容量，淘汰冷链末端数据
        if currentSize >= capacity {
            trim()
        }
        // 新数据添加在冷链头部
        coldChain.push(node)
     }
    
    // 获取数据节点
    fileprivate func get(_ key: String) -> Node? {
        guard let node = source[key] else { return nil }
        // 节点被访问时，访问数 + 1
        node.count += 1
        return node
    }
    
    // 删除数据节点
    fileprivate func remove(_ node: Node) {
        // 判断节点在冷链还是热链中，删除之
        if let chain = node.linkedList {
            chain.remove(node)
        }
    }
}

// MARK: 淘汰规则
extension MemoryCache {
    // 淘汰数据
    fileprivate func trim() {
        // 取出冷链末端数据
        guard let node = coldChain.dropTail() else { return }
        // 判断末端数据 访问次数 是否大于 淘汰等级
        if node.count >= Int(trimLevel) {
            // 访问次数 大于 淘汰等级 的节点，保留节点
            // 加热数据
            heat(node)
            // 继续淘汰冷链末端
            trim()
        } else {
            // 访问次数 小于 淘汰等级 的节点，直接淘汰
            source.removeValue(forKey: node.key)
        }
    }
    // 加热数据（把不需要淘汰的数据移到热链头部）
    private func heat(_ node: Node) {
        // 访问数清零
        node.count = 0
        // 把节点添加到热链
        hotChain.push(node)
        // 判断热链节点数是否大于阈值
        guard hotChain.count > buffer else { return }
        // 若大于，抛出热链末端节点
        guard let frozen = hotChain.dropTail() else { return }
        // 把要冷却的节点添加到冷链头部
        coldChain.push(frozen)
    }
}

// MARK: - Public
// MARK: 外部操作
extension MemoryCache {
    
    /// 根据 key 向缓存中添加数据， 如果对应的 key 已存在，覆盖原数据
    ///
    /// - Parameters:
    ///   - value: 要保存的数据，如果实现copy协议，则保存拷贝，否则直接赋值
    ///   - key: 要保存数据对应的key，若此 key 已在缓存中存在，覆盖其对应的原数据
    public func set(_ value: Element, for key: String) {
        pthread_mutex_lock(lock)
        if let node = get(key) {
            node.value = value
        } else {
            let node = _Node(key: key, value: value)
            node.count = 1
            // 添加节点
            insert(node)
            // 保存数据
            source[node.key] = node
        }
        pthread_mutex_unlock(lock)
    }
    
    /// 获取指定 key 对应的缓存数据
    ///
    /// - Parameter key: 要获取的数据对应的 key
    /// - Returns: 指定 key 对应的缓存数据，若缓存中没有此数据，返回 nil
    public func get(for key: String) -> Element? {
        pthread_mutex_lock(lock)
        let node = get(key)
        pthread_mutex_unlock(lock)
        return node?.value
    }
    
    /// 从缓存中删除指定 key 对应的数据
    ///
    /// - Parameter key: 要删除的数据对应的 key
    /// - Returns: 若删除成功，返回删除的数据，其他情况返回 nil
    @discardableResult
    public func remove(for key: String) -> Element? {
        defer {
            pthread_mutex_unlock(lock)
        }
        pthread_mutex_lock(lock)
        guard let node = get(key) else { return nil }
        // 删除节点
        remove(node)
        // 删除数据缓存
        source.removeValue(forKey: node.key)
        return node.value
    }
    
    /// 判断缓存中是否有指定 key 对应的数据
    ///
    /// - Parameter key: 查找的 key
    /// - Returns: 若找到对应数据，返回 true， 其他情况返回 false
    public func contains(key: String) -> Bool {
        pthread_mutex_lock(lock)
        let contains = source[key] != nil
        pthread_mutex_unlock(lock)
        return contains
    }
}

extension MemoryCache where Element: Equatable {
    /// 判断缓存中是否有指定的数据
    ///
    /// - Parameter value: 查找的 数据
    /// - Returns: 若找到对应数据，返回 true， 其他情况返回 false
    public func contains(value: Element) -> Bool {
        pthread_mutex_lock(lock)
        let contains = source.contains { $1.value == value }
        pthread_mutex_unlock(lock)
        return contains
    }
}

// MARK: Subscript
extension MemoryCache {
    /// 下标访问，根据 key 值，设置或者获取 对应数据
    ///     - set:  若 key 已在缓存中存在，覆盖原数据， 否则，添加新的数据缓存
    ///     - get:  若缓存中存在 key 对应数据，返回此数据， 否则返回 nil
    /// - Parameter key: 数据对应的 key 值
    public subscript(key: String) -> Element? {
        set {
            if let v = newValue {
                set(v, for: key)
            } else {
                remove(for: key)
            }
        }
        get { return get(for: key) }
    }
}

extension MemoryCache {
    public func clean() {
        pthread_mutex_lock(lock)
        hotChain.reset()
        coldChain.reset()
        source = [:]
        pthread_mutex_unlock(lock)
    }
}
