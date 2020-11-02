// MARK: Subject to change prior to 1.0.0 release
// MARK: -

/// Public protocol to adhere to in order to provide template source originators to `LeafRenderer`
public protocol LeafSource {
    /// Given a path name, return an EventLoopFuture holding a ByteBuffer
    /// - Parameters:
    ///   - template: Relative template name (eg: `"path/to/template"`)
    ///   - escape: If the adherent represents a filesystem or something scoped that enforces
    ///             a concept of directories and sandboxing, whether to allow escaping the view directory
    /// - Returns: A succeeded `String` with the raw
    ///            template, or an appropriate failed state ELFuture (not found, illegal access, etc)
    func file(
        template: String,
        escape: Bool
    ) throws -> String
}
