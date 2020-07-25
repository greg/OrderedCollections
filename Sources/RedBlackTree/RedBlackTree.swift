//
//  RedBlackTree.swift
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

/*
 A red-black tree is a binary tree that satisfies the following red-black properties:
 1. Every node is either red or black.
 2. The root is black.
 3. Every leaf (nil) is black.
 4. If a node is red, then both its children are black.
 5. For each node, all simple paths from the node to descendant leaves contain the same number of black nodes.
 */

/// Implements a red-black binary tree: a collection of keys with associated values, ordered by key only.
///
/// Provides O(log `count`) insertion, search, and removal, as well as a `CollectionType` interface.
public struct RedBlackTree<Key : Comparable, Value> {

    private typealias Node = RedBlackTreeNode<Key, Value>

    private var sentinel = Node(sentinel: ())
    private var root: Node
    private unowned var firstNode, lastNode: Node

    public private(set) var count = 0

    /// Copy-on-write optimisation. Returns `true` if the tree was copied.
    /// - Complexity: Expected O(1), O(`count`) if the structure was copied and modified.
    @discardableResult
    private mutating func ensureUnique() -> Bool {
        if _slowPath(root !== sentinel && !isKnownUniquelyReferenced(&root)) {
            sentinel = Node(sentinel: ())
            root = RedBlackTreeNode(deepCopy: root, sentinel: sentinel)
            firstNode = root.subtreeMin()
            lastNode = root.subtreeMax()
            return true
        }
        assert(root === sentinel || isKnownUniquelyReferenced(&root))
        return false
    }

    public init() {
        root = sentinel
        firstNode = sentinel
        lastNode = sentinel
    }

    // TODO: initialiser that takes a sorted sequence and constructs a tree in O(n) time
    /// - Complexity: O(n log n), where n = `seq.count`.
    public init<S : Sequence>(_ seq: S) where S.Element == (Key, Value) {
        self.init()
        for (k, v) in seq { insert(k, with: v) }
    }

    private func loopSentinel() {
        assert(sentinel.isSentinel)
        assert(!sentinel.red)
        assert(sentinel.left == nil)
        assert(sentinel.right == nil)
        assert(sentinel.parent == nil)
        sentinel.left = sentinel
        sentinel.right = sentinel
        sentinel.parent = sentinel
    }

    private func fixSentinel() {
        assert(sentinel.isSentinel)
        assert(!sentinel.red)
        sentinel.left = nil
        sentinel.right = nil
        sentinel.parent = nil
    }

    /// Insert the key `k` into the tree with associated value `value`. Returns the index at which `k` was inserted.
    ///
    /// If this is the *first* modification to the tree since creation or copying, invalidates all indices with respect to `self`.
    ///
    /// - Complexity: O(log `count`)
    @discardableResult
    public mutating func insert(_ k: Key, with value: Value) -> Index {
        ensureUnique()
        loopSentinel()

        let z = Node(key: k, value: value, sentinel: sentinel)
        do {
            var y = sentinel
            var x = root
            // find a leaf (nil) node x to replace with z, and its parent y
            while x !== sentinel {
                y = x
                // move left if z sorts before x, right otherwise
                x = z.key < x.key ? x.left : x.right
            }
            z.parent = y
            // y is only nil if x is the root
            if y === sentinel { root = z }
            // attach z to left or right of y, depending on sort order
            else if z.key < y.key { y.left = z }
            else { y.right = z }
        }

        // fix violated red-black properties (rebalance the tree)
        do {
            var z = z
            while z.parent.red {
                let zp = z.parent!
                assert(z.red)
                assert(zp !== root) // if zp is the root, then zp is black
                let zpp = zp.parent! // zp is red, so cannot be the root
                // if z's parent is a right child, swap left and right operations
                // further comments that mention left/right assume left
                let left = zp === zpp.left

                let y = left ? zpp.right! : zpp.left!
                if y.red {
                    // case 1: z's uncle y is red
                    zp.red = false
                    y.red = false
                    zpp.red = true
                    z = zpp
                }
                else {
                    // if z is a right child
                    if z === (left ? zp.right : zp.left) {
                        // case 2: z's uncle y is black and z is a right child
                        z = zp
                        left ? rotateLeft(z) : rotateRight(z)
                        // z is now a left child
                    }
                    let zp = z.parent!, zpp = zp.parent!
                    // case 3: z's uncle y is black and z is a left child
                    zp.red = false
                    zpp.red = true
                    left ? rotateRight(zpp) : rotateLeft(zpp)
                }
            }
            root.red = false
        }

        fixSentinel()

        count += 1
        if firstNode === sentinel || z.key < firstNode.key { firstNode = z }
        assert(firstNode.predecessor() == nil)
        if lastNode === sentinel || z.key >= lastNode.key { lastNode = z }
        assert(lastNode.successor() == nil)

        return RedBlackTreeIndex(node: z)
    }

    /// Remove the element at `index`.
    ///
    /// If this is the *first* modification to the tree since creation or copying, invalidates all indices with respect to `self`.
    ///
    /// - Complexity: O(log `count`)
    public mutating func remove(at index: Index) {
        let z: Node
        do {
            precondition(index._safe, "Cannot remove an index that is out of range.")

            let copied = ensureUnique() // call this before creating additional references to nodes
            var node = index.node! // get the node
            
            // the index was in the previous tree, find it in this one
            // the O(log `count`) complexity of this operation doesn't matter as it is equal to the complexity of the removal operation
            if copied {
                // make a path of left (true) / right turns from the root
                var path = ContiguousArray<Bool>()
                // the other tree has a different sentinel
                let old = node
                while !node.parent.isSentinel {
                    path.append(node === node.parent.left)
                    node = node.parent
                }
                node = root
                for left in path.reversed() {
                    node = left ? node.left : node.right
                }
                assert(node.key == old.key)
            }
            loopSentinel()
            z = node
        }

        count -= 1
        if z === firstNode { firstNode = firstNode.successor() ?? sentinel }
        if z === lastNode { lastNode = lastNode.predecessor() ?? sentinel }

        var ored = z.red
        let x: Node

        if z.left === sentinel {
            // replace z with its only right child, or the sentinel if it has no children
            x = z.right
            transplant(z, with: z.right)
        }
        else if z.right === sentinel {
            // replace z with its only left child
            x = z.left
            transplant(z, with: z.left)
        }
        else {
            // 2 children
            let y = z.right.subtreeMin()
            ored = y.red
            // y has no left child (successor is leftmost in subtree)
            x = y.right
            // y === r, move r's right subtree under y
            if y.parent === z { x.parent = y }
            else {
                // replace y with its right subtree
                transplant(y, with: y.right)
                // move z's right subtree under y
                y.right = z.right
                y.right.parent = y
            }
            // replace z with y
            transplant(z, with: y)
            // place z's left subtree on y's left
            y.left = z.left
            y.left.parent = y
            y.red = z.red
        }

        // fix violated red-black properties (rebalance)
        if !ored {
            var x = x
            while x !== root && !x.red {
                // mirror directional operations if x is a right child
                let left = x === x.parent.left

                var w: Node = left ? x.parent.right : x.parent.left
                assert(w !== sentinel)
                if w.red {
                    // case 1
                    w.red = false
                    x.parent.red = true
                    left ? rotateLeft(x.parent) : rotateRight(x.parent)
                    w = left ? x.parent.right : x.parent.left
                    assert(w !== sentinel)
                }
                if !w.left.red && !w.right.red {
                    // case 2
                    w.red = true
                    x = x.parent
                }
                else {
                    if left ? !w.right.red : !w.left.red {
                        // case 3
                        left ? (w.left.red = false) : (w.right.red = false)
                        w.red = true
                        left ? rotateRight(w) : rotateLeft(w)
                        w = left ? x.parent.right : x.parent.left
                        assert(w !== sentinel)
                    }
                    // case 4: w's right child is red
                    assert(left ? w.right.red : w.left.red)
                    w.red = x.parent.red
                    x.parent.red = false
                    left ? (w.right.red = false) : (w.left.red = false)
                    left ? rotateLeft(x.parent) : rotateRight(x.parent)
                    x = root
                }
            }
            x.red = false
        }

        fixSentinel()

        assert((count == 0) == (root === sentinel))
        assert(firstNode.predecessor() == nil)
        assert(lastNode.successor() == nil)
    }

    /// Update the value stored at the given index, and return the previous value.
    ///
    /// If this is the *first* modification to the tree since creation or copying, invalidates all indices with respect to `self`.
    ///
    /// - Complexity: O(1).
    @discardableResult
    public mutating func updateValue(_ value: Value, atIndex index: Index) -> Value {
        precondition(index._safe, "Cannot update an index that is out of range.")
        let v = index.node!.value!
        index.node!.value = value
        return v
    }

    /// Replace subtree `u` with subtree `v`.
    private mutating func transplant(_ u: Node, with v: Node) {
        if u.parent === sentinel { root = v }
        else if u === u.parent.left { u.parent.left = v }
        else { u.parent.right = v }
        v.parent = u.parent
    }
    
    /**
     Perform the following structure conversion:
           |                |
           x                y
          / \      ->      / \
         a   y            x   c
            / \          / \
           b   c        a   b
     */
    private mutating func rotateLeft(_ x: Node) {
        // ensureUnique() is not called here since this function does not affect any externally visible interface (elements remain in same order, index objects stay valid, etc.)
        let y = x.right!
        // move b
        x.right = y.left!
        // set b's parent
        if y.left !== sentinel { y.left.parent = x }

        y.parent = x.parent
        // update x's parent
        if x.parent === sentinel { root = y }
        // check if x was left or right child and update appropriately
        else if x === x.parent.left { x.parent.left = y }
        else { x.parent.right = y }
        // put x on y's left
        y.left = x
        x.parent = y
    }

    /// Perform the reverse structure conversion to `rotateLeft`.
    private mutating func rotateRight(_ y: Node) {
        let x = y.left!
        // move b
        y.left = x.right!
        // set b's parent
        if x.right !== sentinel { x.right.parent = y }

        x.parent = y.parent
        // update y's parent
        if y.parent === sentinel { root = x }
        // check if y was left or right child and update appropriately
        else if y === y.parent.left { y.parent.left = x }
        else { y.parent.right = x }
        // put y on x's right
        x.right = y
        y.parent = x
    }

}

extension RedBlackTree {

    /// Returns the index of the first element with key *not less* than `k`, or `endIndex` if not found.
    ///
    /// - Complexity: O(log `count`)
    public func lowerBound(_ k: Key) -> Index {
        // early return if the largest element is smaller
        var nl = lastNode
        guard k <= nl.key else { return endIndex }
        var x = root
        while x !== sentinel {
            if k <= x.key {
                nl = x
                x = x.left
            }
            else { x = x.right }
        }
        assert(k <= nl.key)
        assert(nl.predecessor() == nil || nl.predecessor()!.key < k)
        return Index(node: nl)
    }

    /// Return the index of the first element with key *greater* than `k`, or `endIndex` if not found.
    ///
    /// - Complexity: O(log `count`)
    public func upperBound(_ k: Key) -> Index {
        // early return if the largest element is smaller
        var nl = lastNode
        guard k < nl.key else { return endIndex }
        var x = root
        while x !== sentinel {
            if k < x.key {
                nl = x
                x = x.left
            }
            else { x = x.right }
        }
        assert(k < nl.key)
        assert(nl.predecessor() == nil || nl.predecessor()!.key <= k)
        return Index(node: nl)
    }

    /// Return the index of the first element with key *equal to* `key`, or `nil` if not found.
    ///
    /// - Complexity: O(log `count`)
    public func find(_ key: Key) -> Index? {
        let i = lowerBound(key)
        return i._safe && i.node!.key == key ? i : nil
    }

    /// Return whether the tree contains any elements with key `key`.
    ///
    /// - Complexity: O(log `count`)
    public func contains(_ key: Key) -> Bool {
        return find(key) != nil
    }

    /// - Complexity: O(1)
    public var minKey: Key? {
        return firstNode.key ?? nil
    }

    /// - Complexity: O(1)
    public var maxKey: Key? {
        return lastNode.key ?? nil
    }

}

extension RedBlackTree: Sequence {
    
    public func makeIterator() -> Index {
        return startIndex
    }
}

extension RedBlackTree: Collection {

    public typealias Element = (key: Key, value: Value)
    public typealias Index = RedBlackTreeIndex<Key, Value>

    /// - Complexity: O(1)
    public var startIndex: Index {
        guard firstNode !== sentinel else { assert(count == 0 && root === sentinel); return Index(empty: ()) }
        assert(firstNode.predecessor() == nil)
        return Index(node: firstNode)
    }

    /// - Complexity: O(1)
    public var endIndex: Index {
        guard lastNode !== sentinel else { assert(count == 0 && root === sentinel); return Index(empty: ()) }
        assert(lastNode.successor() == nil)
        return Index(end: lastNode)
    }

    /// Access the key at `index`.
    ///
    /// - Complexity: O(1)
    public subscript(index: Index) -> Element {
        switch index.kind {
        case .node(let u):
            return (u.value.key, u.value.value)
        case .end, .empty:
            preconditionFailure("Cannot subscript an out-of-bounds index.")
        }
    }

    /// - Complexity: Amortised O(1) across a full iteration of the collection.
    public func index(after i: Index) -> Index {
        return i.successor()
    }
}

extension RedBlackTree: RandomAccessCollection {

    public func index(before i: Index) -> Index {
        return i.predecessor()
    }
}

extension RedBlackTree {

    /// - Complexity: O(1)
    public var first: Element? {
        return firstNode !== sentinel ? (firstNode.key, firstNode.value) : nil
    }

    /// - Complexity: O(1)
    public var last: Element? {
        return lastNode !== sentinel ? (lastNode.key, lastNode.value) : nil
    }

}

extension RedBlackTree: ExpressibleByArrayLiteral {

    public init(arrayLiteral elements: Element...) {
        self.init(elements)
    }
}
