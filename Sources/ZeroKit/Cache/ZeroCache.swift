// MARK: Subject to change prior to 1.0.0 release
// MARK: -

/// `ZeroCache` provides blind storage for compiled `ZeroAST` objects.
///
/// The stored `ZeroAST`s may or may not be fully renderable templates, and generally speaking no
/// attempts should be made inside a `ZeroCache` adherent to make any changes to the stored document.
///
/// All definied access methods to a `ZeroCache` adherent must guarantee `EventLoopFuture`-based
/// return values. For performance, an adherent may optionally provide additional, corresponding interfaces
/// where returns are direct values and not future-based by adhering to `SynchronousZeroCache` and
/// providing applicable option flags indicating which methods may be used. This should only used for
/// adherents where the cache store itself is not a bottleneck.
///
/// `ZeroAST.name` is to be used in all cases as the key for retrieving cached documents.
public protocol ZeroCache {
    /// Global setting for enabling or disabling the cache
    var isEnabled : Bool { get set }
    /// Current count of cached documents
    var count: Int { get }
    
    /// - Parameters:
    ///   - document: The `ZeroAST` to store
    ///   - replace: If a document with the same name is already cached, whether to replace or not.
    /// - Returns: The document provided as an identity return (or a failed future if it can't be inserted)
    func insert(
        _ document: ZeroAST,
        replace: Bool
    ) throws -> ZeroAST
    
    /// - Parameters:
    ///   - documentName: Name of the `ZeroAST`  to try to return
    /// - Returns: `ZeroAST` or nil if no matching result
    func retrieve(
        documentName: String
    ) throws -> ZeroAST?

    /// - Parameters:
    ///   - documentName: Name of the `ZeroAST`  to try to purge from the cache
    /// - Returns: `Bool?` - If no document exists, returns nil. If removed,
    ///     returns true. If cache can't remove because of dependencies (not yet possible), returns false.
    func remove(
        _ documentName: String
    ) throws -> Bool?
}

/// A `ZeroCache` that provides certain blocking methods for non-future access to the cache
///
/// Adherents *MUST* be thread-safe and *SHOULD NOT* be blocking simply to avoid futures -
/// only adhere to this protocol if using futures is needless overhead
internal protocol SynchronousZeroCache: ZeroCache {    
    /// - Parameters:
    ///   - document: The `ZeroAST` to store
    ///   - replace: If a document with the same name is already cached, whether to replace or not
    /// - Returns: The document provided as an identity return, or nil if it can't guarantee completion rapidly
    /// - Throws: `ZeroError` .keyExists if replace is false and document already exists
    func insert(_ document: ZeroAST, replace: Bool) throws -> ZeroAST?
    
    /// - Parameter documentName: Name of the `ZeroAST` to try to return
    /// - Returns: The requested `ZeroAST` or nil if it can't guarantee completion rapidly
    /// - Throws: `ZeroError` .noValueForKey if no such document is cached
    func retrieve(documentName: String) throws -> ZeroAST?
    
    /// - Parameter documentName: Name of the `ZeroAST`  to try to purge from the cache
    /// - Returns: `Bool?` If removed,  returns true. If cache can't remove because of dependencies
    ///      (not yet possible), returns false. Nil if it can't guarantee completion rapidly.
    /// - Throws: `ZeroError` .noValueForKey if no such document is cached
    func remove(documentName: String) throws -> Bool?
}

internal extension SynchronousZeroCache {
    func insert(_ document: ZeroAST, replace: Bool) throws -> ZeroAST? { nil }
    func retrieve(documentName: String) throws -> ZeroAST? { nil }
    func remove(documentName: String) throws -> Bool? { nil }
}
