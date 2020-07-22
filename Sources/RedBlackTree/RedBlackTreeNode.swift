//
//  RedBlackTreeNode.swift
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

final class RedBlackTreeNode<Key: Comparable, Value> {

    var red = true
    var left, right: RedBlackTreeNode!
    weak var parent: RedBlackTreeNode!
    let key: Key!
    var value: Value!

    init(sentinel: ()) {
        red = false
        key = nil
        value = nil
    }

    init(key: Key, value: Value, sentinel: RedBlackTreeNode) {
        self.key = key
        self.value = value
        assert(sentinel.isSentinel)
        left = sentinel; right = sentinel; parent = sentinel
    }

    init(deepCopy node: RedBlackTreeNode, sentinel: RedBlackTreeNode, setParent: RedBlackTreeNode? = nil) {
        key = node.key
        value = node.value
        red = node.red
        parent = setParent ?? sentinel
        left = node.left.isSentinel ? sentinel : RedBlackTreeNode(deepCopy: node.left, sentinel: sentinel, setParent: self)
        right = node.right.isSentinel ? sentinel : RedBlackTreeNode(deepCopy: node.right, sentinel: sentinel, setParent: self)
    }

    var isSentinel: Bool {
        return key == nil
    }

    /// - Complexity: O(log count)
    func subtreeMin() -> RedBlackTreeNode {
        guard !self.isSentinel else { return self }
        var x = self
        while !x.left.isSentinel { x = x.left }
        assert(!x.isSentinel)
        return x
    }

    /// - Complexity: O(log count)
    func subtreeMax() -> RedBlackTreeNode {
        guard !self.isSentinel else { return self }
        var x = self
        while !x.right.isSentinel { x = x.right }
        assert(!x.isSentinel)
        return x
    }

    /// - Complexity: Amortised O(1) across a full iteration of the tree.
    func successor() -> RedBlackTreeNode? {
        if isSentinel { return nil }
        // if the right subtree exists, the successor is the smallest item in it
        if !right.isSentinel { return right.subtreeMin() }
        // the successor is the first ancestor which has self in its left subtree
        var x = self, y = x.parent!
        while !y.isSentinel && x === y.right { x = y; y = x.parent }
        return y.isSentinel ? nil : y
    }

    /// - Complexity: Amortised O(1) across a full iteration of the tree.
    func predecessor() -> RedBlackTreeNode? {
        if isSentinel { return nil }
        // if the left subtree exists, the predecessor is the largest item in it
        if !left.isSentinel { return left.subtreeMax() }
        // the predecessor is the first ancestor which has self in its right subtree
        var x = self, y = x.parent!
        while !y.isSentinel && x === y.left { x = y; y = x.parent }
        return y.isSentinel ? nil : y
    }

}
