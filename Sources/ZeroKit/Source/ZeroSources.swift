// MARK: Subject to change prior to 1.0.0 release
// MARK: -


import Foundation

/// An opaque object holding named `ZeroSource` adherants specifying a default search order.
///
/// This object is `public` solely for convenience in reading the currently configured state.
///
/// Once registered, the `ZeroSource` objects can not be accessed or modified - they *must* be
/// fully configured prior to registering with the instance of `ZeroSources`
/// - `ZeroSource` objects are registered with an instance of this class - this should *only* be done
///     prior to use by `ZeroRenderer`.
/// - `.all` provides a `Set` of the `String`keys for all sources registered with the instance
/// - `.searchOrder` provides the keys of sources that an unspecified template request will search.
public final class ZeroSources {
    // MARK: - Public
    
    /// All available `ZeroSource`s of templates
    public var all: Set<String> { lock.withLock { .init(self.sources.keys) } }
    /// Configured default implicit search order of `ZeroSource`'s
    public var searchOrder: [String] { lock.withLock { order } }
    
    public init() {
        self.sources = [:]
        self.order = []
    }
    
    /// Register a `ZeroSource` as `key`
    /// - Parameters:
    ///   - key: Name for the source; at most one may be registered without a name
    ///   - source: A fully configured `ZeroSource` object
    ///   - searchable: Whether the source should be added to the default search path
    /// - Throws: Attempting to overwrite a previously named source is not permitted
    public func register(source key: String = "default",
                         using source: ZeroSource,
                         searchable: Bool = true) throws {
        try lock.withLock {
            guard !sources.keys.contains(key) else { throw "Can't replace source at \(key)" }
            sources[key] = source
            if searchable { order.append(key) }
        }
    }
    
    /// Convenience for initializing a `ZeroSources` object with a single `ZeroSource`
    /// - Parameter source: A fully configured `ZeroSource`
    /// - Returns: Configured `ZeroSource` instance
    public static func singleSource(_ source: ZeroSource) -> ZeroSources {
        let sources = ZeroSources()
        try! sources.register(using: source)
        return sources
    }
    
    // MARK: - Internal Only
    internal private(set) var sources: [String: ZeroSource]
    private var order: [String]
    private let lock = NSLock()
    
    /// Locate a template from the sources; if a specific source is named, only try to read from it. Otherwise, use the specified search order
    internal func find(template: String, in source: String? = nil) throws -> (String, String) {
        var keys: [String]
        
        switch source {
            case .none: keys = searchOrder
            case .some(let source):
                if all.contains(source) { keys = [source] }
                else { throw ZeroError(.illegalAccess("Invalid source \(source) specified")) }
        }
        guard !keys.isEmpty else { throw ZeroError(.illegalAccess("No searchable sources exist")) }
        
        return try searchSources(t: template, s: keys)
    }
    
    private func searchSources(t: String, s: [String]) throws -> (String, String) {
        guard !s.isEmpty else { throw ZeroError(.noTemplateExists(t)) }
        var more = s
        let key = more.removeFirst()
        lock.lock()
            let source = sources[key]!
        lock.unlock()
        
        do {
            let file = try source.file(template: t, escape: true)
            return (key, file)
        } catch {
            // If the throwing error is illegal access, fail immediately
            if let e = error as? ZeroError, case .illegalAccess(_) = e.reason {
                throw e
            } else {
                // Or move onto the next one
                return try searchSources(t: t, s: more)
            }
        }
    }
}
