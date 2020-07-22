//
//  RedBlackTreeIndex.swift
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

/// Used to access elements of an `_RBTree<Key, Value>`.
public struct RedBlackTreeIndex<Key: Comparable, Value> {
    
    typealias Node = RedBlackTreeNode<Key, Value>
    
    enum Kind {
        case node(Unowned<RedBlackTreeNode<Key, Value>>)
        /// A value used for `endIndex`.
        ///
        /// - Warning: **This index does not point to an element**, it's a "past the end" index. `last` is not its value; it's referenced so that the `predecessor` function can work.
        case end(last: Unowned<RedBlackTreeNode<Key, Value>>)
        /// An index into an empty tree.
        case empty
    }

    let kind: Kind

    private init(node u: Unowned<Node>) { kind = .node(u) }
    init(node: Node) { self.init(node: Unowned(node)) }

    private init(end u: Unowned<Node>) {
        assert(u.value.successor() == nil, "Cannot make end index for a node that is not the end.")
        kind = .end(last: u)
    }
    
    /// Create an index for referring to past the end of the tree. `last` is the last actual element of the collection.
    init(end last: Node) { self.init(end: Unowned(last)) }

    /// Create an index into an empty tree.
    init(empty: ()) {
        kind = .empty
    }

    /// - Complexity: Amortised O(1)
    public func successor() -> Self {
        switch kind {
        case .node(let u):
            guard let suc = u.value.successor() else { return Self(end: u) }
            return Self(node: suc)
        case .end(_): fallthrough
        case .empty:
            preconditionFailure("Cannot get successor of the end index.")
        }
    }

    /// - Complexity: Amortised O(1)
    public func predecessor() -> Self {
        switch kind {
        case .node(let u):
            guard let pre = u.value.predecessor() else { preconditionFailure("Cannot get predecessor of the start index.") }
            return Self(node: pre)
        case .end(last: let u):
            return Self(node: u)
        case .empty:
            preconditionFailure("Cannot get predecessor of the start index.")
        }
    }

    /// Whether the index is safe to subscript.
    public var _safe: Bool {
        if case .node(_) = kind { return true }
        return false
    }

    /// The node the index refers to, if any.
    var node: Node? {
        if case .node(let u) = kind { return u.value }
        return nil
    }

}

extension RedBlackTreeIndex: IteratorProtocol {
    
    /// - Complexity: Amortised O(1) over a full iteration of the collection.
    public mutating func next() -> (Key, Value)? {
        switch kind {
        case .node(let u):
            defer {
                self = self.successor()
            }
            return (u.value.key, u.value.value)
        case .end(_), .empty:
            return nil
        }
    }
}

extension RedBlackTreeIndex: Equatable {

    /// - Complexity: O(1)
    public static func == (lhs: RedBlackTreeIndex, rhs: RedBlackTreeIndex) -> Bool {
        switch (lhs.kind, rhs.kind) {
        case (.node(let a), .node(let b)): return a.value === b.value
        case (.end(let a), .end(let b)): return a.value === b.value
        case (.empty, .empty): return true
        default: return false
        }
    }
}

extension RedBlackTreeIndex: Comparable {
    
    /// - Complexity: O(1)
    public static func < (lhs: RedBlackTreeIndex, rhs: RedBlackTreeIndex) -> Bool {
        switch (lhs.kind, rhs.kind) {
        case (.node(let a), .node(let b)):
            return a.value.key < b.value.key
        case (.node(let a), .end(let b)):
            // even if a.value === b.value, a < b because b is "past the end"
            return a.value.key <= b.value.key
        case (.end(let a), .end(let b)):
            // if a.value !== b.value then they're not keys from the same tree, but we can give a total preorder anyway
            return a.value.key < b.value.key
        case (.end(let a), .node(let b)):
            // this is not a valid case. let's try to do something reasonable anyway.
            return a.value.key < b.value.key
        case (.empty, _):
            // let's sort empty after everything else. note .empty < .empty == false, correctly
            return false
        case (.node, .empty), (.end, .empty):
            return true
        }
    }
}
