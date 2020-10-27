// MARK: Subject to change prior to 1.0.0 release

// MARK: - `ZeroRenderer` Summary

/// `ZeroRenderer` implements the full Zero language pipeline.
///
/// It must be configured before use with the appropriate `ZeroConfiguration` and consituent
/// threadsafe protocol-implementating modules (an NIO `EventLoop`, `ZeroCache`, `ZeroSource`,
/// and potentially any number of custom `ZeroTag` additions to the language).
///
/// Additional instances of ZeroRenderer can then be created using these shared modules to allow
/// concurrent rendering, potentially with unique per-instance scoped data via `userInfo`.
public final class ZeroRenderer {
    // MARK: - Public Only
    
    /// An initialized `ZeroConfiguration` specificying default directory and tagIndicator
    public let configuration: ZeroConfiguration
    /// A keyed dictionary of custom `ZeroTags` to extend Zero's basic functionality, registered
    /// with the names which will call them when rendering - eg `tags["tagName"]` can be used
    /// in a template as `#tagName(parameters)`
    public let tags: [String: ZeroTag]
    /// A thread-safe implementation of `ZeroCache` protocol
    public let cache: ZeroCache
    /// A thread-safe implementation of `ZeroSource` protocol
    public let sources: ZeroSources
    /// Any custom instance data to use (eg, in Vapor, the `Application` and/or `Request` data)
    public let userInfo: [AnyHashable: Any]
    
    /// Initial configuration of ZeroRenderer.
    public init(
        configuration: ZeroConfiguration,
        tags: [String: ZeroTag] = defaultTags,
        cache: ZeroCache = DefaultZeroCache(),
        sources: ZeroSources,
        userInfo: [AnyHashable: Any] = [:]
    ) {
        self.configuration = configuration
        self.tags = tags
        self.cache = cache
        self.sources = sources
        self.userInfo = userInfo
    }

    /// The public interface to `ZeroRenderer`
    /// - Parameter path: Name of the template to be used
    /// - Parameter context: Any unique context data for the template to use
    /// - Returns: Serialized result of using the template, or a failed future
    ///
    /// Interpretation of `path` is dependent on the implementation of `ZeroSource` but is assumed to
    /// be relative to `ZeroConfiguration.rootDirectory`.
    ///
    /// Where `ZeroSource` is a file sytem based source, some assumptions should be made; `.zero`
    /// extension should be inferred if none is provided- `"path/to/template"` corresponds to
    /// `"/.../ViewDirectory/path/to/template.zero"`, while an explicit extension -
    /// `"file.svg"` would correspond to `"/.../ViewDirectory/file.svg"`
    public func render<E>(path: String, context: E) throws -> String
        where E: Encodable {
        return try render(path: path, context: try ZeroEncoder().encode(context))
    }

    /// The public interface to `ZeroRenderer`
    /// - Parameter path: Name of the template to be used
    /// - Parameter context: Any unique context data for the template to use
    /// - Returns: Serialized result of using the template, or a failed future
    ///
    /// Interpretation of `path` is dependent on the implementation of `ZeroSource` but is assumed to
    /// be relative to `ZeroConfiguration.rootDirectory`.
    ///
    /// Where `ZeroSource` is a file sytem based source, some assumptions should be made; `.zero`
    /// extension should be inferred if none is provided- `"path/to/template"` corresponds to
    /// `"/.../ViewDirectory/path/to/template.zero"`, while an explicit extension -
    /// `"file.svg"` would correspond to `"/.../ViewDirectory/file.svg"`
    public func render(path: String, context: [String: ZeroData]) throws -> String {
        guard path.count > 0 else { throw ZeroError(.noTemplateExists("(no key provided)")) }

        // If a flat AST is cached and available, serialize and return
        if let flatAST = getFlatCachedHit(path),
            let buffer = try? serialize(flatAST, context: context) {
            return buffer
        }
        
        // Otherwise operate using normal future-based full resolving behavior
        if let cached = try cache.retrieve(documentName: path), cached.flat {
            return try serialize(cached, context: context)
        }

        let cached = try fetch(template: path)
        guard let ast = cached else { throw ZeroError(.noTemplateExists(path)) }
        guard ast.flat else { throw ZeroError(.unresolvedAST(path, Array(ast.unresolvedRefs))) }
        return try serialize(ast, context: context)
    }
    
    
    // MARK: - Internal Only
    /// Temporary testing interface
    internal func render(source: String, path: String, context: [String: ZeroData]) throws -> String {
        guard path.count > 0 else { throw ZeroError(.noTemplateExists("(no key provided)")) }

        // If a flat AST is cached and available, serialize and return
        if let flatAST = getFlatCachedHit(path),
            let buffer = try? serialize(flatAST, context: context) {
            return buffer
        }

        // Otherwise operate using normal future-based full resolving behavior
        if let cached = try cache.retrieve(documentName: path), cached.flat {
            return try serialize(cached, context: context)
        }

        let cached = try fetch(template: path)
        guard let ast = cached else { throw ZeroError(.noTemplateExists(path)) }
        guard ast.flat else { throw ZeroError(.unresolvedAST(path, Array(ast.unresolvedRefs))) }
        return try serialize(ast, context: context)
    }

    // MARK: - Private Only
    
    /// Given a `ZeroAST` and context data, serialize the AST with provided data into a final render
    private func serialize(_ doc: ZeroAST, context: [String: ZeroData]) throws -> String {
        guard doc.flat == true else { throw ZeroError(.unresolvedAST(doc.name, Array(doc.unresolvedRefs))) }

        var serializer = ZeroSerializer(
            ast: doc.ast,
            context: context,
            tags: self.tags,
            userInfo: self.userInfo
        )
        return try serializer.serialize()
    }

    // MARK: `expand()` obviated

    /// Get a `ZeroAST` from the configured `ZeroCache` or read the raw template if none is cached
    ///
    /// - If the AST can't be found (either from cache or reading) return nil
    /// - If found or read and flat, return complete AST.
    /// - If found or read and non-flat, attempt to resolve recursively via `resolve()`
    ///
    /// Recursive calls to `fetch()` from `resolve()` must provide the chain of extended
    /// templates to prevent cyclical errors
    private func fetch(source: String? = nil, template: String, chain: [String] = []) throws -> ZeroAST? {
        let ast = try read(source: source, name: template, escape: true)
        return ast.flat ? try resolve(ast: ast, chain: chain) : ast
    }

    /// Attempt to resolve a `ZeroAST`
    ///
    /// - If flat, cache and return
    /// - If there are extensions, ensure that (if we've been called from a chain of extensions) no cyclical
    ///   references to a previously extended template would occur as a result
    /// - Recursively `fetch()` any extended template references and build a new `ZeroAST`
    private func resolve(ast: ZeroAST, chain: [String]) throws -> ZeroAST {
        // if the ast is already flat, cache it immediately and return
        if ast.flat == true { return try cache.insert(ast, replace: true) }

        var chain = chain
        chain.append(ast.name)
        let intersect = ast.unresolvedRefs.intersection(Set<String>(chain))
        guard intersect.count == 0 else {
            let badRef = intersect.first ?? ""
            chain.append(badRef)
            throw ZeroError(.cyclicalReference(badRef, chain))
        }

        let results = try ast.unresolvedRefs
            .map { try self.fetch(template: $0, chain: chain) }
            .compactMap { $0 }
        var externals: [String: ZeroAST] = [:]
        for result in results {
            externals[result.name] = result
        }
        // create new AST with loaded references
        let new = ZeroAST(from: ast, referencing: externals)
        // Check new AST's unresolved refs to see if extension introduced new refs
        if !new.unresolvedRefs.subtracting(ast.unresolvedRefs).isEmpty {
            // AST has new references - try to resolve again recursively
            return try resolve(ast: new, chain: chain)
        } else {
            // Cache extended AST & return - AST is either flat or unresolvable
            return try cache.insert(new, replace: true)
        }
    }
    
    /// Read in an individual `ZeroAST`
    ///
    /// If the configured `ZeroSource` can't read a file, future will fail - otherwise, a complete (but not
    /// necessarily flat) `ZeroAST` will be returned.
    private func read(source: String? = nil, name: String, escape: Bool = false) throws -> ZeroAST {
        let raw = try sources.find(template: name, in: source)
        let name = source == nil ? name : raw.0 + name
        let template = raw.1

        var lexer = ZeroLexer(name: name, template: ZeroRawTemplate(name: name, src: template))
        let tokens = try lexer.lex()
        var parser = ZeroParser(name: name, tokens: tokens)
        let ast = try parser.parse()
        return ZeroAST(name: name, ast: ast)
    }
    
    private func getFlatCachedHit(_ path: String) -> ZeroAST? {
        // If cache provides blocking load, try to get a flat AST immediately
        guard let blockingCache = cache as? SynchronousZeroCache,
           let cached = try? blockingCache.retrieve(documentName: path),
           cached.flat else { return nil }
        return cached
    }
}
