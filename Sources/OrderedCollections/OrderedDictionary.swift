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

import RedBlackTree

// TODO: this shouldn't just be a typealias, it should be a full wrapper, because RedBlackTree supports duplicate keys. the current RedBlackTreeIndex comparison function is probably wrong and should be removed.
public typealias OrderedDictionary<Key: Comparable, Value> = RedBlackTree<Key, Value>

extension OrderedDictionary {
    
    public subscript(key: Key) -> Value? {
        get {
            guard let index = find(key) else { return nil }
            return self[index].value
        }
        set {
            if let index = find(key) {
                if let newValue = newValue {
                    updateValue(newValue, atIndex: index)
                }
                else {
                    remove(at: index)
                }
            }
            else if let newValue = newValue {
                insert(key, with: newValue)
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
}
