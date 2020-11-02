// MARK: Subject to change prior to 1.0.0 release
// MARK: -

import Foundation

public final class DefaultLeafCache: SynchronousLeafCache {
    // MARK: - Public - `LeafCache` Protocol Conformance
    
    /// Global setting for enabling or disabling the cache
    public var isEnabled: Bool = true
    /// Current count of cached documents
    public var count: Int { self.lock.withLock { cache.count } }
    
    /// Initializer
    public init() {
    }

    /// - Parameters:
    ///   - document: The `LeafAST` to store
    ///   - replace: If a document with the same name is already cached, whether to replace or not.
    /// - Returns: The document provided as an identity return
    public func insert(
        _ document: LeafAST,
        replace: Bool = false
    ) throws -> LeafAST {
        // future fails if caching is enabled
        guard isEnabled else { return document }

        self.lock.lock()
        defer { self.lock.unlock() }
        // return an error if replace is false and the document name is already in cache
        switch (self.cache.keys.contains(document.name),replace) {
            case (true, false): throw LeafError(.keyExists(document.name))
            default: self.cache[document.name] = document
        }
        return document
    }
    
    /// - Parameters:
    ///   - documentName: Name of the `LeafAST`  to try to return
    /// - Returns: `LeafAST` or nil if no matching result
    public func retrieve(
        documentName: String
    ) throws -> LeafAST? {
        guard isEnabled == true else { return nil }
        self.lock.lock()
        defer { self.lock.unlock() }
        return cache[documentName]
    }

    /// - Parameters:
    ///   - documentName: Name of the `LeafAST`  to try to purge from the cache
    /// - Returns: `Bool?` - If no document exists, returns nil. If removed,
    ///     returns true. If cache can't remove because of dependencies (not yet possible), returns false.
    public func remove(
        _ documentName: String
    ) throws -> Bool? {
        guard isEnabled == true else { throw LeafError(.cachingDisabled) }

        self.lock.lock()
        defer { self.lock.unlock() }

        guard self.cache[documentName] != nil else { return nil }
        self.cache[documentName] = nil
        return true
    }
    
    // MARK: - Internal Only
    
    internal let lock = NSLock()
    internal var cache = [String: LeafAST]()
}
