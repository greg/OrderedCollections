//
//  OrderedDictionary.swift
//  OrderedCollections
//
//  The MIT License (MIT)
//
//  Copyright (c) 2020 Greg Omelaenko
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.
//

import Swift
import RedBlackTree

public struct OrderedDictionary<Key: Comparable, Value> {
    
    private var tree: RedBlackTree<Key, Value>
    
    init<S>(uniqueKeysWithValues keysAndValues: S) where S : Sequence, S.Element == (Key, Value) {
        self.tree = RedBlackTree(keysAndValues)
    }
    
    public subscript(key: Key) -> Value? {
        get {
            guard let index = tree.find(key) else { return nil }
            return tree[index].value
        }
        set {
            if let index = tree.find(key) {
                if let newValue = newValue {
                    tree.updateValue(newValue, atIndex: index)
                }
                else {
                    tree.remove(at: index)
                }
            }
            else if let newValue = newValue {
                tree.insert(key, with: newValue)
            }
        }
    }

    public subscript(key: Key, default defaultValue: @autoclosure () -> Value) -> Value {
        get {
            return self[key] ?? defaultValue()
        }
        set {
            self[key] = newValue
        }
    }
    
    public var count: Int {
        return 0
    }
}

extension OrderedDictionary: Collection {
    
    public typealias Index = RedBlackTreeIndex<Key, Value>
    public typealias Element = (key: Key, value: Value)
    
    public var startIndex: Index {
        return tree.startIndex
    }
    
    public var endIndex: Index {
        return tree.endIndex
    }
    
    public func index(after i: RedBlackTreeIndex<Key, Value>) -> Index {
        return tree.index(after: i)
    }
    
    public subscript(position: Index) -> Element {
        return tree[position]
    }
}

extension OrderedDictionary: ExpressibleByDictionaryLiteral {
    
    public init(dictionaryLiteral elements: (Key, Value)...) {
        self.init(uniqueKeysWithValues: elements)
    }
}
